#!/bin/bash

#
# NOTE: The ImageURI is bogus here. This Stack isn't going to work unless the ImageURI is valid.  
# ECS Will just keep trying to deploy the bogus container over and over and over and over.
#
aws cloudformation deploy --template-file service-a.yaml --parameter-overrides ImageURI=123456789012.dkr.ecr.us-east-1.amazonaws.com/a-new-startup-eks:123456 --stack-name "a-new-startup-ecs-service-a" 