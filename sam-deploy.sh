#!/bin/sh

if [ $# -lt 2 ]; then
  echo "Error! Missing input arguments!!"
  echo "Usage: ./sam-deploy.sh STACK_NAME SAM_TEMPLATE_OUTPUT_FILE"
  echo "ex: ./sam-deploy.sh test-concurrency sam-template-output.yaml"
  exit -1
fi

STACK_NAME=$1
SAM_TEMPLATE_OUTPUT_FILE=$2
sam deploy \
  --stack-name ${STACK_NAME} \
  --template-file ${SAM_TEMPLATE_OUTPUT_FILE} \
  --capabilities CAPABILITY_NAMED_IAM
