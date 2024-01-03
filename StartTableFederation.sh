#!/bin/bash

#scriptPath to be configured with the current path of the script
scriptPath="/home/dbteamuser/SALES_LEAD/TableFederation"

#logPath to be configured with a valid directory to write the logs
logPath="/home/dbteamuser/SALES_LEAD/TableFederation/Logs"

echo "#### Processing started at `date "+%D %T"` ####"
echo -e "\n----Logs available at :: ${logPath}/FederateTables_$(date "+%Y_%m_%d").log ----- \n"
sh ${scriptPath}/FederateTables.sh ${scriptPath} >> ${logPath}/FederateTables_$(date "+%Y_%m_%d").log 2>&1
wait
echo "#### Processing completed at `date "+%D %T"` ####"

