#!/usr/bin/perl

use FindBin;
use lib "$FindBin::Bin/../lib";
use FileHandle;
use File::Find;
use Data::Dumper;
use Getopt::Long;
use Pod::Usage;
use strict;

my $TIMESTAMP = `date +%Y_%m_%d_%H_%M_%S`;
chomp $TIMESTAMP;

my %Scriptz;# name=>+{ 'auth'=>auth/items satisfied, 'options'=>option names }
#  Note: Some Scriptz entries are real files.
#  Others are "scriptname-variant" pseudo-script names.

my %Variantz; # "scriptname-variantname" => +[scriptname, variantname]

my %scriptlogz; # name(incl variants) => failure log of script
my %satisfyz; # auth/item => list of scripts (incl variants)
my %Byhandz; # auth/item => existence means no script is planned to check it.

my %Authorityz; # name => { attr => value, list=>list of reqts keys in order,
 # 'reqts'=>{rqt-id => text-of-rqt} }

my $AUTHORITY_DIR = "";

my %optionz; # option name => value. All options known to relevant scripts. 
# undef means no one has supplied a value to the option.

my %requiredz; # requirement => dummy
my %waivedz; # requirement => dummy
my @runs; # steps to run (in order to run them) .. if scriptlet has variants, runs includes only the variants
my %runOrSkipz; # step name on either the run or skip list => dummy

my $dbgSteps = 0;
my $dbgScripts = 0;

my $stepDir = "$FindBin::Bin/scriptlets";

# Where to put reports, logs, recommended files:
my $lhccertDir = "/Certification";

my %resultz; # auth/item => 
#    0 if a step failed; 
#    1 if step(s) passed and none failed; 
#    missing if not tried.

my $_VERSION = "04112017";
my $_VERSION_PRETTY = "04/11/2017";

sub readAllScripts {
    my @s;
    if ($dbgScripts) {
        print "Reading all scriptlets:\n";
    }
    File::Find::find(
                     sub{ 
                         -f && # normal file
                             -x && # can execute
                             !/~/ && # not editor backup file!
                             push(@s, $_)
                         }, 
                     $stepDir);
    for my $s (@s) {
        if ($dbgScripts) {
            print "  Reading $s\n";
        }
        my $h = new FileHandle();
        my $f = "$stepDir/$s";
        open($h, '<', $f) || die ("Can't read $f");
        $Scriptz{$s} = +{auth=>+[], options=>+[]};
        my $L;
        my @variants;
        my @auths;
        my @options;
        # Authorities accumulate, but upon each 'variant' line,
        # authorities (if further specified) start a fresh accumulation.
        my $kill_auths=0;
        while ( $L = <$h> ) {
            if ($L =~ m!^\s*\#\s*authority:\s*([^\s]+)!) {
                my $auth = $1;
                if ($kill_auths) { @auths=(); $kill_auths=0; }
                push(@auths, $1);
            }
            elsif ($L =~ m!^\s*\#\s*variant:\s*([^\s]+)!) {
                my $variant = $1;
                push(@variants, $variant);
                $kill_auths=1;

                $Variantz{"$s-$variant"}=+[$s, $variant];
                push(@{$Scriptz{"$s-$variant"}{auth}}, @auths);
                for my $auth (@auths) {
                    push(@{$satisfyz{$auth}}, "$s-$variant");
                }
                push(@{$Scriptz{"$s-$variant"}{options}}, @options);
                for my $option (@options) {
                    $optionz{$option}=undef;
                }
            }
            elsif ($L =~ m!^\s*\#\s*option:\s*([^\s]+)!) {
                push(@options, $1);
            }
        }
        close($h);

        # A script that satisfies no requirement might be an error!
        if ( 0 == @auths ) {
            warn("Script $s does not name any authority(ies).");
        }

        # Register the script under its own name if no variants.
        # Otherwise register it only under the variants' names:
        if (!@variants) {
            push(@{$Scriptz{$s}{auth}}, @auths);
            for my $auth (@auths) {
                push(@{$satisfyz{$auth}}, $s);
            }
            push(@{$Scriptz{$s}{options}}, @options);
            for my $option (@options) {
                $optionz{$option}=undef;
            }
        }
    }
}

