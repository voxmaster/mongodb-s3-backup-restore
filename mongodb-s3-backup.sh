#!/bin/sh

# Dependency check:
if which aws > /dev/null; then echo ; else echo "Instal awscli and configure it, before using this script!" ; fi
if which mongorestore > /dev/null; then echo ; else sudo apt-get install -y mongo-tools; fi #Works for Ubuntu LTS 2018

# Make sure to:
# 1) Name this file `backup.sh` and place it in /home/ubuntu
# 2) Run sudo apt-get install awscli to install the AWSCLI
# 3) Run aws configure (enter s3-authorized IAM user and specify region)
# 4) Fill in DB host + name
# 5) Create S3 bucket for the backups and fill it in below (set a lifecycle rule to expire files older than X days in the bucket)
# 6) Run chmod +x backup.sh
# 7) Test it out via ./backup.sh
# 8) Set up a daily backup at midnight via `crontab -e`:
#    0 0 * * * /home/ubuntu/backup.sh > /home/ubuntu/backup.log

# DB host (secondary preferred as to avoid impacting primary performance)
HOST=localhost

# DB name
DBNAME=project

# S3 bucket name
BUCKET="project-backup"

# File prefix
FILE_PREFIX="project-mongo-prod"

# Current time
TIME=`/bin/date +%Y_%m_%d-%H_%M`

# Backup directory
DEST="/tmp/mongodump"

# Tar file of backup directory
TAR=$DEST/../$FILE_PREFIX-$TIME.tar.gz

# Remove backup directory
/bin/rm -rf $DEST

# Create backup dir (-p to avoid warning if already exists)
/bin/mkdir -p $DEST

# Log
echo "Backing up $HOST/$DBNAME to s3://$BUCKET/ on $FILE_PREFIX-$TIME";

# Dump from mongodb host into backup directory
/usr/bin/mongodump -h $HOST -d $DBNAME -o $DEST

# Create tar of backup directory
/bin/tar zcvf $TAR -C $DEST .

# Upload tar to s3
/usr/bin/aws s3 cp $TAR s3://$BUCKET/

# Remove tar file locally
/bin/rm -f $TAR

# All done
echo "Backup available at https://s3.amazonaws.com/$BUCKET/$FILE_PREFIX-$TIME.tar.gz"
