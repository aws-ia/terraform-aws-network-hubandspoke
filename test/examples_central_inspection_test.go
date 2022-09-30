package test

import (
	"testing"

	"github.com/gruntwork-io/terratest/modules/logger"
	"github.com/gruntwork-io/terratest/modules/terraform"
)

func TestExamplesCentralInspectionEgress(t *testing.T) {
	logger.Logf(t, "Starting test - Central Inspection (with egress)")

	terraformOptions := &terraform.Options{
		TerraformDir: "../examples/central_inspection",
	}

	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)
}