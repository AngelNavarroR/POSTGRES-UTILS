#!/bin/bash

export PGPASSWORD=pass

echo "`date` $OSTYPE"
##############################
## POSTGRESQL BACKUP CONFIG ##
##############################

# Optional system user to run backups as.  If the user the script is running as doesn't match this
# the script terminates.  Leave blank to skip check.
BACKUP_USER=

# Optional hostname to adhere to pg_hba policies.  Will default to "localhost" if none specified.
HOSTNAME=

# Optional username to connect to database as.  Will default to "postgres" if none specified.
USERNAME=sisapp

# Optional password to connect to database as.  Will default to "postgres" if none specified.
PASSWORD=password

# This dir will be created if it doesn't exist.  This must be writable by the user the script is
# running as.
BACKUP_DIR=/home/backups/postgresql/

# List of strings to match against in database name, separated by space or comma, for which we only
# wish to keep a backup of the schema, not the data. Any database names which contain any of these
# values will be considered candidates. (e.g. "system_log" will match "dev_system_log_2010-01")
SCHEMA_ONLY_LIST=""

# Will produce a custom-format backup if set to "yes"
ENABLE_CUSTOM_BACKUPS=yes

# Will produce a gzipped plain-format backup if set to "yes"
ENABLE_PLAIN_BACKUPS=no

# Will produce gzipped sql file containing the cluster globals, like users and passwords, if set to "yes"
ENABLE_GLOBALS_BACKUPS=no

#### SETTINGS FOR ROTATED BACKUPS ####
# Which day to take the weekly backup from (1-7 = Monday-Sunday)
DAY_OF_WEEK_TO_KEEP=5

# Number of days to keep daily backups
DAYS_TO_KEEP=7

# How many weeks to keep weekly backups
WEEKS_TO_KEEP=5

# Deshalita la eliminacion de los archivos generados
DISABLE_DELETE_BACKUP=yes

###########################
#### PRE-BACKUP CHECKS ####
###########################

# Make sure we're running as the required backup user
if [ "$BACKUP_USER" != "" -a "$(id -un)" != "$BACKUP_USER" ] ; then
	echo "`date` This script must be run as $BACKUP_USER. Exiting." 1>&2 | tee -a PGBACUKPS_LOGS.txt
	exit 1
fi

###########################
### INITIALISE DEFAULTS ###
###########################

if [ ! $HOSTNAME ]; then
	HOSTNAME="localhost"
fi;

if [ ! $USERNAME ]; then
	USERNAME="postgres"
fi;


