# ep-dept-report
Use to generate a report from eprints repository on how many deposits from each department and how many documents (open access and private)
First version from eprints wiki at http://wiki.eprints.org/w/Departmental_report_script

First, make sure to refresh the user index with:
./epadmin reindex <REPOSITORY> user

This script gives an output to STDOUT and a CSV file - we're interested in 'new' outputs that have an eprintID over 2,000,000 but I'm sure you could use another test, such as the date in the SCONUL_Report

save in your eprints bin directory

Run with the following: 
perl repo-department-report.pl <REPOSITORY>

you can capture the output with something like ' > dept-report.txt '
