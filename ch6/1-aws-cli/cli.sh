#!/usr/bin/env bash

set -euo pipefail

command -v aws >/dev/null 2>&1 ||
    { echo >&2 "ERR: aws cli is missing, aborting!"; exit 1; }

command -v jq >/dev/null 2>&1 ||
    { echo >&2 "ERR: jq is missing, aborting!"; exit 1; }

REGION='eu-west-1'
REGION_AZ='eu-west-1a'
CIDR_BLOCK='10.0.0.0/16'
CIDR_BLOCK_SUBNET='10.0.1.0/24'

aws configure set region $REGION

# Creates the AWS VPC
VPCID=$(aws ec2 create-vpc --cidr-block ${CIDR_BLOCK} | jq .Vpc.VpcId -r)
aws ec2 create-tags --resources $VPCID --tags Key=Name,Value=Chapter-6-bash
echo "Created VPC $VPCID"

# Creates an internet gateway and attaches it to the VPC
IGW=$(aws ec2 create-internet-gateway | jq -r '.InternetGateway.InternetGatewayId')
aws ec2 attach-internet-gateway --internet-gateway-id $IGW --vpc-id $VPCID
echo "Created internet gateway $IGW"

# Creates route table and configure routing
RT=$(aws ec2 describe-route-tables --query 'RouteTables[].RouteTableId' \
    --filters Name=vpc-id,Values=$VPCID \
    --output text)
aws ec2 create-route --route-table-id $RT --gateway-id $IGW \
    --destination-cidr-block '0.0.0.0/0'
echo "Created route table $RT"

# Creates subnet
SUBNET=$(aws ec2 create-subnet --vpc-id $VPCID \
    --cidr-block $CIDR_BLOCK \
    --availability-zone $REGION_AZ | jq -r '.Subnet.SubnetId')
echo "Created subnet $SUBNET"

# Allows instances launched in the VPC to get public IP addresses
aws ec2 modify-subnet-attribute --map-public-ip-on-launch \
    --subnet-id $SUBNET
aws ec2 associate-route-table --route-table-id $RT \
    --subnet-id $SUBNET
echo "Associated route table $RT with subnet $SUBNET"

# # get latest amazon linux image
AMI=$(aws ec2 describe-images --owners amazon \
    --filters "Name=name,Values=amzn2-ami-hvm-2.0*" \
    --query 'sort_by(Images, &CreationDate)[-1].ImageId' \
    --output text)
echo "Using Amazon Linux latest AMI $AMI"

# launch smallest ec2 instance
INSTANCE=$(aws ec2 run-instances --image-id $AMI \
    --instance-type t3.nano \
    --subnet-id $SUBNET \
    --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=Chapter-6-bash}]' \
    --user-data file://user-data.sh \
    --query 'Instances[].InstanceId' \
    --output text)
echo "Launched instance $INSTANCE"

# get instance public ip
PUBLIC_IP=$(aws ec2 describe-instances --instance-ids $INSTANCE \
    --query 'Reservations[].Instances[].PublicIpAddress' \
    --output text)

#get instance security group
SG=$(aws ec2 describe-instances --instance-ids $INSTANCE \
    --query 'Reservations[].Instances[].SecurityGroups[].GroupId' \
    --output text)

# open http port in security group
aws ec2 authorize-security-group-ingress --group-id $SG \
    --protocol tcp --port 80 --cidr 0.0.0.0/0

echo "Open http://$PUBLIC_IP in your browser!"