sub getAuthority {
    my ($authName) = @_;
    if (!exists($Authorityz{$authName})) {
        for my $candidate 
            (grep(-f, 
                  map("$_/LHC/Harden/resources/Authority/$authName", 
                      @INC),
                  map("$_/resources/Authority/$authName", 
                      @INC)
                  )) {
                $Authorityz{$authName}=+{list=>+[]};
                my $h = new FileHandle();
                open($h, '<', $candidate) || die ("Can't open $candidate");
                my $L;
                while ( $L=<$h> ) {
                    # Comment starts with "#" after optional whitespace:
                    if ($L =~ /^\s*\#/) {
                    }
                    # Requirement is: nnn whitespace definition
                    elsif ($L =~ /^\s*([^=]+?)\s+(.*?)\s*$/) {
                        my ($number, $text) = ($1, $2);
                        if ($number =~ /^by-hand\!(.*)/) {
                            $number = $1;
                            $Byhandz{"$authName/$number"}=1;
                        }
                        $Authorityz{$authName}{reqts}{$number}=$text;
                        push(@{$Authorityz{$authName}{list}}, $1);
                    }
                    # Attribute is: "title" = stuff
                    elsif ($L =~ /^\s*(title)=\s*()\s*$/) {
                        $Authorityz{$authName}{$1}=$2;
                    }
                    # Option is: optionname = optionvalue
                    elsif ($L =~ /^\s*([^=]+?)\s+(.*?)\s*$/) {
                        if (exists($optionz{$1})) {
                            if (!defined($optionz{$1})) {
                                $optionz{$1} = $2;
                            }
                        }
                        else {
                            die("Don't know option $1, referred to by authority $authName");
                        }
                    }
                }
                close($h);
                last;
            }
    }
    return $Authorityz{$authName};
}

sub findPlan {
    my ($planName) = @_;
    my $rv = $planName; 
    if ( ! -f $rv )  {
        for my $candidate 
            (grep(-f, 
                  map("$_/LHC/Harden/resources/Patterns/$planName", 
                      @INC),
                  map("$_/resources/Pattern/$planName", 
                      @INC),
                  )) {
                $rv = $candidate;
                last;
            }
    }
    return $rv;
}

# It reads the authorities as they're needed.
sub evalplan {
    my $plan = shift;
    my $level = shift;
    if (!defined($level)) { $level = 0; }
    my $L;
    for my $L (@{$plan}) {
        chomp $L;
        # ignore comments:
        if ($L =~ /^\s*\#/) {
            # ignore
        }
        # include:
        elsif ($L =~ /^\s*include\s+(.*?)\s*$/) {
            my $f = $1;
            addPlan($f, $level);
        }
        # require:
        elsif ($L =~ /^\s*require\s+(.*?)\s*$/) {
            my $rqt = $1;
            addRequire($rqt, $level);
        }
        # waive:
        elsif ($L =~ /^\s*waive\s+(.*?)\s*$/) {
            my $rqt = $1;
            addWaive($rqt, $level);
        }
        # run:
        elsif ($L =~ /^\s*run\s+(.*?)\s*$/) {
            my $step = $1;
            addRun($step, $level);
        }
        # skip:
        elsif ($L =~ /^\s*skip\s+(.*?)\s*$/) {
            my $step = $1;
            addSkip($step, $level);

            ### TODO: check step name against known steps to prevent confusion of skip vs waive.
        }
        # option:
        elsif ($L =~ /^\s*option\s+(.*?)\s*=\s*(.*?)\s*$/) {
            my $option = $1;
            my $value = $2;
            if (exists($optionz{$option})) {
                if (!defined($optionz{$option})) {
                    $optionz{$option} = $value;
                }
            }
            else {
                die("Don't know option $option, referred to by pattern $plan");
            }
        }
        # error!
        elsif ($L !~ /^\s*$/) {
            die("Don't know what to do with $L");
        }
    }

}

sub addPlan {
    my $planName = shift;
    my $level = shift;
    my $f = findPlan($planName);
    if (!defined($level)) { $level = 0; }
    dbgStepsComment($level, "include $f");
    my $h = new FileHandle();
    open($h, '<', $f) || die "Can't open $f";
    my @LL = <$h>;
    evalplan(+[@LL], 1+$level);
    close($h);
}

sub addRequire {
    my $rqt = shift;
    my $level = shift;
    ($rqt =~ m!(.*?)/(.*)!)
        or die ("require $rqt: Must look like \"authority/item\"");
    my ($auth, $item) = ($1, $2);
    getAuthority($auth);
    if ($item eq '*') {
        addRequireAll($auth, $level);
    }
    else {
        addRequireOne($auth, $item, $level);
    }
}

