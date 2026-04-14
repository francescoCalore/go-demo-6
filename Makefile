ifeq ($(OS),Windows_NT)
GO := go
else
SHELL := /bin/bash
GO := GO15VENDOREXPERIMENT=1 go
endif
NAME := go-demo-6
ifeq ($(OS),Windows_NT)
HOST_OS := windows
else
HOST_OS := $(shell uname)
endif
MAIN_GO := main.go
ROOT_PACKAGE := $(GIT_PROVIDER)/vfarcic/$(NAME)
GO_VERSION = $(shell $(GO) version | sed -e 's/^[^0-9.]*\([0-9.]*\).*/\1/')
ifeq ($(OS),Windows_NT)
PACKAGE_DIRS = ./...
PKGS = ./...
else
PACKAGE_DIRS = $(shell $(GO) list ./... | grep -v /vendor/)
PKGS = $(shell go list ./... | grep -v /vendor | grep -v generated)
endif
BUILDFLAGS := ''
CGO_ENABLED = 0
VENDOR_DIR=vendor

all: build

check: fmt build test

build:
	CGO_ENABLED=$(CGO_ENABLED) $(GO) build -ldflags $(BUILDFLAGS) -o bin/$(NAME) $(MAIN_GO)

test: 
	CGO_ENABLED=$(CGO_ENABLED) $(GO) test $(PACKAGE_DIRS) -test.v

full: $(PKGS)

install:
	GOBIN=${GOPATH}/bin $(GO) install -ldflags $(BUILDFLAGS) $(MAIN_GO)

fmt:
	@FORMATTED=`$(GO) fmt $(PACKAGE_DIRS)`
	@([[ ! -z "$(FORMATTED)" ]] && printf "Fixed unformatted files:\n$(FORMATTED)") || true

clean:
	rm -rf build release

linux:
ifeq ($(OS),Windows_NT)
	powershell -NoProfile -Command "$$env:CGO_ENABLED='$(CGO_ENABLED)'; $$env:GOOS='linux'; $$env:GOARCH='amd64'; $$env:GOFLAGS='-mod=mod'; New-Item -ItemType Directory -Path 'bin' -Force | Out-Null; go mod download; go build -o 'bin/$(NAME)' '$(MAIN_GO)'"
else
	CGO_ENABLED=$(CGO_ENABLED) GOOS=linux GOARCH=amd64 $(GO) build -ldflags $(BUILDFLAGS) -o bin/$(NAME) $(MAIN_GO)
endif

.PHONY: release clean

ifneq ($(OS),Windows_NT)

FGT := $(GOPATH)/bin/fgt
$(FGT):
	go get github.com/GeertJohan/fgt

GOLINT := $(GOPATH)/bin/golint
$(GOLINT):
	go get github.com/golang/lint/golint

$(PKGS): $(GOLINT) $(FGT)
	@echo "LINTING"
	@$(FGT) $(GOLINT) $(GOPATH)/src/$@/*.go
	@echo "VETTING"
	@go vet -v $@
	@echo "TESTING"
	@go test -v $@

.PHONY: lint
lint: vendor | $(PKGS) $(GOLINT) # ❷
	@cd $(BASE) && ret=0 && for pkg in $(PKGS); do \
	    test -z "$$($(GOLINT) $$pkg | tee /dev/stderr)" || ret=1 ; \
	done ; exit $$ret

endif

