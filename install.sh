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

if [ -z $1 ]; then
        echo "Need a comma delimited list of two PUBLIC subnet Ids (for ALB). Exiting..."
        exit 0
fi
SUBNETS_COMMADELIMITED=$1

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

./01-cluster.sh $SUBNETS_COMMADELIMITED
aws cloudformation wait stack-create-complete --stack-name "a-new-startup-ecs-cluster"

echo "Creating Build Projects..."
./02-build-projects.sh
aws cloudformation wait stack-create-complete --stack-name "a-new-startup-ecs-build-projects"

# The Service will be created the first time the Pipeline runs.
echo "Creating Pipeline for Service ..."
./03-pipeline.sh
aws cloudformation wait stack-create-complete --stack-name "a-new-startup-ecs-pipeline"

echo "Done..."

DNSNAME=$(aws cloudformation describe-stacks --stack-name a-new-startup-ecs-cluster --query "Stacks[0].Outputs[?OutputKey=='LoadBalancerDNSName'].OutputValue" --output text )
echo "Open this URL in your browser to see the app. NOTE: It won't work until the first run of the Pipeline finishes..."
echo " "
echo "http://$DNSNAME"
echo " "

echo "NOTE: If you want to use the Blue-Green demo, please wait a few minutes before running the 04-blue-green.sh script. The Container Image is probably still be built..."
