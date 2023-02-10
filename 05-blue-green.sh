#!/bin/bash

# NOTE: This is more of a manual demo.  When you run this, it creates a NEW Service that will use a CodeDeploy Blue/Green update.
#
# To demo it, run this and show the newly created ECS Service. (The first deploy is NOT blue/green)
# Then make a change to the a-new-startup repo - let it flow through the regular pipeline (and therefore new container image in ECR)
# Then re-run this script again, and it will do a Blue/Green to update this particular service.
#
# Note that if anything goes awry, you'll have to "Stack Actions" -> Cancel update stack, which will do a Rollback to the prior version.
#


# We can't use ImportValue in this CF template.
# Per this: https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/blue-green.html#
# We have to retrieve all values here and pass them in via Parameters
#

PREFIX="a-new-startup-ecs"

VPCID=$(aws cloudformation list-exports --query "Exports[?Name=='$PREFIX-VpcId'].Value" --output text)
echo "VPCID=$VPCID."

PUBLICSUBNETS=$(aws cloudformation list-exports --query "Exports[?Name=='$PREFIX-PublicSubnets'].Value" --output text)
echo "PUBLICSUBNETS=$PUBLICSUBNETS."

TASKROLEARN=$(aws cloudformation list-exports --query "Exports[?Name=='$PREFIX-TaskRoleArn'].Value" --output text)
echo "TASKROLEARN=$TASKROLEARN."

ECRREPONAME=$(aws cloudformation list-exports --query "Exports[?Name=='$PREFIX-AppImage'].Value" --output text)

# Get the latest image tag - a specific imagetag, not latest. This sorts by imagePushedAt
# We combine a server side --filter with jq to get what we want
# We want to skip UNTAGGED builds and latest.
# NOTE: we use --raw-output on the jq part ot get the value without quotes
TAG=$(aws ecr describe-images --repository-name $ECRREPONAME --filter '{"tagStatus": "TAGGED"}' | jq '.imageDetails|=sort_by(.imagePushedAt)|.imageDetails[].imageTags[]' --raw-output | grep -v latest | tail -1)
echo "TAG=$TAG"

# Get the leftmost 7 chars only
TAGPARSED=${TAG:0:7}

# Need to get the URI separately
URI=$(aws ecr describe-repositories --repository-names=$ECRREPONAME --query "repositories[0].repositoryUri" --output text)
IMAGEURI=$URI:$TAGPARSED

echo "IMAGEURI=$IMAGEURI."

# Need to get the TableName and TopicArn

TABLENAME=$(aws cloudformation list-exports --query "Exports[?Name=='$PREFIX-TableName'].Value" --output text)
echo "TABLENAME=$TABLENAME."

TOPICARN=$(aws cloudformation list-exports --query "Exports[?Name=='$PREFIX-TopicArn'].Value" --output text)
echo "TOPICARN=$TOPICARN."

echo "Creating Service ..."
aws cloudformation deploy \
    --template-file blue-green.yaml \
    --stack-name $PREFIX-bluegreen \
    --capabilities CAPABILITY_IAM \
    --parameter-overrides \
    Cluster=ecs-demo \
    PublicSubnets=$PUBLICSUBNETS \
    ImageUri=$IMAGEURI \
    TaskRoleArn=$TASKROLEARN \
    VpcId=$VPCID \
    TableName=$TABLENAME \
    TopicArn=$TOPICARN
