#!/bin/bash

echo "Creating simple CodePipeline pipeline (Source/Build/Deploy) ..."
aws cloudformation deploy --template-file pipeline.yaml --stack-name a-new-startup-ecs-pipeline --capabilities CAPABILITY_NAMED_IAM


