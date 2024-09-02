#!/usr/bin/env bash

command -v aws >/dev/null 2>&1 ||
    { echo >&2 "ERR: aws cli is missing, aborting!"; exit 1; }

command -v jq >/dev/null 2>&1 ||
    { echo >&2 "ERR: jq is missing, aborting!"; exit 1; }

REGION='eu-west-1'
aws configure set region $REGION

# Get the VPC ID
VPCID=$(aws ec2 describe-vpcs --filters "Name=tag:Name,Values=Chapter-6-bash" --query 'Vpcs[].VpcId' --output text)

# Get the Instance ID
INSTANCE=$(aws ec2 describe-instances --filters "Name=vpc-id,Values=$VPCID" "Name=instance-state-name,Values=running" --query 'Reservations[].Instances[].InstanceId' --output text)

# Get instance security group
SG=$(aws ec2 describe-instances --instance-ids $INSTANCE --query 'Reservations[].Instances[].SecurityGroups[].GroupId' --output text)

# Terminate the Instance
echo "Terminating instance $INSTANCE"
aws ec2 terminate-instances --instance-ids $INSTANCE ||
    { echo >&2 "error: instance already terminated"; }

# Wait for the Instance to terminate
echo "Waiting for the instance to terminate..."
sleep 120

# Get the Subnet ID
SUBNET=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPCID" --query 'Subnets[].SubnetId' --output text)

# Delete the Subnet
echo "Deleting subnet $SUBNET"
aws ec2 delete-subnet --subnet-id $SUBNET ||
    { echo >&2 "error: subnet deletion failed"; }


# Get the Internet Gateway ID
IGW=$(aws ec2 describe-internet-gateways --filters "Name=attachment.vpc-id,Values=$VPCID" --query 'InternetGateways[].InternetGatewayId' --output text)

# Detach and delete the Internet Gateway
echo "Deleting internet gateway $IGW"
aws ec2 detach-internet-gateway --internet-gateway-id $IGW --vpc-id $VPCID
aws ec2 delete-internet-gateway --internet-gateway-id $IGW ||
    { echo >&2 "error: igw deletion failed"; }
sleep 10

# Delete the VPC
echo "Deleting VPC"
aws ec2 delete-vpc --vpc-id $VPCID ||
    { echo >&2 "error: vpc deletion failed"; }
