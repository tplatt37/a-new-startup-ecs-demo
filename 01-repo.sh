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
# NOTE: We're using ssh.  I hope you have a key pair configured!

# Make sure we don't have this folder local
rm -rf a-new-startup-github 

echo "Attemping to retrieve latest a-new-startup app source code from git@github.com:tplatt37/a-new-startup.git using ssh..."
git clone git@github.com:tplatt37/a-new-startup.git a-new-startup-github
if [ $? -eq 128 ]; then
        echo "But... that failed, so we'll use a possibly out of date zip instead."
        cp a-new-startup-fallback.zip a-new-startup.zip
else
        # If it was successful, zip up what was cloned
        # NOTE: When we zip, we ignore .git folder, but include other hidden files and folders! 
        echo "Success! Let's zip it up!"
        cd a-new-startup-github && zip -r --exclude=*.git/* ../a-new-startup.zip ./* .[^.]* && cd ..
        # Save this for next time, in case we can't get the code live.
        # (This makes the maintainer's life easier)
        cp a-new-startup.zip a-new-startup-fallback.zip 
fi

echo "Copying application source zip to S3 bucket"
aws s3 cp a-new-startup.zip s3://$BUCKET

# Do the same, but for the ui testing code.

# Make sure we don't have this folder local
rm -rf a-new-startup-ui-tests-github 

echo "Attemping to retrieve ui testing code from git@github.com:tplatt37/a-new-startup-ui-tests.git using ssh..."
git clone git@github.com:tplatt37/a-new-startup-ui-tests.git a-new-startup-ui-tests-github
if [ $? -eq 128 ]; then
        echo "But... that failed, so we'll use a possibly out of date zip instead."
        cp a-new-startup-ui-tests-fallback.zip a-new-startup-ui-tests.zip
else
        # NOTE: When we zip, we ignore .git folder, but include other hidden files and folders! 
        echo "Success! ZIPPING UP!"
        cd a-new-startup-ui-tests-github && zip -r --exclude=*.git/* ../a-new-startup-ui-tests.zip ./* .[^.]* && cd ..
        cp a-new-startup-ui-tests.zip a-new-startup-ui-tests-fallback.zip
fi

# This is a zip of the testing code (python/selenim) used to test the UI.
aws s3 cp a-new-startup-ui-tests.zip s3://$BUCKET

echo "Setting up CodeCommit repos and ECR repos..."
aws cloudformation deploy --template-file repo.yaml --stack-name $PREFIX-repo --parameter-overrides Prefix=$PREFIX Bucket=$BUCKET

echo "Waiting for stack update"

