.DEFAULT_GOAL := help

PROJECT := FSDDemoApp.xcodeproj
SCHEME := FSDDemoApp
APP_ROOT := FSDDemoApp
DERIVED_DATA_PATH := DerivedData
SIMULATOR ?= iPhone 17 Pro
DESTINATION := platform=iOS Simulator,name=$(SIMULATOR)
XCODEBUILD ?= xcodebuild
SWIFT ?= swift

.PHONY: help open lint lint-strict build test demo ci clean

help:
	@printf '%s\n' \
		'Targets:' \
		'  make open         Open the Xcode project' \
		'  make lint         Run the baseline FSD lint' \
		'  make lint-strict  Run the strict FSD lint' \
		'  make build        Build the app for an iOS simulator' \
		'  make test         Run the xcodebuild test command from README' \
		'  make demo         Print the FSD map and run strict lint' \
		'  make ci           Run lint, strict lint, and tests' \
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
	$(SWIFT) tools/fsd-lint.swift --root $(APP_ROOT) --strict

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

ci: lint lint-strict test

clean:
	rm -rf $(DERIVED_DATA_PATH)
