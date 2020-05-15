# Q-SIS-Updater
 Copies updated Q SIS files to a collection of webservers.

## Setup:
The updater currently supports distribution of files to 3 different environments - testing, production and reporting. The "reporting" environment is spefically for dedicated reporting servers. To get started:
* Copy or rename the files in the /servers folder and rename them to just testing, reporting, and production. 
* Each file should contain a list of all coresponding machine names, one machine name per line.
* Review the config.txt file and make any needed changes. More details on config coming soon.
* In the "Payloads" directory, delete "filesGoHere.txt" file and copy in all updated files to deploy to the appropriate environment directories
