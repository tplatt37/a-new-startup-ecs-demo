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

if [ -z $2 ]; then
        echo "Need a comma delimited list of two PRIVATE subnet Ids (for Fargate). Exiting..."
        exit 0
fi

source 01-cluster.sh $1 $2
aws cloudformation wait stack-create-complete --stack-name "a-new-startup-ecs-cluster"

echo "Creating Build Projects..."
source 02-build-projects.sh
aws cloudformation wait stack-create-complete --stack-name "a-new-startup-ecs-build-projects"

# The Service will be created the first time the Pipeline runs.
echo "Creating Pipeline for Service A ..."
source 03-pipeline-a.sh
aws cloudformation wait stack-create-complete --stack-name "a-new-startup-ecs-pipeline-a"

echo "Done..."

DNSNAME=$(aws cloudformation describe-stacks --stack-name a-new-startup-ecs-cluster --query "Stacks[0].Outputs[?OutputKey=='LoadBalancerDNSName'].OutputValue" --output text )
echo "Open this URL in your browser to see the app. NOTE: It won't work until the first run of the Pipeline finishes..."
echo " "
echo "http://$DNSNAME"
echo " "
