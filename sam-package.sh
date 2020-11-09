#!/bin/sh

if [ $# -lt 3 ]; then
  echo "Error! Missing input arguments!!"
  echo "Usage: ./sam-package.sh SAM_TEMPLATE_INPUT_FILE SAM_TEMPLATE_OUTPUT_FILE EXISTING_S3_BUCKET"
  echo "ex: ./sam-package.sh template.yaml sam-template-output.yaml aws-sam-cli-managed-default-samclisourcebucket-xyz "
  exit -1
fi

SAM_TEMPLATE_INPUT_FILE=$1
SAM_TEMPLATE_OUTPUT_FILE=$2
S3_BUCKET=$3


sam package \
  --s3-bucket ${S3_BUCKET} \
  --template-file  ${SAM_TEMPLATE_INPUT_FILE}  \
  --output-template-file ${SAM_TEMPLATE_OUTPUT_FILE}
