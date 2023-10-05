package test

import (
	"testing"

    "github.com/stretchr/testify/assert"

	"github.com/gruntwork-io/terratest/modules/logger"
	"github.com/gruntwork-io/terratest/modules/terraform"
    "github.com/gruntwork-io/terratest/modules/random"
)

func TestCentralSharedServicesNoAssociationAndPropagation(t *testing.T) {
    helperDir := "./test_helpers"
    mainTestDir := "../../"

    randomId := random.UniqueId()
    identifier := ("central-egress-ingress-Terratest-" + randomId)

    logger.Log(t, "Test: Creating TGW and Spoke VPCs...")
    logger.Log(t, "=============================================")

    helperStageOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
        TerraformDir: helperDir,
        Vars: map[string]interface{}{
           "identifier": identifier,
           "spoke_vpcs": map[string]interface{}{
               ("vpc1-terratest-" + randomId): map[string]interface{}{
                    "cidr_block": "10.0.0.0/24",
                    "number_azs": 2,
               },
               ("vpc2-terratest-" + randomId): map[string]interface{}{
                    "cidr_block": "10.0.1.0/24",
                    "number_azs": 2,
                    },
                },
            },
        NoColor: true,
    })
    defer CleanUp(t, helperStageOptions)
    defer terraform.Destroy(t, helperStageOptions)

    terraform.InitAndApply(t, helperStageOptions)

    tgwId := terraform.Output(t, helperStageOptions, "transit_gateway_id")
    spokeVPCsAttributes := terraform.OutputMapOfObjects(t, helperStageOptions, "spoke_vpcs_attributes")
    assert.NotNil(t, tgwId)
    assert.NotEmpty(t, spokeVPCsAttributes)

    logger.Log(t, "TGW ID: %s", tgwId)
    logger.Log(t, "Spoke VPCs:")
    logger.Log(t, spokeVPCsAttributes)

    logger.Log(t, "Test: Creating Central VPCs...")
    logger.Log(t, "=============================================")

    mainStageOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
        TerraformDir: mainTestDir,
        Vars: map[string]interface{}{
            "identifier": identifier,
            "transit_gateway_id": tgwId,
            "network_definition": map[string]string{
                "type": "CIDR",
                "value": "10.0.0.0/24",
            },
            "central_vpcs": map[string]interface{}{
                "shared_services": map[string]interface{}{
                    "name": ("shared-services-vpc-" + randomId),
                    "cidr_block": "10.10.0.0/24",
                    "az_count": 2,
                    "subnets": map[string]map[string]int{
                        "endpoints": {
                            "netmask": 28,
                        },
                        "transit_gateway": {
                            "netmask": 28,
                        },
                    },
                    "associate_and_propagate_to_tgw": false,
                },
            },
            "spoke_vpcs": map[string]interface{}{
                "number_vpcs": len(spokeVPCsAttributes),
                "vpc_information": spokeVPCsAttributes,
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
