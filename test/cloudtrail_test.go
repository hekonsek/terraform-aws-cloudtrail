package test

import (
	"testing"
)
import "github.com/gruntwork-io/terratest/modules/terraform"

func Test(t *testing.T) {
	// Given
	terraformOptions := &terraform.Options{}
	defer terraform.Destroy(t, terraformOptions)

	// When
	terraform.InitAndApply(t, terraformOptions)
}
