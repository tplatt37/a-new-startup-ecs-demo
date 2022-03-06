#!/bin/bash
# Must pass in the bucket name you want to use.

# Must pass in an s3 bucket (private) where the source code zip can be stored...
if [ -z $1 ]; then
        echo "Need the S3 Bucket Name as a parameter. Exiting..."
        exit 1
fi
BUCKET=$1

PREFIX=a-new-startup-ecs

# First, we create a Zip of the latest A-New-Startup app code from Github,
# and copy it into the S3 bucket.  Cloudformation will use that to seed the CC repo.

# Make sure we don't have this folder local
rm -rf a-new-startup-github 

git clone git@github.com:tplatt37/a-new-startup.git a-new-startup-github

# NOTE: When we zip, we ignore .git folder, but include other hidden files and folders! 
cd a-new-startup-github && zip -r --exclude=*.git/* ../a-new-startup.zip ./* .[^.]* && cd ..

echo "Copying application source zip to S3 bucket"
aws s3 cp a-new-startup.zip s3://$BUCKET

# Do the same, but for the ui testing code.

# Make sure we don't have this folder local
rm -rf a-new-startup-ui-tests-github 

git clone git@github.com:tplatt37/a-new-startup-ui-tests.git a-new-startup-ui-tests-github

# NOTE: When we zip, we ignore .git folder, but include other hidden files and folders! 
cd a-new-startup-ui-tests-github && zip -r --exclude=*.git/* ../a-new-startup-ui-tests.zip ./* .[^.]* && cd ..

# This is a zip of the testing code (python/selenim) used to test the UI.
aws s3 cp a-new-startup-ui-tests.zip s3://$BUCKET

echo "Setting up CodeCommit repos and ECR repos..."
aws cloudformation deploy --template-file repo.yaml --stack-name $PREFIX-repo --parameter-overrides Prefix=$PREFIX Bucket=$BUCKET

echo "Waiting for stack update"

