package test

import (
	"testing"

    "github.com/stretchr/testify/assert"

	"github.com/gruntwork-io/terratest/modules/logger"
	"github.com/gruntwork-io/terratest/modules/terraform"
    "github.com/gruntwork-io/terratest/modules/random"
)

func TestCentralEgressIngressNoAssociationAndPropagation(t *testing.T) {
    hclFixturesDir := "./hcl_fixtures"
    mainTestDir := "../../"

    randomId := random.UniqueId()
    identifier := ("central-egress-ingress-" + randomId)

    logger.Log(t, "Test: Creating TGW and Managed Prefix List...")
    logger.Log(t, "=============================================")

    hclFixturesOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
        TerraformDir: hclFixturesDir,
        Vars: map[string]interface{}{
           "identifier": identifier,
        },
        NoColor: true,
    })
    defer CleanUp(t, hclFixturesOptions)
    defer terraform.Destroy(t, hclFixturesOptions)

    terraform.InitAndApply(t, hclFixturesOptions)

    tgwId := terraform.Output(t, hclFixturesOptions, "transit_gateway_id")
    prefixListId := terraform.Output(t, hclFixturesOptions, "network_prefix_list_id")
    assert.NotNil(t, tgwId)
    assert.NotNil(t, prefixListId)

    logger.Log(t, "TGW ID: %s", tgwId)
    logger.Log(t, "Prefix List ID: %s", prefixListId)

    logger.Log(t, "Test: Creating Central VPCs...")
    logger.Log(t, "=============================================")

    mainStageOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
        TerraformDir: mainTestDir,
        Vars: map[string]interface{}{
            "identifier": identifier,
            "transit_gateway_id": tgwId,
            "network_definition": map[string]string{
                "type": "PREFIX_LIST",
                "value": prefixListId,
            },
            "central_vpcs": map[string]interface{}{
                "egress": map[string]interface{}{
                    "name": ("egress-vpc" + randomId),
                    "cidr_block": "10.10.0.0/24",
                    "az_count": 2,
                    "subnets": map[string]map[string]int{
                        "public": {
                            "netmask": 28,
                        },
                        "transit_gateway": {
                            "netmask": 28,
                        },
                    },
                    "associate_and_propagate_to_tgw": false,
                },
                "ingress": map[string]interface{}{
                    "name": ("ingress-vpc" + randomId),
                    "cidr_block": "10.20.0.0/24",
                    "az_count": 2,
                    "subnets": map[string]map[string]int{
                        "public": {
                            "netmask": 28,
                        },
                        "transit_gateway": {
                            "netmask": 28,
                        },
                    },
                    "associate_and_propagate_to_tgw": false,
                },
            },
        },
        NoColor: true,
    })
    defer CleanUp(t, mainStageOptions)
    defer terraform.Destroy(t, mainStageOptions)

    terraform.InitAndApply(t, mainStageOptions)
    // assert that output map transit_gateway_route_tables.central_vpcs is empty
    tgwRtMap := terraform.OutputMapOfObjects(t, mainStageOptions, "transit_gateway_route_tables")
    assert.Empty(t, tgwRtMap["central_vpcs"])
}
