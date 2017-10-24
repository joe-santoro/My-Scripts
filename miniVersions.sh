#!/usr/bin/env bash
# sample scripti to log into several machine and check various software version

#for n in "mini1" "mini2" "mini5" "mini6" "mini7" "mini8" "mini9"
for n in "mini7" "mini8" "mini9" "lhcp-vm-osx12-1"
do
    echo "===" $n "==="
    ssh $n "sw_vers -productVersion; xcodebuild -version; sysctl -n machdep.cpu.brand_string" 2> /dev/null
    echo
done


#for n in "vm-osx106" "vm-osx109" "vm-osx1010" "vm-osx1011" "vm-osx1012"
for n in "vm-osx106"
do
    echo "===" $n "==="
    ssh mini9 ssh $n "sw_vers -productVersion\; xcodebuild -version\; sysctl -n machdep.cpu.brand_string" 2> /dev/null
    echo
done

