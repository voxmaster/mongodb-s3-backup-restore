#!/bin/sh

# Fill the variables:
BUCKET="project-backup"
FILE_PREFIX="project-mongo-prod"
TMP_DIR="/tmp/mongorestore"
MONGO_HOST=localhost
MONGO_PORT="27017"
MONGO_DB_NAME="project"

# Dependency check:
if which aws > /dev/null; then echo ; else echo "Instal awscli and configure it, before using this script!" ; fi
if which mongorestore > /dev/null; then echo ; else sudo apt-get install -y mongo-tools; fi
# Color output:
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Get last modified file from S3 or ask for custom input
LAST_MODIFIED_FILE=$(aws s3 ls s3://$BUCKET | grep ${FILE_PREFIX} | sort | tail -n 1 | awk '{print $4}')
echo "Found this file as last modified: ${GREEN} ${LAST_MODIFIED_FILE} ${NC}"
read -p "Continue restore(Y/N) or (S)list s3 and Select file? `echo $'\n> '`" choice
case "$choice" in 
  y|Y ) echo "OK!" && RESTORE_FILE=$LAST_MODIFIED_FILE ;;
  n|N ) echo "Interupting" && exit ;;
  s|S ) aws s3 ls s3://$BUCKET | sort
        read -p "Input filename `echo $'\n> '`" RESTORE_FILE ;;
  * ) echo "Invalid input. Interupting" && exit ;;
esac
echo "\n"

# Check if file exists in S3
echo "File has following attibutes:"
aws s3 ls s3://$BUCKET/${RESTORE_FILE}
if [[ $? -ne 0 ]]; then
  echo "File does not exist. Interupting." && exit
fi
echo "\n"

# 
rm -rf ${TMP_DIR} && mkdir -p ${TMP_DIR}
aws s3 cp s3://$BUCKET/${RESTORE_FILE} ${TMP_DIR}
tar -zxvf ${TMP_DIR}/${RESTORE_FILE} -C ${TMP_DIR}

# OLD BACKUP STYLE:
# mongorestore --drop -v --host ${MONGO_HOST}:${MONGO_PORT} --db ${MONGO_DB_NAME} /${TMP_DIR}/tmp/mongodump/${MONGO_DB_NAME}
# NEW BACKUP STYLE:
mongorestore --drop -v --host ${MONGO_HOST}:${MONGO_PORT} --db ${MONGO_DB_NAME} /${TMP_DIR}/${MONGO_DB_NAME}
# TODO:
# Add ability to restore collection only
# Add colorized output
#   mongo --host localhost:27017 ${MONGO_DB_NAME} --eval 'db.${MONGO_COLLECTION_NAME}.remove({})'
#   mongorestore -v --db ${MONGO_DB_NAME} --host localhost:27017 --collection ${MONGO_COLLECTION_NAME} /${TMP_DIR}/${MONGO_DB_NAME}/${MONGO_COLLECTION_NAME}.bson 
