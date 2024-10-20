#!/usr/bin/env bash

set -euo pipefail

usage(){
    echo "usage: ${0##*/} AWS_REGION"
    return 1
}

[ $# -ne 1 ] && usage

command -v packer >/dev/null 2>&1 ||
    { echo >&2 "error: packer is missing, aborting!"; exit 1; }

echo "Initializing Packer..."
packer plugins install github.com/hashicorp/amazon
packer build -var "aws_region=$1" app.json
