package test

import (
	"testing"

	"github.com/gruntwork-io/terratest/modules/logger"
	"github.com/gruntwork-io/terratest/modules/terraform"
)

func TestExamplesCentralEgressIngress(t *testing.T) {
	logger.Logf(t, "Starting test - Central Egress and Ingress")

	terraformOptions := &terraform.Options{
		TerraformDir: "../examples/central_egress_ingress",
	}

	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)
}