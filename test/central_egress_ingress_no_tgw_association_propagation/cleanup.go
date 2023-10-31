package test

import (
    "testing"
    "os"
    "path/filepath"

    "github.com/gruntwork-io/terratest/modules/terraform"
    "github.com/gruntwork-io/terratest/modules/logger"
)

func CleanUp(t *testing.T, terraformOptions *terraform.Options) {
    os.Remove(filepath.Join(terraformOptions.TerraformDir, "terraform.tfstate"))
    os.Remove(filepath.Join(terraformOptions.TerraformDir, "terraform.tfstate.backup"))
    os.Remove(filepath.Join(terraformOptions.TerraformDir, ".terraform.lock.hcl"))
    os.RemoveAll(filepath.Join(terraformOptions.TerraformDir, ".terraform"))
    logger.Log(t, "==> Temporary module state is deleted.")
}
