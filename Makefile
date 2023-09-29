PROJECT_NAME := dummy Package

SHELL            := /bin/bash
PACK             := dummy
PROJECT          := github.com/Eclion/pulumi-playground
NODE_MODULE_NAME := @pulumi/${PACK}
TF_NAME          := ${PACK}
SDK_PATH         := ${PACK}-sdk
PROVIDER_PATH    := ${PACK}-provider
VERSION_PATH     := ${PROVIDER_PATH}/pkg/version.Version

TFGEN           := pulumi-tfgen-${PACK}
PROVIDER        := pulumi-resource-${PACK}
VERSION         := $(shell pulumictl get version)

TESTPARALLELISM := 4

WORKING_DIR     := $(shell pwd)

OS := $(shell uname)
EMPTY_TO_AVOID_SED := ""

.PHONY: development provider build_sdks build_go cleanup

development:: install_plugins provider lint_provider build_sdks cleanup # Build the provider & SDKs for a development environment

# Required for the codegen action that runs in pulumi/pulumi and pulumi/pulumi-terraform-bridge
build:: install_plugins provider build_sdks
only_build:: build

tfgen:: install_plugins
	(cd ${PROVIDER_PATH} && go build -o $(WORKING_DIR)/bin/${TFGEN} -ldflags "-X ${PROJECT}/${VERSION_PATH}=${VERSION}" ${PROJECT}/${PROVIDER_PATH}/cmd/${TFGEN})
	$(WORKING_DIR)/bin/${TFGEN} schema --out ${PROVIDER_PATH}/cmd/${PROVIDER}
	(cd ${PROVIDER_PATH} && VERSION=$(VERSION) go generate cmd/${PROVIDER}/main.go)

provider:: tfgen install_plugins # build the provider binary
	(cd ${PROVIDER_PATH} && go build -o $(WORKING_DIR)/bin/${PROVIDER} -ldflags "-X ${PROJECT}/${VERSION_PATH}=${VERSION}" ${PROJECT}/${PROVIDER_PATH}/cmd/${PROVIDER})

build_sdks:: install_plugins provider build_go # build all the sdks

build_go:: install_plugins tfgen # build the go sdk
	$(WORKING_DIR)/bin/$(TFGEN) go --overlays ${PROVIDER_PATH}/overlays/go --out ${SDK_PATH}/go/

lint_provider:: provider # lint the provider code
	cd ${PROVIDER_PATH} && golangci-lint run -c ../.golangci.yml

cleanup:: # cleans up the temporary directory
	rm -r $(WORKING_DIR)/bin
	rm -f ${PROVIDER_PATH}/cmd/${PROVIDER}/schema.go

help::
	@grep '^[^.#]\+:\s\+.*#' Makefile | \
 	sed "s/\(.\+\):\s*\(.*\) #\s*\(.*\)/`printf "\033[93m"`\1`printf "\033[0m"`	\3 [\2]/" | \
 	expand -t20

clean::
	rm -rf ${SDK_PATH}/{go}

install_plugins::
	[ -x $(shell which pulumi) ] || curl -fsSL https://get.pulumi.com | sh

test::
	cd examples && go test -v -tags=all -parallel ${TESTPARALLELISM} -timeout 2h

