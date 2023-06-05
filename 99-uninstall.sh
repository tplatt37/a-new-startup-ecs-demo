#!/bin/bash

#
# This uninstalls (DELETES!) everything.
# No snapshots, nothing is retained.
#

PREFIX=a-new-startup-ecs

REGION=${AWS_DEFAULT_REGION:-$(aws configure get default.region)}

# NOTE: if you invoke with --yes it will skip these "Are you sure?" prompts
if [[ -z $1 || $1 != "--yes" ]]; then
    read -p "This will delete all the a-new-startup-ecs-* stacks in $REGION. Are you sure? (Yy) " -n 1 -r
    echo    # (optional) move to a new line
    if [[ ! $REPLY =~ ^[Yy]$ ]]
    then
        exit 1
    fi
    
    read -p "Are you sure you are sure???? (Yy) " -n 1 -r
    echo    # (optional) move to a new line
    if [[ ! $REPLY =~ ^[Yy]$ ]]
    then
        exit 1
    fi
fi

echo "OK... here we go..."

# Get the artifacts bucket from the Pipeline stack
ARTIFACT_BUCKET_STORE=$(aws cloudformation describe-stacks --stack-name $PREFIX-build-projects --query "Stacks[0].Outputs[?OutputKey=='ArtifactStoreBucket'].OutputValue" --output text )

# Empty the artifacts bucket (Otherwise stack delete will fail)
echo "Will empty bucket $ARTIFACT_BUCKET_STORE - to prevent stack delete from failing..."
aws s3 rm s3://$ARTIFACT_BUCKET_STORE --recursive

# Manually --force delete the ecr repos.  They'll fail to delete otherwise.
ECRREPONAME=$(aws cloudformation list-exports --query "Exports[?Name=='$PREFIX-AppImage'].Value" --output text)
aws ecr delete-repository --repository-name $ECRREPONAME --force

# Delete the services first, otherwise you may find a role missing...
STACK_NAME=$PREFIX-bluegreen
echo "Deleting ($STACK_NAME) ..."
aws cloudformation delete-stack --stack-name $STACK_NAME
aws cloudformation wait stack-delete-complete --stack-name $STACK_NAME 

STACK_NAME=$PREFIX-service
echo "Deleting ($STACK_NAME) ..."
aws cloudformation delete-stack --stack-name $STACK_NAME
aws cloudformation wait stack-delete-complete --stack-name $STACK_NAME 

STACK_NAME=$PREFIX-backend
echo "Deleting ($STACK_NAME) ..."
aws cloudformation delete-stack --stack-name $STACK_NAME
aws cloudformation wait stack-delete-complete --stack-name $STACK_NAME 

STACK_NAME=$PREFIX-pipeline
echo "Deleting ($STACK_NAME) ..."
aws cloudformation delete-stack --stack-name $STACK_NAME
aws cloudformation wait stack-delete-complete --stack-name $STACK_NAME 

STACK_NAME=$PREFIX-build-projects
echo "Deleting ($STACK_NAME) ..."
aws cloudformation delete-stack --stack-name $STACK_NAME
aws cloudformation wait stack-delete-complete --stack-name $STACK_NAME 

STACK_NAME=$PREFIX-cluster
echo "Deleting ($STACK_NAME) ..."
aws cloudformation delete-stack --stack-name $STACK_NAME
aws cloudformation wait stack-delete-complete --stack-name $STACK_NAME 

# Get the logging bucket from the Repo stack
LOGGING_BUCKET=$(aws cloudformation describe-stacks --stack-name $PREFIX-repo --query "Stacks[0].Outputs[?OutputKey=='LoggingBucket'].OutputValue" --output text )
echo "LOGGING_BUCKET=$LOGGING_BUCKET."

# Empty the artifacts bucket (Otherwise stack delete will fail)
# NOTE: You need to do this AFTER THE ALB Is gone.  Otherwise there may be files created dynamically that prevent the cleanup
echo "Will empty bucket $LOGGING_BUCKET - to prevent stack delete from failing..."
aws s3 rm s3://$LOGGING_BUCKET --recursive

STACK_NAME=$PREFIX-repo
echo "Deleting ($STACK_NAME) ..."
aws cloudformation delete-stack --stack-name $STACK_NAME
aws cloudformation wait stack-delete-complete --stack-name $STACK_NAME 

echo "Done."
