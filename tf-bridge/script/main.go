package main

import (
	"github.com/Eclion/pulumi-playground/dummy-sdk/go/dummy"
	"github.com/pulumi/pulumi/sdk/v3/go/pulumi"
)

func main() {
	pulumi.Run(func(ctx *pulumi.Context) error {
		dummy.NewProvider()

		return nil
	})
}
