.DEFAULT_GOAL := help

PROJECT := FSDDemoApp.xcodeproj
SCHEME := FSDDemoApp
APP_ROOT := FSDDemoApp
DERIVED_DATA_PATH := DerivedData
SIMULATOR ?= iPhone 17 Pro
DESTINATION := platform=iOS Simulator,name=$(SIMULATOR)
XCODEBUILD ?= xcodebuild
SWIFT ?= swift

.PHONY: help open lint lint-strict lint-architecture template-validate template-validate-negative build test demo template-demo ci clean

help:
	@printf '%s\n' \
		'Targets:' \
		'  make open         Open the Xcode project' \
		'  make lint         Run the baseline FSD lint' \
		'  make lint-strict  Run the strict FSD lint' \
		'  make lint-architecture  Run the Swift symbol dependency lint' \
		'  make template-validate  Validate the copyable template bundle' \
		'  make template-validate-negative  Run the negative template fixture' \
		'  make build        Build the app for an iOS simulator' \
		'  make test         Run the xcodebuild test command from README' \
		'  make demo         Print the FSD map and run architecture lint' \
		'  make template-demo  Print the copyable template package map' \
		'  make ci           Run all lint targets and tests' \
		'  make clean        Remove local DerivedData' \
		'' \
		'Variables:' \
		'  SIMULATOR="iPhone 17 Pro"'

open:
	open "$(PROJECT)"

lint:
	$(SWIFT) tools/fsd-lint.swift $(APP_ROOT)

lint-strict:
	$(SWIFT) tools/fsd-lint.swift --root $(APP_ROOT) --strict

lint-architecture:
	$(SWIFT) tools/fsd-lint.swift --root $(APP_ROOT) --strict --architecture

template-validate:
	$(SWIFT) tools/fsd-template-validate.swift --template templates/fsd-ios
	$(SWIFT) tools/fsd-lint.swift --root templates/fsd-ios/AppName --strict --architecture

template-validate-negative:
	@if $(SWIFT) tools/fsd-template-validate.swift --template tests/fixtures/template-invalid-missing-entrypoint; then \
		printf '%s\n' 'Expected invalid template fixture to fail'; \
		exit 1; \
	else \
		printf '%s\n' 'Invalid template fixture failed as expected'; \
	fi

demo:
	@printf 'FSD layers:\n'
	@printf '%s\n' \
		'$(APP_ROOT)/app' \
		'$(APP_ROOT)/pages' \
		'$(APP_ROOT)/widgets' \
		'$(APP_ROOT)/features' \
		'$(APP_ROOT)/entities' \
		'$(APP_ROOT)/shared'
	@printf '\nPage slices:\n'
	@find $(APP_ROOT)/pages -type d \( -path '$(APP_ROOT)/pages/*/*/*' -prune -o -print \) | sort
	@printf '\nFeature slices:\n'
	@find $(APP_ROOT)/features -type d \( -path '$(APP_ROOT)/features/*/*/*' -prune -o -print \) | sort
	@printf '\nWidget slices:\n'
	@find $(APP_ROOT)/widgets -type d \( -path '$(APP_ROOT)/widgets/*/*/*' -prune -o -print \) | sort
	@printf '\nEntity slices:\n'
	@find $(APP_ROOT)/entities -type d \( -path '$(APP_ROOT)/entities/*/*/*' -prune -o -print \) | sort
	@printf '\nShared slices:\n'
	@find $(APP_ROOT)/shared -type d \( -path '$(APP_ROOT)/shared/*/*/*' -prune -o -print \) | sort
	@printf '\nArchitecture lint:\n'
	$(SWIFT) tools/fsd-lint.swift --root $(APP_ROOT) --strict --architecture

template-demo:
	@printf 'Template package:\n'
	@find templates/fsd-ios -maxdepth 7 -type f | sort
	@printf '\nTemplate manifest:\n'
	@sed -n '1,120p' templates/fsd-ios/template.yaml

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

ci: lint lint-strict lint-architecture template-validate template-validate-negative test

clean:
	rm -rf $(DERIVED_DATA_PATH)