###########################
#### START THE BACKUPS ####
###########################
DIR_="`pwd`"
LAST_DATABASE = "" 
function perform_backups()
{
	SUFFIX=$1
	FINAL_BACKUP_DIR=$BACKUP_DIR"`date +\%Y/\%m/\%d/\%H`/"
	COMPRESS_FILE="`date +\%Y\%m\%d\%H`.tar.gz"
	#pgsql= if [[ "$OSTYPE" == "msys" ]]; then
	echo "`date` Making backup directory in $FINAL_BACKUP_DIR"

	if ! mkdir -p $FINAL_BACKUP_DIR; then
		echo "`date` Cannot create backup directory in $FINAL_BACKUP_DIR. Go and fix it!" 1>&2 | tee -a PGBACUKPS_LOGS.txt
		exit 1;
	fi;
	
	#######################
	### GLOBALS BACKUPS ###
	#######################

	if [ $ENABLE_GLOBALS_BACKUPS = "yes" ]
	then
			echo -e "\n\n`date` Performing globals backup" | tee -a PGBACUKPS_LOGS.txt
			echo -e "--------------------------------------------\n" | tee -a PGBACUKPS_LOGS.txt
		    echo "`date` Globals backup" | tee -a PGBACUKPS_LOGS.txt
			
		    set -o pipefail
		    if ! pg_dumpall -g -h "$HOSTNAME" -U "$USERNAME" | gzip > $FINAL_BACKUP_DIR"globals".sql.gz.in_progress; then
		            echo "`date` [!!ERROR!!] Failed to produce globals backup" 1>&2
		    else
		            mv $FINAL_BACKUP_DIR"globals".sql.gz.in_progress $FINAL_BACKUP_DIR"globals".sql.gz
		    fi
		    set +o pipefail
	else
		echo "`date` Globals backup None" | tee -a PGBACUKPS_LOGS.txt
	fi
	
	
	###########################
	###### FULL BACKUPS #######
	###########################

	for SCHEMA_ONLY_DB in ${SCHEMA_ONLY_LIST//,/ }
	do
		EXCLUDE_SCHEMA_ONLY_CLAUSE="$EXCLUDE_SCHEMA_ONLY_CLAUSE and datname !~ '$SCHEMA_ONLY_DB'"
	done

	FULL_BACKUP_QUERY="select datname from pg_database where not datistemplate and datallowconn $EXCLUDE_SCHEMA_ONLY_CLAUSE order by datname;"

	echo -e "\n\n`date` Performing full backups" | tee -a PGBACUKPS_LOGS.txt
	echo -e "--------------------------------------------\n" | tee -a PGBACUKPS_LOGS.txt
	for DATABASE in `psql -h "$HOSTNAME" -U "$USERNAME" -At -c "$FULL_BACKUP_QUERY" postgres`
	do
		if [ $ENABLE_PLAIN_BACKUPS = "yes" ]
		then
			echo "`date` Plain backup of $DATABASE" | tee -a PGBACUKPS_LOGS.txt
			set -o pipefail
			if ! pg_dump -Fp -h "$HOSTNAME" -U "$USERNAME" "$DATABASE" | gzip > $FINAL_BACKUP_DIR"$DATABASE".sql.gz.in_progress; then
				echo "`date` [!!ERROR!!] Failed to produce plain backup database $DATABASE" 1>&2 | tee -a PGBACUKPS_LOGS.txt
			else
				mv $FINAL_BACKUP_DIR"$DATABASE".sql.gz.in_progress $FINAL_BACKUP_DIR"$DATABASE".sql.gz
			fi
			set +o pipefail
                        
		fi

		if [ $ENABLE_CUSTOM_BACKUPS = "yes" ]
		then
			FILE_DATABASE=$DATABASE"_`date +\%H-\%M-\%S`"
			LAST_DATABASE=$FILE_DATABASE
			echo "`date` Custom backup of $DATABASE final file $FILE_DATABASE"
			if ! pg_dump -Fc -h "$HOSTNAME" -U "$USERNAME" "$DATABASE" -f $FINAL_BACKUP_DIR"$FILE_DATABASE".backup.in_progress; then
				echo "`date` [!!ERROR!!] Failed to produce custom backup database $DATABASE" | tee -a PGBACUKPS_LOGS.txt
			else
				mv $FINAL_BACKUP_DIR"$FILE_DATABASE".backup.in_progress $FINAL_BACKUP_DIR"$FILE_DATABASE".backup
			fi
		fi

	done
	# La utlima base de la renombramos manualmente
	mv $FINAL_BACKUP_DIR"$LAST_DATABASE".backup.in_progress $FINAL_BACKUP_DIR"$LAST_DATABASE".backup
	# Empezamos a comprimir el directorio con los backup 
	echo "`date` Directorio actual `pwd` " | tee -a "$DIR_/"PGBACUKPS_LOGS.txt
	cd $FINAL_BACKUP_DIR
	echo "`date` Directorio actual `pwd` " | tee -a "$DIR_/"PGBACUKPS_LOGS.txt
	cd .. 
	echo "`date` Ingreso a directorio `pwd` " | tee -a "$DIR_/"PGBACUKPS_LOGS.txt
	echo "`date` $COMPRESS_FILE >> ${FINAL_BACKUP_DIR::-1} " | tee -a "$DIR_/"PGBACUKPS_LOGS.txt
	
	#if 
	tar czfv "$COMPRESS_FILE" "${FINAL_BACKUP_DIR::-1}" && rm -rf $FINAL_BACKUP_DIR #; then
	wait $!
	#sleep 30s
	#rm -rf $FINAL_BACKUP_DIR
	#fi
	# FINAL_BACKUP_DIR
	echo -e "\n`date` All database backups complete!" | tee -a "$DIR_/"PGBACUKPS_LOGS.txt
	
}

# MONTHLY BACKUPS

DAY_OF_MONTH=`date +%d`

if [ $DISABLE_DELETE_BACKUP = "no" ];
then 
	if [ $DAY_OF_MONTH -eq 1 ];
	then
		# Delete all expired monthly directories
		find $BACKUP_DIR -maxdepth 1 -name "*-monthly" -exec rm -rf '{}' ';'
					
		perform_backups "-monthly"
		
		exit 0;
	fi
	# WEEKLY BACKUPS
	DAY_OF_WEEK=`date +%u` #1-7 (Monday-Sunday)
	EXPIRED_DAYS=`expr $((($WEEKS_TO_KEEP * 7) + 1))`

	if [ $DAY_OF_WEEK = $DAY_OF_WEEK_TO_KEEP ];
	then
		# Delete all expired weekly directories
		find $BACKUP_DIR -maxdepth 1 -mtime +$EXPIRED_DAYS -name "*-weekly" -exec rm -rf '{}' ';'
					
		perform_backups "-weekly"
		
		exit 0;
	fi

	# DAILY BACKUPS
	# Delete daily backups 7 days old or more
	find $BACKUP_DIR -maxdepth 1 -mtime +$DAYS_TO_KEEP -name "*-daily" -exec rm -rf '{}' ';'

fi
perform_backups "-daily"
