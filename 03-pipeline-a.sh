#!/bin/bash

echo "Creating simple CodePipeline pipeline (Source/Build/Deploy) ..."
aws cloudformation deploy --template-file pipeline-a.yaml --stack-name a-new-startup-ecs-pipeline-a --capabilities CAPABILITY_NAMED_IAM


