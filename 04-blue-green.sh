#!/bin/bash

# We can't use ImportValue in this CF template.
# We have to retrieve all values here and pass them in via Parameters

VPCID=$(aws cloudformation list-exports --query "Exports[?Name=='ecs-demo-VpcId'].Value" --output text)
echo "VPCID=$VPCID."

PUBLICSUBNETS=$(aws cloudformation list-exports --query "Exports[?Name=='ecs-demo-PublicSubnets'].Value" --output text)
echo "PUBLICSUBNETS=$PUBLICSUBNETS."

PRIVATESUBNETS=$(aws cloudformation list-exports --query "Exports[?Name=='ecs-demo-PrivateSubnets'].Value" --output text)
echo "PRIVATESUBNETS=$PRIVATESUBNETS."

# Get IMAGEURI from ECR.  Use latest, but use a specific tag, not "latest"
TAG=$(aws ecr describe-images --repository-name "a-new-startup" --image-ids imageTag=latest --query "imageDetails[0].imageTags" --output text | sed 's/latest//g' ) 
# Get the leftmost 6 chars only
IMAGEURI=${TAG:0:6} 
echo "IMAGEURI=$IMAGEURI."

echo "Creating Blue/Green deployment ..."
aws cloudformation deploy \
    --template-file blue-green.yaml \
    --stack-name a-new-startup-ecs-green-blue \
    --capabilities CAPABILITY_IAM \
    --parameter-overrides \
    Cluster=ecs-demo \
    PublicSubnets=$PUBLICSUBNETS \
    PrivateSubnets=$PRIVATESUBNETS \
    ImageUri=$IMAGEURI \
    VpcId=$VPCID \
    Vpc=$VPCID \
    Subnet1=subnet-03e7d5fef169bc0fc \
    Subnet2=subnet-07cbb5aef6aac40cd 