sub addRequireAll {
    my $auth = shift;
    my $level = shift;
    dbgStepsComment($level, "require $auth/*");
    my @items = @{$Authorityz{$auth}{list}};
    for my $item (@items) {
        addRequireOne($auth, $item, 1+$level);
    }
}

sub addRequireOne {
    my ($auth, $item, $level) = @_;
    #   If it is not waived:
    if (!exists($requiredz{"$auth/$item"})
        && !exists($waivedz{"$auth/$item"})) {
        dbgStepsComment($level, "require $auth/$item: ".$Authorityz{$auth}{reqts}{$item});
        #     Add all scripts that satisfy it (except those to skip).
        if (exists($satisfyz{"$auth/$item"}) && @{$satisfyz{"$auth/$item"}}) {
            my @satisfiers = @{$satisfyz{"$auth/$item"}};
            for my $step (@satisfiers) {
                addRun($step, 1+$level);
            }
        }
        else {
            #warn("No step satisfies requirement $auth/$item\n");
        }
        $requiredz{"$auth/$item"}++;
    } 
    else {
        dbgStepsComment($level, "require $auth/$item (already seen)");
    }
}

sub addWaive {
    my $rqt = shift;
    my $level = shift;
    ($rqt =~ m!(.*?)/(.*)!)
        or die ("waive $rqt: Must look like \"authority/item\"");
    my ($auth, $item) = ($1, $2);
    getAuthority($auth);
    if ($item eq '*') {
        addWaiveAll($auth, $level);
    }
    else {
        addWaiveOne($auth, $item, $level);
    }
}

sub addWaiveAll {
    my $auth = shift;
    my $level = shift;
    dbgStepsComment($level, "waive $auth/*");
    my @items = keys(%{$Authorityz{$auth}{reqts}});
    for my $item (@items) {
        addWaiveOne($auth, $item, 1+$level);
    }
}

sub addWaiveOne {
    my ($auth, $item, $level) = @_;
    if (!exists($requiredz{"$auth/$item"}) &&
        !exists($waivedz{"$auth/$item"})) {
        dbgStepsComment($level, "waive $auth/$item: ".$Authorityz{$auth}{reqts}{$item});
        $waivedz{"$auth/$item"}++;
    }
    else {
        dbgStepsComment($level, "waive $auth/$item (already seen)");
    }
}

sub addRun {
    my $step = shift;
    my $level = shift;
    # If not skipped...
    if (!exists($runOrSkipz{$step})) {
        dbgStepsComment($level, "run $step");
        push(@runs, $step);
        $runOrSkipz{$step}++;
    }
    else {
        dbgStepsComment($level, "run $step (already seen)");
    }
}

sub addSkip {
    my $step = shift;
    my $level = shift;
    if (!exists($runOrSkipz{$step})) {
        dbgStepsComment($level, "skip $step");
        $runOrSkipz{$step}++;
    }
    else {
        dbgStepsComment($level, "skip $step (already seen)");
    }
}

sub dbgStepsComment {
    my ($level, $comment) = @_;
    if ($dbgSteps) {
        print "".(' ' x $level).$comment."\n";
    }
}




sub runChecks {
    for my $step (@runs) {
        runCheck($step);
    }
}
sub runDry {
    for my $stepName (@runs) {
        # Save result in resultz:
        foreach my $rqt (@{$Scriptz{$stepName}{auth}}) {
            if (exists($resultz{$rqt}) && !$resultz{$rqt}) {
                # a failure already occurred. leave it alone.
            } 
            else {
                $resultz{$rqt} = 2;
            }
        }
    }
}

# Perl trim function to remove whitespace from the start and end of the string
# from http://www.somacon.com/p114.php
# which in turn credits "the Perl FAQ entry, 
# How do I strip blank space from the beginning/end of a string?"
sub trim($)
{
	my $string = shift;
	$string =~ s/^[\s\n]+//s;  # pw modification to include \n
	$string =~ s/\s+$//s;
	return $string;
}

