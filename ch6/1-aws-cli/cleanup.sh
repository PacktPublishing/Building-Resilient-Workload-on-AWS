#!/usr/bin/env bash

set -euo pipefail

command -v aws >/dev/null 2>&1 ||
    { echo >&2 "ERR: aws cli is missing, aborting!"; exit 1; }

command -v jq >/dev/null 2>&1 ||
    { echo >&2 "ERR: jq is missing, aborting!"; exit 1; }


REGION='eu-west-1'
aws configure set region $REGION

# Get the VPC ID
VPCID=$(aws ec2 describe-vpcs --filters "Name=tag:Name,Values=Chapter-6" --query 'Vpcs[].VpcId' --output text)

# Get the Internet Gateway ID
IGW=$(aws ec2 describe-internet-gateways --filters "Name=attachment.vpc-id,Values=$VPCID" --query 'InternetGateways[].InternetGatewayId' --output text)

# Detach and delete the Internet Gateway
aws ec2 detach-internet-gateway --internet-gateway-id $IGW --vpc-id $VPCID
aws ec2 delete-internet-gateway --internet-gateway-id $IGW

# Get the Subnet ID
SUBNET=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPCID" --query 'Subnets[].SubnetId' --output text)

# Get the Instance ID
INSTANCE=$(aws ec2 describe-instances --filters "Name=vpc-id,Values=$VPCID" "Name=instance-state-name,Values=running" --query 'Reservations[].Instances[].InstanceId' --output text)

# Terminate the Instance
aws ec2 terminate-instances --instance-ids $INSTANCE

# Wait for the Instance to terminate
while aws ec2 describe-instances --instance-ids $INSTANCE --query 'Reservations[].Instances[].State.Name' --output text | grep -q 'running'; do
    echo "Waiting for instance $INSTANCE to terminate..."
    sleep 5
done

# Delete the Subnet
aws ec2 delete-subnet --subnet-id $SUBNET

# Delete the Route Table
RT=$(aws ec2 describe-route-tables --filters "Name=vpc-id,Values=$VPCID" --query 'RouteTables[].RouteTableId' --output text)
aws ec2 delete-route-table --route-table-id $RT

# Delete the VPC
aws ec2 delete-vpc --vpc-id $VPCID