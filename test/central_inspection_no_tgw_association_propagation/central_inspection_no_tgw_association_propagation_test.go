package test

import (
	"testing"

    "github.com/stretchr/testify/assert"

	"github.com/gruntwork-io/terratest/modules/logger"
	"github.com/gruntwork-io/terratest/modules/terraform"
    "github.com/gruntwork-io/terratest/modules/random"
)

func TestCentralInspectionNoAssociationAndPropagation(t *testing.T) {
    hclFixturesDir := "./hcl_fixtures"
    mainTestDir := "../../"

    randomId := random.UniqueId()
    identifier := ("central-ingress-Terratest-" + randomId)

    logger.Log(t, "Test: Creating Network Firewall Policy...")
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

    netFwPolicyArn := terraform.Output(t, hclFixturesOptions, "network_firewall_policy_arn")
    assert.NotNil(t, netFwPolicyArn)

    logger.Log(t, "Network Firewall Policy ARN: %s", netFwPolicyArn)

    logger.Log(t, "Test: Creating TGW and Central Inspection VPC...")
    logger.Log(t, "=============================================")

    mainStageOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
        TerraformDir: mainTestDir,
        Vars: map[string]interface{}{
            "identifier": identifier,
            "transit_gateway_attributes": map[string]interface{}{
                "name": ("tgw-" + identifier),
                "description": ("Transit_Gateway-" + identifier),
                "amazon_side_asn": 65000,
                "tags": map[string]string{
                    "team": "networking",
                    "owner": "Terratest",
                },
            },
            "network_definition": map[string]string{
                "type": "CIDR",
                "value": "10.0.0.0/8",
            },
            "central_vpcs": map[string]interface{}{
                "inspection": map[string]interface{}{
                    "name": ("inspection-vpc_Terratest-" + randomId),
                    "cidr_block": "10.10.0.0/24",
                    "az_count": 2,
                    "inspection_flow": "north-south",
                    "aws_network_firewall": map[string]interface{}{
                        "name": ("anfw-" + identifier),
                        "description": ("AWS Network Firewall - " + identifier),
                        "policy_arn": netFwPolicyArn,
                    },
                    "subnets": map[string]map[string]int{
                        "public": {
                            "netmask": 28,
                        },
                        "endpoints": {
                            "netmask": 28,
                        },
                        "transit_gateway": {
                            "netmask": 28,
                        },
                    },
                    "associate_and_propagate_to_tgw": false,
                    "tags": map[string]string{
                        "team": "security",
                        "owner": "Terratest",
                    },
                },
            },
        },
        NoColor: true,
    })
    defer CleanUp(t, mainStageOptions)
    defer terraform.Destroy(t, mainStageOptions)

    terraform.InitAndApply(t, mainStageOptions)
    // assert that output map transit_gateway_route_tables.central_vpcs is not empty
    tgwRtMap := terraform.OutputMapOfObjects(t, mainStageOptions, "transit_gateway_route_tables")
    assert.NotEmpty(t, tgwRtMap["central_vpcs"])
}
