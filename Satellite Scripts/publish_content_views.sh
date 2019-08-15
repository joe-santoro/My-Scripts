#!/bin/bash
# Adapted by J. Santoroski for the LHC enviroment
#
# Script to publish monthly content views
CONTENT_VIEW=`/bin/hammer --no-headers --csv content-view list --composite no | grep -v -e Default_Organization_View |  awk -F "," '{print $1}'`
COMPOSITE_CONTENT_VIEW=`/bin/hammer --no-headers --csv content-view list --composite yes | grep -v -e Default_Organization_View |  awk -F "," '{print $1}'`
REPO=`/bin/hammer --no-headers --csv repository list | grep -v -e file -e puppet |  awk -F "," '{print $1}'`

for x in $REPO
	do
	/bin/hammer repository synchronize --id $x --organization-id 1
done

#SYNC=`/bin/hammer product list  --organization-id 1 | grep -i running| wc -l`
#while [ $SYNC != 0 ]
#	do
#	echo "repos are still syncing "
#	/bin/hammer product list  --organization-id 1 | grep -i running | awk -F "|" '{print $2 }'
#	sleep 360
#	SYNC=`/bin/hammer product list  --organization-id 1 | grep -i running| wc -l`
#done

logger "Publishing Monthly Content Views"
for x in $CONTENT_VIEW
	do
	/bin/hammer content-view publish --organization-id 1 --id $x  --description 'Automated Monthly update to latest RPMs'
	/bin/hammer content-view purge --organization-id 1 --id $x
done

logger "Publishing Monthly Composite Content Views"
for x in $COMPOSITE_CONTENT_VIEW
	do
	/bin/hammer content-view publish --organization-id 1 --id $x  --description 'Automated Monthly update to latest RPMs'
	/bin/hammer content-view purge --organization-id 1 --id $x
done
