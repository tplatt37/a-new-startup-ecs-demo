#!/bin/bash

if [ -z $1 ]; then
        echo "Need a comma delimited list of two PUBLIC subnet Ids. Exiting..."
        exit 0
fi

# Optional - IP address to allowlist for access to the app.  if not provided, we use current IP
if [ ! -z $2 ]; then
        MY_IP=$2
else
        MY_IP=$(curl -s checkip.amazonaws.com)
fi
echo "MY_IP=$MY_IP"


# Sometimes we need a comma delimited list of subnets, other times, space delimited. 
# use $1 for the comma delimited, and SUBNETS for the space delimited.
# Subnets are needed for the ALB.
SUBNETS=$(echo $1 | sed 's/,/ /g')
echo "Public Subnets=$SUBNETS"

# Grab the VpcId off the first subnet. This is needed for the Security Group and Target Group.
VPC_ID=$(aws ec2 describe-subnets --subnet-ids $SUBNETS --query 'Subnets[0].VpcId' --output text)
echo "VpcId=$VPC_ID"


aws cloudformation deploy --template-file cluster.yaml --stack-name "a-new-startup-ecs-cluster" --parameter-overrides VpcId=$VPC_ID IpRangeForAccess=$MY_IP PublicSubnets=$1 --capabilities CAPABILITY_NAMED_IAM