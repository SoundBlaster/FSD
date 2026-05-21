.DEFAULT_GOAL := help

PROJECT := AppName.xcodeproj
SCHEME := AppName
APP_ROOT := AppName
DERIVED_DATA_PATH := DerivedData
SIMULATOR ?= iPhone 17 Pro
DESTINATION := platform=iOS Simulator,name=$(SIMULATOR)
XCODEBUILD ?= xcodebuild
SWIFT ?= swift
FSD_LINT ?= $(SWIFT) tools/fsd-lint.swift

.PHONY: help open lint lint-strict lint-architecture build test demo ci clean

help:
	@printf '%s\n' \
		'Targets:' \
		'  make open         Open the Xcode project' \
		'  make lint         Run the baseline FSD lint' \
		'  make lint-strict  Run the strict FSD lint' \
		'  make lint-architecture  Run the Swift symbol dependency lint' \
		'  make build        Build the app for an iOS simulator' \
		'  make test         Run xcodebuild tests' \
		'  make demo         Print the FSD map and run architecture lint' \
		'  make ci           Run all lint targets and tests' \
		'  make clean        Remove local DerivedData' \
		'' \
		'Variables:' \
		'  SIMULATOR="iPhone 17 Pro"'

open:
	open "$(PROJECT)"

lint:
	$(FSD_LINT) $(APP_ROOT)

lint-strict:
	$(FSD_LINT) --root $(APP_ROOT) --strict

lint-architecture:
	$(FSD_LINT) --root $(APP_ROOT) --strict --architecture

demo:
	@printf 'FSD layers:\n'
	@printf '%s\n' \
		'$(APP_ROOT)/app' \
		'$(APP_ROOT)/pages' \
		'$(APP_ROOT)/widgets' \
		'$(APP_ROOT)/features' \
		'$(APP_ROOT)/entities' \
		'$(APP_ROOT)/shared'
	@printf '\nArchitecture lint:\n'
	$(FSD_LINT) --root $(APP_ROOT) --strict --architecture

build:
	$(XCODEBUILD) \
		-project $(PROJECT) \
		-scheme $(SCHEME) \
		-destination "$(DESTINATION)" \
		-derivedDataPath $(DERIVED_DATA_PATH) \
		build \
		CODE_SIGNING_ALLOWED=NO

test:
	$(XCODEBUILD) \
		-project $(PROJECT) \
		-scheme $(SCHEME) \
		-destination "$(DESTINATION)" \
		-derivedDataPath $(DERIVED_DATA_PATH) \
		test \
		CODE_SIGNING_ALLOWED=NO

ci: lint lint-strict lint-architecture test

clean:
	rm -rf $(DERIVED_DATA_PATH)