sub runCheck {
    my $stepName = shift; # including variant if any

    my $f;
    my $v;
    my $ev = join(' ', map("$_=$optionz{$_}", 
                           grep(defined($optionz{$_}), 
                                @{$Scriptz{$stepName}{options}})));
    if (exists($Variantz{$stepName})) {
        $f = "$stepDir/".($Variantz{$stepName}[0]);
        $v = $Variantz{$stepName}[1];
    }
    else {
        $f = "$stepDir/$stepName";
        $v = undef;
    }
    # Capture STDOUT and STDERR.
    # Display name-of-script ... and ok or EXAMINE.
    print $stepName;
    print '.' x (60-length($stepName));

    # Establish fresh bak and repl directories.
    my $auditdir="$lhccertDir/trail_$TIMESTAMP";
    mkdir($auditdir);
    chmod(0700,$auditdir);
    my $BAKROOT="$auditdir/bak";
    mkdir($BAKROOT);
    my $REPLROOT="$auditdir/new";
    mkdir($REPLROOT);

    my @R = `/bin/bash -c \"PATH=${ENV{PATH}}:${FindBin::Bin}/../lib BAKROOT=$BAKROOT REPLROOT=$REPLROOT $ev $f check $v 2>&1\"`;
    my $ec = $?;
    my $rv = ($ec >> 8);
    my $death_signal = ($ec & 127);

    # From @R, weed out "))= " not immediately followed by a problem
    # and "))  " not immediately preceded by either a problem or another "))  "
    # that made it into the output.
    my @L;
    my $dam = 0;
    for (my $i = 0; $i < @R; $i++) {
        if ($R[$i] =~ /^\)\)= /) 
        {
            $dam = 1;
        }
        if ( ($R[$i] !~ /^\)\)/)
             || ( ($R[$i]=~/^\)\)= /) && ($i<(@R-1)) && ($R[$i+1] !~/^\)\)/) )
             || ( ($R[$i]=~/^\)\)  /) && ($i>0) && 
                  (($R[$i-1] !~/^\)\)/) || (($L[$#L] =~ /^\)\)  / ) && !$dam)   )    )
             )
        {
            push(@L, $R[$i]);
        }
        elsif ($R[$i] =~ /^\)\)x/) 
        {
            $dam = 1;
        }
    }

    # If text was left, or there was a process error code, save text:
    if (@L && !$ec) {
        $ec = 1;
    }
    if ($ec != 0) {
        my $failtext = join('', map("$_", @L));
        if (!$failtext) {
            $failtext = "Scriptlet terminated abnormally: exit code $rv; signal $death_signal\n";
        }
        $scriptlogz{$stepName} = $failtext;
        print "EXAMINE\n$failtext";
    }
    else {
        print "ok";
    }
    print "\n";
    # Save result in resultz:
    foreach my $rqt (@{$Scriptz{$stepName}{auth}}) {
        if (exists($resultz{$rqt}) && !$resultz{$rqt}) {
            # a failure already occurred. leave it alone.
        } 
        else {
            $resultz{$rqt} = !$ec;
        }
    }
}



