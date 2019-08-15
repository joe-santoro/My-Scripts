#!/bin/bash
# Adapted by J. Santoroski for the LHC environment
#
# Script to publish monthly content views
# This script will take the latest version of each composite content view and promote it from Library -> Testing and 
# then promote it from Testing to Production
#

COMPOSITE_CONTENT_VIEW=`/bin/hammer --no-headers --csv content-view list --composite yes | grep -v -e Default_Organization_View | awk -F "," '{print $1}'`

for x in $COMPOSITE_CONTENT_VIEW; do
	LATEST_CV=`/bin/hammer --no-headers --csv content-view version list --content-view-id $x --organization-id 1 | awk -F "," '{print $3}' | sort -nr | head -n1`
	/bin/hammer content-view version promote --version $LATEST_CV --organization-id 1 --content-view-id $x --to-lifecycle-environment "Testing" --force
	/bin/hammer content-view version promote --version $LATEST_CV --organization-id 1 --content-view-id $x --to-lifecycle-environment "Production" --force
	/bin/hammer content-view purge --organization-id 1 --id $x
done
