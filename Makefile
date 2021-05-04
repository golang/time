# latest git commit hash
LATEST_COMMIT_HASH=$(shell git rev-parse HEAD)

# go commands and variables
GO=go
GOM=$(GO) mod

# git commands
GIT=git

# environment variables related to
# cross-compilation.
GOOS_MACOS=darwin
GOOS_LINUX=linux
GOARCH=amd64

# currently installed/running Go version (full and minor)
GOVERSION=$(shell go version | grep -Eo '[1-2]\.[[:digit:]]{1,3}\.[[:digit:]]{0,3}')
MINORVER=$(shell echo $(GOVERSION) | awk '{ split($$0, array, ".") } {print array[2]}')

# Color code definitions
# Note: everything is bold.
GREEN=\033[1;38;5;70m
BLUE=\033[1;38;5;27m
LIGHT_BLUE=\033[1;38;5;32m
MAGENTA=\033[1;38;5;128m
RESET_COLOR=\033[0m

COLORECHO = $(1)$(2)$(RESET_COLOR)

default: help

setup-hooks: ## setup the repository (enables git hooks)
	git config core.hooksPath .github/hooks --replace-all

bench:  ## Run all benchmarks in the Go application
	@go test -bench=. -benchmem

clean-mods: ## Remove all the Go mod cache
	@go clean -modcache

coverage: ## Get the test coverage from go-coverage
	@go test -coverprofile=coverage.out ./... && go tool cover -func=coverage.out

godocs: ## Run a godoc server
	@echo "godoc server running on http://localhost:9000"
	@godoc -http=":9000"


golangci-install:
	@#Travis (has sudo)
	@if [ "$(shell which golangci-lint)" = "" ] && [ $(TRAVIS) ]; then curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s && sudo cp ./bin/golangci-lint $(go env GOPATH)/bin/; fi;
	@#AWS CodePipeline
	@if [ "$(shell which golangci-lint)" = "" ] && [ "$(CODEBUILD_BUILD_ID)" != "" ]; then curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s -- -b $(go env GOPATH)/bin; fi;
	@#Github Actions
	@if [ "$(shell which golangci-lint)" = "" ] && [ "$(GITHUB_WORKFLOW)" != "" ]; then curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s && sudo cp ./bin/golangci-lint $(go env GOPATH)/bin/; fi;
	@#Brew - MacOS
	@if [ "$(shell which golangci-lint)" = "" ] && [ "$(shell which brew)" != "" ]; then brew install golangci-lint; fi;

go-acc-install:
	@if [ "$(shell which "go-acc")" = "" ]; then go get -u github.com/ory/go-acc; fi;

ci-lint: golangci-install ## Run the golangci-lint application (install if not found) & fix issues if possible
	@golangci-lint run

lint: golangci-install ## Run the golangci-lint application (install if not found) & fix issues if possible
	@golangci-lint run --fix

# pre-commit hook
pre-commit: lint

test: ## run tests without coverage reporting
	@go test ./...

ci-test: go-acc-install # run a test with coverage
	@go-acc -o profile.cov ./...

gomvendor: ## run tidy & vendor
	@go mod tidy
	@go mod vendor

help: ## This help dialog.
	@IFS=$$'\n' ; \
	help_lines=(`fgrep -h "##" $(MAKEFILE_LIST) | fgrep -v fgrep | sed -e 's/\\$$//'`); \
	for help_line in $${help_lines[@]}; do \
		IFS=$$'#' ; \
		help_split=($$help_line) ; \
		help_command=`echo $${help_split[0]} | sed -e 's/^ *//' -e 's/ *$$//'` ; \
		help_info=`echo $${help_split[2]} | sed -e 's/^ *//' -e 's/ *$$//'` ; \
		printf "%-30s %s\n" $$help_command $$help_info ; \
	done