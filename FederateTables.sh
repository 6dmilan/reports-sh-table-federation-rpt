#!/bin/bash
if [ "$1" = "" ]
then
	echo "Script exiting !!!"
	exit 1
fi
scriptPath=$1

if [ -f ${scriptPath}/common.properties ] 
then
	. ${scriptPath}/common.properties
else
echo -e "\n========= Script exiting !! configuration file : \"${scriptPath}/common.properties\" : unavailable ==========\n"
fi
MYSQL_SRC_CONN="mysql -h${source_db_ip} -P${source_db_port} -u${source_db_user} -p${source_db_pwd} ${source_db_name}"
MYSQL_DEST_CONN="mysql -h${dest_db_ip} -P${dest_db_port} -u${dest_db_user} -p${dest_db_pwd} ${dest_db_name}"

echo -e "\n#######================= STARTED at `date "+%D %T"` =======================########"

if [ ${NO_OF_TABLES_TO_PROCESS} -gt 0 ]
then
tableId=1
while [ ${tableId} -le ${NO_OF_TABLES_TO_PROCESS} ]
do
	sourceTable="SRC_TABLE_"${tableId}
	sourceColumns="SRC_COLUMNS_"${tableId}
	destTable="DEST_TABLE_"${tableId}
	destColumns="DEST_COLUMNS_"${tableId}

	outfileLocation="OUTFILE_LOCATION_"${tableId}
	outfileName="OUTFILE_NAME_"${tableId}
	fieldsSeparator="FIELDS_SEPARATOR_"${tableId}
	linesTerminator="LINES_TERMINATOR_"${tableId}
	echo -e "\n<========Processing \"${!sourceTable}\" started at `date "+%D %T"`=======>"
	echo "----------------------------------------------------------------------"
	echo ${sourceTable} :: ${!sourceTable}
	echo ${sourceColumns} :: ${!sourceColumns}
	echo ${destTable} :: ${!destTable}
	echo ${destColumns} :: ${!destColumns}
	echo ${outfileLocation} :: ${!outfileLocation}
	echo ${outfileName} :: ${!outfileName}
	echo ${fieldsSeparator} :: ${!fieldsSeparator}
	echo ${linesTerminator} :: ${!linesTerminator}
	echo "----------------------------------------------------------------------"
	if [ -f ${!outfileLocation}/${!outfileName} ]
	then
	rm -rvf ${!outfileLocation}/${!outfileName}
	fi
	echo "<<< OUTFILE QUERY >>> select ${!sourceColumns} from ${!sourceTable} into outfile '${!outfileLocation}/${!outfileName}' fields terminated by '${!fieldsSeparator}' lines terminated by '${!linesTerminator}'"
	${MYSQL_SRC_CONN} -e "select ${!sourceColumns} from ${!sourceTable} into outfile '${!outfileLocation}/${!outfileName}' fields terminated by '${!fieldsSeparator}' lines terminated by '${!linesTerminator}'" > ${scriptPath}/log_outfile.log 2>&1 
	wait
	cat ${scriptPath}/log_outfile.log | grep -v "Warning" > ${scriptPath}/log_outfile.err; #rm -rf ${scriptPath}/log_outfile.log
	if [ -s ${scriptPath}/log_outfile.err ]
	then
		echo -e "\n ====Error generating outfile !!!====="
		cat ${scriptPath}/log_outfile.err
		exit 1
	fi
	echo "Outfile generated :: \"${!outfileLocation}/${!outfileName}\" :: `date "+%D %T"`"
	
	echo "<<< TRUNCATE QUERY >>> truncate table ${!destTable}"
	${MYSQL_DEST_CONN} -e "truncate table ${!destTable}" > ${scriptPath}/log_truncate.log 2>&1
	wait
	cat ${scriptPath}/log_truncate.log | grep -v "Warning" > ${scriptPath}/log_truncate.err; #rm -rf ${scriptPath}/log_truncate.log
	if [ -s ${scriptPath}/log_truncate.err ]
        then
                echo -e "\n ====Error truncating table \"${!destTable}\" !!!====="
                cat ${scriptPath}/log_truncate.err 
                exit 1
        fi
	echo "Truncated \"${!destTable}\" at `date "+%D %T"`"
	echo "<<< LOAD QUERY >>> load data local infile '${!outfileLocation}/${!outfileName}' into table ${!destTable} fields terminated by '${!fieldsSeparator}' lines terminated by '${!linesTerminator}' (${!destColumns}) ;"

	 ${MYSQL_DEST_CONN} <<- EOF > ${scriptPath}/log_load.log 2>&1
	set autocommit = 0;
	load data local infile '${!outfileLocation}/${!outfileName}' into table ${!destTable} fields terminated by '${!fieldsSeparator}' lines terminated by '${!linesTerminator}' (${!destColumns}) ;
	commit;
	EOF
	wait
	cat ${scriptPath}/log_load.log | grep -v "Warning" > ${scriptPath}/log_load.err; #rm -rf ${scriptPath}/log_load.log 
	if [ -s ${scriptPath}/log_load.err ]
	then
		echo -e "\n====Error loading data into table !!!====="
		cat ${scriptPath}/log_load.err
		exit 1
	fi
	echo "Loaded  \"${!outfileLocation}/${!outfileName}\" into \"${!destTable}\"  at `date "+%D %T"`"
	tableId=$[ ${tableId} + 1 ]
done
else
	echo "No tables to process this time !! Please check \"NO_OF_TABLES_TO_PROCESS\" parameter in \"${scriptPath}/common.properties\""
fi
echo -e "\n#######================= COMPLETED at `date "+%D %T"` =======================########"
