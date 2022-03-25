#!/bin/bash
#
# This will run each CloudFormation template in order
# You must pass in:
#  A comma delimited list of 2 Public subnets, to use for the ALB. They need to be in the same VPC, of course!
#
# Example:
# ./00-install.sh  subnet-01394a2a0668b9de3,subnet-0696d8146ac458a3d
#
#

# Check AWS CLI version - must be v2.
AWS_CLI_VERSION=$(aws --version | grep -Po '(?<=aws-cli/)\d')
if [[ $AWS_CLI_VERSION -lt 2 ]]; then
    echo "You must install AWS CLI v2 to use this script."
    exit 1
fi

PREFIX="a-new-startup-ecs"

# Must pass in an s3 bucket (private) where the source code zip can be stored...
if [ -z $1 ]; then
        echo "Need the S3 Bucket Name as a parameter. Exiting..."
        exit 0
fi
BUCKET=$1

if [ -z $2 ]; then
        echo "Need a comma delimited list of two PUBLIC subnet Ids (for ALB). Exiting..."
        exit 0
fi
SUBNETS_COMMADELIMITED=$2

REGION=${AWS_DEFAULT_REGION:-$(aws configure get default.region)}

echo "Creating in $REGION..."

echo "Validating VPC and Subnets..."
SUBNETS=$(echo $SUBNETS_COMMADELIMITED | sed 's/,/ /g')
echo "Subnets=$SUBNETS"

aws ec2 describe-subnets --subnet-ids $SUBNETS 1>/dev/null
if [[ $? -ne 0 ]]; then
        echo "Subnets $SUBNETS don't exist ($REGION) - please double check.  Exiting..."
        exit 1
fi

./01-repo.sh $BUCKET
STACK_NAME=$PREFIX-repo
aws cloudformation wait stack-exists --stack-name $STACK_NAME
STACK_STATUS=$(aws cloudformation describe-stacks --stack-name $STACK_NAME --query "Stacks[].StackStatus" --output text)
if [[ $STACK_STATUS != "CREATE_COMPLETE" ]] && [[ $STACK_STATUS != "UPDATE_COMPLETE" ]]; then
        echo "Create or Update of Stack $STACK_NAME failed: $STACK_STATUS.  Cannot continue..."
        exit 1
fi

./02-cluster.sh $SUBNETS_COMMADELIMITED
STACK_NAME=$PREFIX-cluster
aws cloudformation wait stack-exists --stack-name $STACK_NAME
STACK_STATUS=$(aws cloudformation describe-stacks --stack-name $STACK_NAME --query "Stacks[].StackStatus" --output text)
if [[ $STACK_STATUS != "CREATE_COMPLETE" ]] && [[ $STACK_STATUS != "UPDATE_COMPLETE" ]]; then
        echo "Create or Update of Stack $STACK_NAME failed: $STACK_STATUS.  Cannot continue..."
        exit 1
fi

echo "Creating Build Projects..."
./03-build-projects.sh
STACK_NAME=$PREFIX-build-projects
aws cloudformation wait stack-exists --stack-name $STACK_NAME
STACK_STATUS=$(aws cloudformation describe-stacks --stack-name $STACK_NAME --query "Stacks[].StackStatus" --output text)
if [[ $STACK_STATUS != "CREATE_COMPLETE" ]] && [[ $STACK_STATUS != "UPDATE_COMPLETE" ]]; then
        echo "Create or Update of Stack $STACK_NAME failed: $STACK_STATUS.  Cannot continue..."
        exit 1
fi

# The Service will be created the first time the Pipeline runs.
echo "Creating Pipeline for Service ..."
./04-pipeline.sh
STACK_NAME=$PREFIX-pipeline
aws cloudformation wait stack-exists --stack-name $STACK_NAME
STACK_STATUS=$(aws cloudformation describe-stacks --stack-name $STACK_NAME --query "Stacks[].StackStatus" --output text)
if [[ $STACK_STATUS != "CREATE_COMPLETE" ]] && [[ $STACK_STATUS != "UPDATE_COMPLETE" ]]; then
        echo "Create or Update of Stack $STACK_NAME failed: $STACK_STATUS.  Cannot continue..."
        exit 1
fi

echo "Done..."

DNSNAME=$(aws cloudformation describe-stacks --stack-name $PREFIX-cluster --query "Stacks[0].Outputs[?OutputKey=='LoadBalancerDNSName'].OutputValue" --output text )
echo "Open this URL in your browser to see the app. NOTE: It won't work until the first run of the Pipeline finishes..."
echo " "
echo "http://$DNSNAME"
echo " "

echo "NOTE: If you want to use the Blue-Green demo, please wait a few minutes before running the 05-blue-green.sh script. The Container Image is probably still being built..."