sub main {

    mkdir($lhccertDir);

    # Initialize the data structure for the available scripts:
    readAllScripts();

    # Read the pattern. Form a plan of steps to execute:
    my $plan = shift;
    if (!$plan) { die("Must name plan"); }

    my $dryrun = shift;

    # Run just one step for debugging?
    if ($plan eq '-scriptlet') {
        for (;; ) {
            my $step = shift;
            last unless $step;
            runCheck($step);
        }
        exit 0;
    }

    addPlan($plan);

    if (0) {
        print "Scriptz:\n";
        print Data::Dumper::Dumper(\%Scriptz)."\n";

        print "Variantz:\n";
        print Data::Dumper::Dumper(\%Variantz)."\n";

        print "Byhandz:\n";
        print Data::Dumper::Dumper(\%Byhandz)."\n";

        print "Authorityz:\n";
        print Data::Dumper::Dumper(\%Authorityz)."\n";

        print "requiredz:\n";
        print Data::Dumper::Dumper(\%requiredz)."\n";

        print "waivedz:\n";
        print Data::Dumper::Dumper(\%waivedz)."\n";

        print "runs:\n";
        print Data::Dumper::Dumper(\@runs)."\n";

        print "runOrSkipz:\n";
        print Data::Dumper::Dumper(\%runOrSkipz)."\n";
    }

    # Execute the steps:
    if ($dryrun) {
        runDry();
    } else {
        runChecks();
    }

    # Compose report:

    my $VERDICT_EXAMINE='EXAMINE';
    my $VERDICT_EXAMINE_SEEALSO='DUPLICATE';
    my $VERDICT_MANUAL='(manual)';
    my $VERDICT_NOTIMPL='(not impl)';
    my $VERDICT_OK='ok';
    my $VERDICT_REQUIRED='scan';
    my $VERDICT_WAIVE='waive';
    my $VERDICT_SKIP='skip';

    my @REPORT_VERDICT_ORDER = ($VERDICT_REQUIRED, $VERDICT_EXAMINE, $VERDICT_EXAMINE_SEEALSO, $VERDICT_MANUAL, $VERDICT_NOTIMPL, $VERDICT_OK, $VERDICT_WAIVE, $VERDICT_SKIP);


    my %faillogprintedz; # scriptname=>rqt for which log was printed

    my %reportz; # status => list of lines
    my %verdictz; # verdict name => list of auth/items
    for my $authorityName (sort(keys(%Authorityz))) {
        for my $rqt (@{$Authorityz{$authorityName}{list}}) {
            my $ar = "$authorityName/$rqt";
            my $verdict = undef;
            my @seealso; # list of scripts whose transcripts to refer to
            my @faillog;
            if (exists($requiredz{$ar})) {
                # ok, (not impl), or EXAMINE:
                if (exists($resultz{$ar})) {
                    if ($resultz{$ar} == 2) {
                        $verdict = $VERDICT_REQUIRED;
                        for my $scriptname (@{$satisfyz{$ar}}) {
                            # Say something if the test should be explained in detail:
                            if (exists($scriptlogz{$scriptname})) {
                                if (!exists($faillogprintedz{$scriptname})) {
                                    push(@faillog, 
                                         split(/\n/,$scriptlogz{$scriptname}));
                                    $faillogprintedz{$scriptname} = $ar;
                                }
                                else {
                                    push(@seealso, $scriptname);
                                }
                            }
                        } 
                    }
                    elsif ($resultz{$ar} == 1) {
                        $verdict = $VERDICT_OK;
                    }
                    else {
                        $verdict = $VERDICT_EXAMINE; # may be revised below
                        # include germane failure logs (one time only):
                        for my $scriptname (@{$satisfyz{$ar}}) {
                            # Say something if the script failed:
                            if (exists($scriptlogz{$scriptname})) {
                                if (!exists($faillogprintedz{$scriptname})) {
                                    push(@faillog, 
#                                         "--- 8< --- Log from scriptlet $scriptname:");
                                         ".................... Log from scriptlet $scriptname:");
                                    push(@faillog, 
                                         split(/\n/,$scriptlogz{$scriptname}));
                                    push(@faillog, 
#                                         "--- >8 ---");
                                         ".................... end log");
                                    push(@faillog, 
                                         "");
                                    $faillogprintedz{$scriptname} = $ar;
                                }
                                else {
                                    push(@seealso, $scriptname);
                                }
                            } 
                        }
                        if (@seealso && !@faillog) {
                            $verdict=$VERDICT_EXAMINE_SEEALSO;
                        }
                    }
                }
                elsif (exists($satisfyz{$ar})) {
                    $verdict = $VERDICT_WAIVE;# no point distinguishing from SKIP; # all checks skipped
                }
                elsif (exists($Byhandz{$ar})) {
                    $verdict = $VERDICT_MANUAL;
                }
                else {
                    $verdict = $VERDICT_MANUAL; # no point distinguishing from NOTIMPL;
                }
            }
            elsif (exists($waivedz{$ar})) {
                $verdict = $VERDICT_WAIVE;
            }

            push(@{$reportz{$verdict}}, ());
            push(@{$verdictz{$verdict}}, $ar);
            my $report_section = $reportz{$verdict};

            push(@{$report_section}, 
                  sprintf("%15s %s %s\n", $verdict, $ar, 
                          $Authorityz{$authorityName}{reqts}{$rqt}));

            if (@faillog) {
                push(@$report_section, "\n"); # blank line
                push(@$report_section,
                     map(sprintf("%15s %s\n", '', $_), @faillog));
                if (@seealso) {
                    push(@$report_section, ((' ' x 15)." --  > > -- See also transcript(s) from scriptlet(s): ".join(', ', @seealso)."\n"));
                }
                push(@$report_section, "\n"); # blank line
            }
            elsif (@seealso) {
                push(@$report_section, ((' ' x 15)."--  > > -- See transcript(s) from scriptlet(s): ".join(', ', @seealso)));
            }

            push(@$report_section, "\n"); # blank line
        }
    }
    my %evalz; # auth/item => verdict name
    for my $verdict (keys(%verdictz)) {
        for my $authitem (@{$verdictz{$verdict}}) {
            $evalz{$authitem} = $verdict;
        }
    }

    my %key = 
        (
         $VERDICT_REQUIRED=>"The test should be run.",
         $VERDICT_OK=>"The computer is apparently compliant.",
         $VERDICT_EXAMINE=>"Might be noncompliant. Review transcript and verify manually.",
         $VERDICT_EXAMINE_SEEALSO=>"Additional requirements, the substance of which has already been reported above.",
         $VERDICT_MANUAL=>"Check by hand (no automated check possible).",
         $VERDICT_NOTIMPL=>"Script not written yet. Check by hand.",
         $VERDICT_WAIVE=>"Pattern \"$plan\" waives this requirement.",
         $VERDICT_SKIP=>"Pattern \"$plan\" skips these checks.",
         );

    if (!$dryrun) {
        
        # Write detailed report file:
        my $report_file = "$lhccertDir/lhccert_report";
        
        my $h = new FileHandle();
        open($h, '>', $report_file) || die("Could not open $report_file");
        #print $h "Summary of results, organized by requirement:\n";
        # Show all requirements (skipping those never either required or waived).
        # For each, show "waive", "ok", "(not impl)", or "EXAMINE".
        print $h "\n";
        
        my $a1divider = ('*' x 65);
        
        print $h "$a1divider\n";
        print $h "\nHost Certification - Detailed Report\n\n";
        print $h "Lhccertification version: $_VERSION\n\n";
        print $h "Lhccertification Release Date: $_VERSION_PRETTY\n\n";
        print $h "Pattern: $plan\n";
        print $h "Time:    $TIMESTAMP\n";
        print $h "\nFor best results, print landscape in monospace font.\n";
        print $h "\n$a1divider\n";
        
        print $h "\nKey:\n";
        # Omit EXAMINE_SEE_ALSO from the key:
        for my $v (grep(!/^$VERDICT_EXAMINE_SEEALSO/, @REPORT_VERDICT_ORDER)) {
            # Omit key entries that are not germane to the report:
            if (exists($verdictz{$v})) {
                print $h sprintf("%15s %s\n", $v, $key{$v});
            }
        }
        print $h "\n";
        print $h "\nSome results are listed in the form of \"diff\" or \"sdiff\" output, \n";
        print $h "comparing an existing, insecure, file with a proposed, secured, file.\n";
        print $h "For information about the diff notation, see \"man diff\" or \"man sdiff\".\n\n";
        print $h "$a1divider\n";
        
        # Copy the failure and ok sections to the report.
        for my $rstat (@REPORT_VERDICT_ORDER) {
            if (exists($reportz{$rstat})) {
                print $h "\n\n\"$rstat\" findings: $key{$rstat}\n\n";
                print $h join('', @{$reportz{$rstat}});
            }
        }
        
        print $h "$a1divider\n";
        
        
        print $h "End of report\n";
        
        close($h);
        
        print "\n\nReport written: $report_file\n";
    }


    # Write report summary (for dry-run and real assessment):
    {
        my $summary_file = "$lhccertDir/lhccert_summary";
        my $h = new FileHandle();
        open($h, '>', $summary_file) || die("Could not open $summary_file");
        #print $h "Summary of results, organized by requirement:\n";
        # Show all requirements (skipping those never either required or waived).
        # For each, show "waive", "ok", "(not impl)", or "EXAMINE".
        print $h "\n";
        
        my $a1divider = ('*' x 65);
        
        print $h "$a1divider\n";
        print $h "\nHost Certification - Summary Report\n\n";
        print $h "Pattern: $plan\n";
        print $h "Time:    $TIMESTAMP\n";
        print $h "\nFor best results, print landscape in mono font.\n";
        print $h "\n$a1divider\n";
        
        print $h "\nKey:\n";
        # Omit " EXAMINE" from the key:
        for my $v (grep(!/^$VERDICT_EXAMINE_SEEALSO/, @REPORT_VERDICT_ORDER)) {
            print $h sprintf("%15s %s\n", $v, $key{$v});
        }
        print $h "\n";
        print $h "$a1divider\n";
        
        # Copy the failure and ok sections to the report.
        for my $rstat (grep(!/^( EXAMINE|ok)$/, @REPORT_VERDICT_ORDER)) {
            if (exists($verdictz{$rstat})) {
                if ($rstat eq 'ok') {
                    print $h sprintf("\n%d \"$rstat\" - see detailed report\n", 0+@{$verdictz{$rstat}});
                }
                else {
                    print $h sprintf("\n%d \"$rstat\":  $key{$rstat}\n", 0+@{$verdictz{$rstat}});
                    for my $summary_item (@{$verdictz{$rstat}}) {
                        my ($authorityName, $rqt) = split(/\//, $summary_item);
                        print $h sprintf("%5s %-12s %s\n", ' ', $summary_item, 
                                         $Authorityz{$authorityName}{reqts}{$rqt});
                    }
                    
                    if ($rstat eq 'EXAMINE') {
                        if (exists($verdictz{' EXAMINE'})) {
                            print $h sprintf("%5s...Plus %d similar requirement(s) - see detailed report\n", '', 0+@{$verdictz{' EXAMINE'}});
                        }
                    }
                }
            }
        }
        
        
        print $h "End of summary\n";
        
        close($h);
        
        print "\n\nSummary written: $summary_file\n";
    }

    # Write coverage report (for dry run and real assessment):
    {
        my $coverage_file = "$lhccertDir/lhccert_coverage";

        my $h = new FileHandle();
        open($h, '>', $coverage_file) || die("Could not open $coverage_file");
        print $h "\n";
        
        my $a1divider = ('*' x 65);
        
        print $h "$a1divider\n";
        print $h "\nHost Certification - Requirement-Coverage Report\n\n";
        print $h "Pattern: $plan\n";
        print $h "Time:    $TIMESTAMP\n";
        print $h "\nFor best results, print landscape in mono font.\n";
        print $h "\n$a1divider\n";
        
        print $h "$a1divider\n";
        
        for my $a (sort(keys(%Authorityz))) {

            print $h "Authority: $a\n";

            for my $rk (@{$Authorityz{$a}{'list'}}) {

                my $title = $Authorityz{$a}{'reqts'}{$rk};

                my $verdict = $evalz{"$a/$rk"};

                print $h sprintf("%-10s %-10s %s\n", $rk, $verdict, $title);
            }
        }

        my %scriptsWithVariantz; # set
        for my $variantScript (sort(keys(%Variantz))) {
            $scriptsWithVariantz{$Variantz{$variantScript}[0]}=1;
        }
        my @scriptNames = grep(!exists($scriptsWithVariantz{$_}), keys(%Scriptz));
        
        my %runz = map( ($_=>1) , @runs);
        
        my %bigscriptz; # script(not variant) -> +{ runs=>+[scriptnames], skips=>+[scriptnames] } 
        
        for my $scriptName (sort(@scriptNames)) {
            if ($runz{$scriptName}) { 
                push(@{$bigscriptz{$Variantz{$scriptName}[0]}{'run'}}, $scriptName);
            }
            else { 
                my $nWaived = 0;
                my $nRequired = 0;
                for my $r (@{$Scriptz{$scriptName}->{'auth'}}) {
                    if (exists($waivedz{$r})) { $nWaived++; }
                    elsif (exists($requiredz{$r})) { $nRequired++; }
                }
                if ($nRequired > 0) {
                    push(@{$bigscriptz{$Variantz{$scriptName}[0]}{'skip'}}, $scriptName);
                }
                elsif ($nWaived > 0) {
                    push(@{$bigscriptz{$Variantz{$scriptName}[0]}{'waive'}}, $scriptName);
                }
                else { 
                    push(@{$bigscriptz{$Variantz{$scriptName}[0]}{'leftover'}}, $scriptName);
                }
            }
        }
        
        # Excerpt of non-empty keys from bigscriptz where there is an interesting diversity:
        my @partials = grep($_ && 1<0+keys(%{$bigscriptz{$_}}), keys(%bigscriptz));
        
        if (@partials) {
            
            print $h "Elements of the following scriptlets (tests) run selectively:\n";
            
            for my $partial (sort(@partials)) {
                print $h "Scriptlet: $partial\n";
                
                my %m; # scriptName => run/skip/waive
                for my $k (sort(keys(%{${bigscriptz{$partial}}}))) {
                    for my $sv (sort(@{$bigscriptz{$partial}{$k}})) {
                        $m{$sv} = $k;
                    }
                }
                
                for my $scriptName (sort(keys(%m))) {
                    print $h sprintf("  %-10s %s\n", $m{$scriptName}, $scriptName);

                } 

                if (0) {
                    for my $k (sort(keys(%{${bigscriptz{$partial}}}))) {
                        print $h "  $k\n";
                        for my $sv (sort(@{$bigscriptz{$partial}{$k}})) {
                            print $h "    $sv\n";
                        }
                    }
                }
                
            }
        }

        print $h "End of coverage report\n";
        
        close($h);
        
        print "\n\nCoverage report written: $coverage_file\n";
    }

}

my $man = 0;
my $help = 0;
my $scriptlet = undef;
my $dryrun = 0;

GetOptions('help|?'=>\$help, 
           'man'=>\$man, 
           'cert_dir=s'=>\$lhccertDir,
           'scriptlet=s'=>\$scriptlet,
           'dryrun!'=>\$dryrun) or pod2usage(2);
pod2usage(1) if $help;
# Use -noperldoc to prevent spawning perldoc process,
# which evidently does not work in a minimal RHEL installation?
pod2usage('-exitstatus' => 0, '-verbose' => 2, '-noperldoc' => 1) if $man;

# Must specify either a scriptlet or a pattern

if ($scriptlet) {
    &main( '-scriptlet', $scriptlet );
}
else {
    my $pattern = shift;
    pod2usage('-message'=>'Please specify a pattern!','-verbose' => 1, '-noperldoc' => 1) unless $pattern;
              
    &main( $pattern, $dryrun );
}

__END__

=head1 NAME

check - Execute hardening-assessment checklists

=head1 SYNOPSIS

 check InternalWorkstation
 check PublicServer

 less /Certification/lhccert_summary
 less /Certification/lhccert_report

=head1 PARAMETERS

The parameter names a "pattern".  Patterns are files located at the
relative location F<../lib/resources/Pattern/>.  Three patterns are
included:

=over 4

=item PublicServer

Suitable for unattended computers in a physically-secure DMZ.
Requires most authority checklists, but waives some specific
requirements that do not apply in LHC's environment.

=item InternalWorkstation

Suitable for workstations in a somewhat protected environment.
"Includes" PublicServer as a foundation, but waives some requirements
that do not apply to workstations (e.g., "Disable GUI login").

=item CTInternalWorkstation

"Includes" InternalWorkstation as a foundation, but additionally
requires SecurID and permits a cron user.

=back



=head1 OPTIONS

=over 8

=item B<--help>

Show help

=item B<--man>

Show more complete documentation

=item B<--scriptlet=SCRIPTLET>

Just execute one specific scriptlet (instead of all scriptlets implied
by a Pattern).  Specify only the basename (not the directory) of the
scriptlet.  All scriptlets are in the subdirectory F<scriptlets/>
under the location of the check script.

=item B<--cert_dir=DIRECTORY>

Where to put the reports. By default, reports go in F</Certification>.
See REPORTS below.

=item B<--dryrun>

Writes a report without running any tests.  Instead of pass/fail
results, the report shows the requirements that would be tested
and the requirements that would be waived.


=back

=head1 REPORTS

The program writes two reports and a directory full of suggestions:

=over 8

=item /Certification/lhccert_summary

Brief report.

=item /Certification/lhccert_report

Full report.

=item /Certification/trail_YYYY_MM_DD_HH_MM/

Directory full of suggestions:

 trail_YYYY_MM_DD_HH_MM/
   bak/
     etc/
       somefile.conf    <-- original version
   new/
     etc/
       somefile.conf    <-- suggestion

=back


=head1 DESCRIPTION

The "check" program reports on compliance with various security
checklists (see AUTHORITIES below).

The user specifies the Pattern that best describes the computer being
examined.  The Pattern, in turn, lists the checklists ("Authorities")
and specific checklist items that apply.  The package includes
numerous "scriptlets", each of which addresses a certain checklist
item or group of checklist items (as the checklists tend to overlap).
The "check" program executes enough scriptlets to test the checklist
items prescribed by the applicable Pattern, then reports on the
results.

=head1 AUTHORITIES

Authorities are files located at the relative location
F<../lib/resources/Authority/>.  An Authority's file name must begin
with a letter and be composed of just letters and digits.  

Each Authority file consists of a list (one per line) of requirements.
Each requirement consists of the requirement's official identifier
(number or label) and its name, separated by whitespace.  The label
may consist of letters, digits, dots, commas, and dashes.

Each requirement is fully qualified (in Pattern files and reports) by
combining the authority file name, "/", and the requirement label.

It's quite all right for Authorities to overlap in their requirements
- for example, nine out of ten of them might require that the root
password not be "root".

Authority files do not specify - indeed, most of the authorities
themselves did not prescribe - I<how> to check their requirements.
Authority files are merely I<lists> of requirements.  Pattern files
and Scriptlets refer to requirements by their authority file name
and label - so keep those stable!

The following Authorities are included.

=over 8

=item CIS

Center for Internet Security, Linux Benchmark v1.1.0

=item CIS5

Center for Internet Security, RHEL5 Benchmark

=item HHS

HHS Minimum Security Configuration Standards for Departmental Operating Systems and Applications 8/28/2006

=item LHC

LHC Unix System Hardening Guidelines

=item Local

Miscellaneous requests and requirements that are not in any of the above checklists

=back

=cut

