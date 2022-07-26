#!/usr/bin/env bash

set -e

source .env

if [ -z $PROJECT_NAME ]; then
    echo "PROJECT_NAME environment variable is not set."
    exit 1
fi

if [ -z $AWS_ACCOUNT_ID ]; then
    echo "AWS_ACCOUNT_ID environment variable is not set."
    exit 1
fi

if [ -z $AWS_DEFAULT_REGION ]; then
    echo "AWS_DEFAULT_REGION environment variable is not set."
    exit 1
fi

if [ -z $KEY_PAIR ]; then
    echo "KEY_PAIR environment variable is not set. This must be the name of an SSH key pair, see https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-key-pairs.html"
    exit 1
fi

DOCKER_IMAGE_APP=${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com/${PROJECT_NAME}
TAG=latest

APP_IMAGE=$DOCKER_IMAGE_APP:$TAG
BUCKET_NAME=twitter-bucket

deploy_images() {
    echo "Deploying App images to ECR..."
    aws ecr get-login-password --region ${AWS_DEFAULT_REGION} | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com
    aws ecr describe-repositories --repository-name ${PROJECT_NAME} >/dev/null 2>&1 || aws ecr create-repository --repository-name ${PROJECT_NAME}
    bash scripts/build-push.sh
}

deploy_env(){
    echo "Deploying App enviroment to s3..."
    aws s3api create-bucket \
        --bucket $BUCKET_NAME \
        --region AWS_DEFAULT_REGION
    aws s3 cp .env s3:://$BUCKET_NAME/enviroment/.env
}

deploy_infra() {
    echo "Deploying Cloud Formation stack: \"VPC-$APP_ENV-$PROJECT_NAME\""
    aws cloudformation deploy \
        --no-fail-on-empty-changeset \
        --stack-name vpc-$APP_ENV-$PROJECT_NAME \
        --template-file "deploy/vpc-2azs.yml" \
        --capabilities CAPABILITY_IAM \
        --tags $PROJECT_NAME-$APP_ENV-cluster=vpc

    echo "Deploying Cloud Formation stack: \"SG-$APP_ENV-$PROJECT_NAME\""
    aws cloudformation deploy \
        --no-fail-on-empty-changeset \
        --template-file "deploy/client-sg.yml" \
        --stack-name client-$APP_ENV-$PROJECT_NAME \
        --capabilities CAPABILITY_NAMED_IAM \
        --parameter-overrides ParentVPCStack=vpc-$APP_ENV-$PROJECT_NAME \
        --tags $PROJECT_NAME-$APP_ENV-cluster=client

    echo "Deploying Cloud Formation stack: \"BastionHost-$APP_ENV-$PROJECT_NAME\""
    aws cloudformation deploy \
        --template-file "deploy/vpc-ssh-bastion.yml" \
        --stack-name ssh-bastion-$APP_ENV-$PROJECT_NAME \
        --capabilities CAPABILITY_NAMED_IAM \
        --parameter-overrides ParentVPCStack=vpc-$APP_ENV-$PROJECT_NAME \
        KeyPairName=$KEY_PAIR \
        EnableTCPForwarding=true \
        --tags $PROJECT_NAME-$APP_ENV--cluster=$APP_ENV-ssh-bastion

    echo "Deploying Cloud Formation stack: \"Cluster-$APP_ENV-$PROJECT_NAME\""
    aws cloudformation deploy \
        --no-fail-on-empty-changeset \
        --template-file "deploy/cluster-fargate.yml" \
        --stack-name cluster-fargate-$APP_ENV-$PROJECT_NAME \
        --capabilities CAPABILITY_NAMED_IAM \
        --parameter-overrides ParentVPCStack=vpc-$APP_ENV-$PROJECT_NAME \
        --tags $PROJECT_NAME-$APP_ENV-cluster=ecs-cluster
}

deploy_app() {
    echo "Deploying Cloud Formation stack: \"${PROJECT_NAME}-app\" containing ALB, ECS Tasks..."
    aws cloudformation deploy \
        --no-fail-on-empty-changeset \
        --template-file "deploy/task-definition/app-demo.yml" \
        --stack-name app-$APP_ENV-$PROJECT_NAME \
        --capabilities CAPABILITY_NAMED_IAM \
        --parameter-overrides ParentVPCStack=vpc-$APP_ENV-$PROJECT_NAME \
        AppEnvironment1Key=APP_ENV \
        ParentClusterStack=cluster-fargate-$APP_ENV-$PROJECT_NAME \
        ParentClientStack1=client-$APP_ENV-$PROJECT_NAME \
        AppEnvironment1Value=$APP_ENV \
        AppImage=$APP_IMAGE \
        AutoScaling=true \
        Cpu=0.25 \
        Memory=0.5 \
        DesiredCount=3 \
        MinCapacity=3 \
        AppEnvironmentS3Arn=arn:aws:s3:::$BUCKET_NAME/enviroment/.env
        --tags $PROJECT_NAME-$APP_ENV-cluster=service-$APP_IMAGE
}

print_bastion() {
    echo "Bastion endpoint:"
    ip=$(aws cloudformation describe-stacks \
        --stack-name=ssh-bastion-$APP_ENV-$PROJECT_NAME\  --query="Stacks[0].Outputs[?OutputKey=='EIP1'].OutputValue" \
        --output=text)
    echo "${ip}"
}

print_endpoint() {
    echo "Public endpoint:"
    prefix=$(aws cloudformation describe-stacks \
        --stack-name=cluster-fargate-$APP_ENV-$PROJECT_NAME \
        --query="Stacks[0].Outputs[?OutputKey=='URL'].OutputValue" \
        --output=text)
    echo "${prefix}"
}

deploy_stacks() {
    deploy_images
    deploy_env
    deploy_infra
    deploy_app

    print_bastion
    print_endpoint
}

delete_cfn_stack() {
    stack_name=$1
    echo "Deleting Cloud Formation stack: \"${stack_name}\"..."
    aws cloudformation delete-stack --stack-name $stack_name
    echo 'Waiting for the stack to be deleted, this may take a few minutes...'
    aws cloudformation wait stack-delete-complete --stack-name $stack_name
    echo 'Done'
}

delete_images() {
    echo "deleting repository \"${PROJECT_NAME}\"..."
    aws ecr delete-repository \
        --repository-name $PROJECT_NAME \
        --force
}

delete_stacks() {
    delete_cfn_stack app-$APP_ENV-$PROJECT_NAME

    delete_cfn_stack cluster-fargate-$APP_ENV-$PROJECT_NAME

    delete_cfn_stack ssh-bastion-$APP_ENV-$PROJECT_NAME

    delete_cfn_stack client-$APP_ENV-$PROJECT_NAME

    delete_cfn_stack app-$APP_ENV-$PROJECT_NAME

    delete_cfn_stack vpc-$APP_ENV-$PROJECT_NAME

    delete_images

    echo "all resources from this tutorial have been removed"
}

action=${1:-"deploy"}
if [ "$action" == "delete" ]; then
    delete_stacks
    exit 0
fi

deploy_stacks
