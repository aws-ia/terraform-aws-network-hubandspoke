package test

import (
	"os"
	"testing"

	"github.com/gruntwork-io/terratest/modules/logger"
	"github.com/gruntwork-io/terratest/modules/terraform"
)

func TestExamplesCentralInspectionEgress(t *testing.T) {
	_region := "eu-west-1"

	if os.Getenv(ENV_REGION) != "" {
		_region = os.Getenv(ENV_REGION)
	}
	logger.Logf(t, "Using region %v. To override set environment variable %v", _region, ENV_REGION)

	terraformOptions := &terraform.Options{
		TerraformDir: "../examples/central_shared_services",
	}

	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)
}