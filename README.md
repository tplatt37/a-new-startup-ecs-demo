# Overview

After we've built A-New-Startup and got it running on EC2 - can we run it containerized as an ECS Service? 

Yep.

This set of CloudFormation templates will create an ECS Cluster, running a Service for A-New-Startup.
There's also a CI/CD Pipeline that builds a container image of the app, and stores it in ECR. 
That container image is then used by CloudFormation to update the running service.

NOTE: This set of templates will create resources that cost money - including some with billing per hour (Fargate, Application Load Balancer, etc.)

# Requirements

You need to supply a VPC with 2 Public Subnets (for ALB)

This set of templates uses many static/fixed resource names (stack names, repo name, iam stuff, and much more) for simplicity's sake. 
This means you can only install it ONCE per account (stack will fail with naming conflicts otherwiwse).
If you need multiple installs, use different accounts!

This repo is meant for demos to students - so we keep it as simple (as possible).

# Architecture

After running the installation script, the architecture will be:

![Diagram - ECS cluster for a-new-startup](/diagrams/aws-a-new-startup-ecs-demo-cluster.png)

The CI/CD Pipeline will be implemented as shown:

![Diagram - ECS a-new-startup pipeline](/diagrams/aws-a-new-startup-ecs-demo-pipeline.png)

Please note that the CodeCommit repo (a-new-startup) was previously created.

# Installation

I recommend setting your AWS_DEFAULT_REGION first:
```
export AWS_DEFAULT_REGION=us-east-1
```
Run the following command, and pass a bucket name for temporary code, and a comma delimited list of the 2 PUBLIC subnets.
```
./install.sh "BUCKET_NAME" "subnet-1234568999,subnet-8298392925" 
```
Alternatively, you can run the individual files (This is helpful after the initial install if you are making updates and only want one stack to be updated.)

01-repo.sh, 02-cluster.sh, 03-build-projects.sh, etc.

# What's Next?

The pipeline will kick off automatically after you install it.  Navigate to CodePipeline to see it in action.  

After it is deployed, pull up the ALB DNSName in your browser to see the app. (The DNSName is an output of a-new-startup-ecs-cluster stack - for convenience)

To run it again, you have the option of using "Release Change" in CodePipeline, or cloning the application source, and making changes.

To update the app (and trigger the CI/CD pipeline again) do the following:

Find the Clone URL (NOTE: Using ssh here) and clone easily with:
```
REPO=$(aws cloudformation list-exports --query "Exports[?Name=='a-new-startup-ecs-AppRepo'].Value" --output text)
git clone $(aws codecommit get-repository --repository-name $REPO --query "repositoryMetadata.cloneUrlSsh" --output text)         
```

Modify some of the visible text in src/views/index.ejs (for an easy and visible change)

```
git commit -a -m "updated version number"

git push
```
The pipeline should then kick off with the latest commit.

# Then what? 

Using the 05-blue-green.sh script you can demonstrate a Blue/Green deployment orchestrated by CodeDeploy.

```
./05-blue-green.sh
```

(This demo is a bit more manual, but basically run it once to create the service, push some changes to a-new-startup, then run this script again.  The 2nd deploy will be a Blue/Green deployment.)

See the notes within 05-blue-green.sh

# Uninstall

To uninstall (WARNING - This deletes EVERYTHING created above - no snapshots, no retain)
```
./99-uninstall.sh 
```
Investigate that file to find out what it does. 

# A Warning

This code should NOT be considered production ready.  
While some best practices have been incorporated, the primary goal was to keep things SIMPLE so that students can absorb what they are being shown - without tons of extraneous error checking and complicated dynamic names.



