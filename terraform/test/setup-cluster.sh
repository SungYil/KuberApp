#!/bin/bash

VAR_FILE=${1:-clever2-vsup.tfvars}

test -d .terraform && rm -rf .terraform* terraform.*

terraform init -var-file $VAR_FILE

terraform plan -var-file $VAR_FILE

terraform apply -var-file $VAR_FILE