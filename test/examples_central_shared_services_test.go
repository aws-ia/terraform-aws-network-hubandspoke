package test

import (
	"testing"

	"github.com/gruntwork-io/terratest/modules/logger"
	"github.com/gruntwork-io/terratest/modules/terraform"
)

func TestExamplesCentralSharedServices(t *testing.T) {
	logger.Logf(t, "Starting test - Central Shared Services")

	terraformOptions := &terraform.Options{
		TerraformDir: "../examples/central_shared_services",
	}

	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)
}