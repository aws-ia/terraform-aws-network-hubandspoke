#!/bin/sh

REGIONS="eu-central-1
eu-central-2
eu-north-1
eu-south-1
eu-south-2
eu-west-1
eu-west-2
eu-west-3
us-east-1
us-east-2
us-west-1
us-west-2"

AWS_DEFAULT_REGION=$(echo "$REGIONS" | shuf -n 1)
export AWS_DEFAULT_REGION
TIMEOUT="40m"

go test -v -count 1 -timeout "$TIMEOUT" | tee Test.log

