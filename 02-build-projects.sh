#!/bin/bash

echo "Creating simple CodePipeline pipeline (Source/Build/Deploy) ..."
aws cloudformation deploy --template-file build-projects.yaml --stack-name a-new-startup-ecs-build-projects --capabilities CAPABILITY_NAMED_IAM


