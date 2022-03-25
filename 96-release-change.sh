#!/bin/bash

# This is a helper script. Run this to "Release Change" to the pipeline, and this script will wait until the pipeline is complete
# This is used in a CI/CD pipeline that is used to test this CI/CD pipeline!


# Must pass in an pipeline name
if [ -z $1 ]; then
        echo "Need Codepipeline Pipeline Name. Exiting..."
        exit 0
fi
PIPELINE_NAME=$1

if [ -z $2 ]; then
        echo "Need to know how many minutes to wait for the pipeline to finish. Exiting..."
        exit 0
fi
# Multiply minutes by 4, because we poll for succcess every 15 seconds.
MAX=$((4*$2))


echo "Releasing latest change in pipeline...Waiting up to $2 minutes for Success..."
EXECUTION_ID=$(aws codepipeline start-pipeline-execution --name $PIPELINE_NAME --query="pipelineExecutionId" --output text)
echo "EXECUTION_ID=$EXECUTION_ID."

# Wait for the execution to complete.
# There's no wait/waiter command so have to do this loop instead.
ATTEMPTS=0

SUCCESS_COUNT=0
SLEEP_SECONDS=15
while [[ $SUCCESS_COUNT -eq 0 && $ATTEMPTS -lt $MAX ]]; do
    sleep $SLEEP_SECONDS
    # Look for Execution Status to be become "Succeeded"
    SUCCESS_COUNT=$(aws codepipeline get-pipeline-execution --pipeline-execution-id $EXECUTION_ID --pipeline-name $PIPELINE_NAME --query "pipelineExecution.status" --output text | grep Succeeded | wc -l)
    ((ATTEMPTS=ATTEMPTS+1))
    echo "Waiting $SLEEP_SECONDS seconds for pipeline execution status to == Succeeded... ($ATTEMPTS attempts of $MAX)..."
done

# If we maxed out, fail the build project (non zero exit)
if [[ $ATTEMPTS -eq $MAX ]]; then
    echo "Max attempts exceeded."
    exit 5  
else    
    echo "Pipeline execution succeeded."
    exit 0
fi