#!/bin/sh

AWS_DEFAULT_REGION="eu-central-1"
export AWS_DEFAULT_REGION
TIMEOUT="60m"

go test -v -count 1 -timeout "$TIMEOUT" | tee Test.log

