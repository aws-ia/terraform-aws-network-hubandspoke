package test

import (
	"testing"

	"github.com/gruntwork-io/terratest/modules/logger"
	"github.com/gruntwork-io/terratest/modules/terraform"
)

func TestExamplesSpokesRoutingOnly(t *testing.T) {
	logger.Logf(t, "Starting test - Spokes Routing")

	terraformOptions := &terraform.Options{
		TerraformDir: "../examples/spokes_routing_only",
	}

	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)
}