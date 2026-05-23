.DEFAULT_GOAL := help

PROJECT := FSDDemoApp.xcodeproj
SCHEME := FSDDemoApp
APP_ROOT := FSDDemoApp
DERIVED_DATA_PATH := DerivedData
SIMULATOR ?= iPhone 17 Pro
DESTINATION := platform=iOS Simulator,name=$(SIMULATOR)
XCODEBUILD ?= xcodebuild
SWIFT ?= swift
INSTALL_PREFIX ?= $(HOME)/.local
INSTALL_BIN_DIR := $(INSTALL_PREFIX)/bin
INSTALL_SMOKE_PREFIX := $(DERIVED_DATA_PATH)/LocalInstall
XCODE_TEMPLATES_SRC := templates/xcode/file-templates/FSD iOS
XCODE_TEMPLATES_DIR ?= $(HOME)/Library/Developer/Xcode/Templates/File Templates/FSD iOS
XCODE_TEMPLATES_SMOKE_DIR := $(DERIVED_DATA_PATH)/XcodeTemplatesSmoke

.PHONY: help open install uninstall install-smoke install-xcode-templates uninstall-xcode-templates xcode-templates-smoke cli-help cli-smoke cli-doctor config-smoke report-smoke action-smoke lint lint-strict lint-architecture harmonize harmonize-fixture template-create-dry-run template-create-fixture slice-create-fixture module-create-fixture template-validate template-validate-negative spm-template-test spm-template-create-fixture build test demo template-demo ci clean

help:
	@printf '%s\n' \
		'Targets:' \
		'  make open         Open the Xcode project' \
		'  make install      Install fsd-ios into INSTALL_PREFIX/bin' \
		'  make uninstall    Remove fsd-ios from INSTALL_PREFIX/bin' \
		'  make install-smoke  Verify local fsd-ios installation wrapper' \
		'  make install-xcode-templates  Install Xcode File Templates for FSD iOS' \
		'  make uninstall-xcode-templates  Remove the Xcode File Templates for FSD iOS' \
		'  make xcode-templates-smoke  Verify the Xcode File Templates install/uninstall flow' \
		'  make cli-help     Print the unified fsd-ios CLI help' \
		'  make cli-smoke    Smoke-test the unified fsd-ios CLI' \
		'  make cli-doctor   Check local FSD iOS tooling prerequisites' \
		'  make config-smoke  Verify .fsd-ios.yml config loading' \
		'  make report-smoke  Verify lint text/json/xcode report formats' \
		'  make action-smoke  Smoke-test the reusable GitHub Action contract' \
		'  make lint         Run the baseline FSD lint' \
		'  make lint-strict  Run the strict FSD lint' \
		'  make lint-architecture  Run the Swift symbol dependency lint' \
		'  make harmonize    Print read-only FSD refactoring suggestions' \
		'  make harmonize-fixture  Verify harmonize suggestions on a fixture' \
		'  make template-create-dry-run  Preview template materialization' \
		'  make template-create-fixture  Materialize and verify a generated template smoke app' \
		'  make slice-create-fixture  Generate sample page, feature, and entity slices' \
		'  make module-create-fixture  Generate and test a standalone SwiftPM module island' \
		'  make template-validate  Validate the copyable template bundle' \
		'  make template-validate-negative  Run the negative template fixture' \
		'  make spm-template-test  Build and test the SPM module-island template' \
		'  make spm-template-create-fixture  Materialize and test the SPM template' \
		'  make build        Build the app for an iOS simulator' \
		'  make test         Run the xcodebuild test command from README' \
		'  make demo         Print the FSD map and run architecture lint' \
		'  make template-demo  Print the copyable template package map' \
		'  make ci           Run all lint targets and tests' \
		'  make clean        Remove local DerivedData' \
		'' \
		'Variables:' \
		'  SIMULATOR="iPhone 17 Pro"' \
		'  INSTALL_PREFIX="$(HOME)/.local"' \
		'  XCODE_TEMPLATES_DIR="$(HOME)/Library/Developer/Xcode/Templates/File Templates/FSD iOS"'

open:
	open "$(PROJECT)"

install:
	@mkdir -p "$(INSTALL_BIN_DIR)"
	@{ \
		printf '%s\n' '#!/bin/sh'; \
		printf '%s\n' 'exec $(SWIFT) "$(abspath tools/fsd-ios.swift)" "$$@"'; \
	} > "$(INSTALL_BIN_DIR)/fsd-ios"
	@chmod +x "$(INSTALL_BIN_DIR)/fsd-ios"
	@printf '%s\n' "Installed $(INSTALL_BIN_DIR)/fsd-ios"

uninstall:
	rm -f "$(INSTALL_BIN_DIR)/fsd-ios"

install-xcode-templates:
	@test -d "$(XCODE_TEMPLATES_SRC)" || { printf '%s\n' 'Missing source: $(XCODE_TEMPLATES_SRC)'; exit 1; }
	@test -n "$(XCODE_TEMPLATES_DIR)" || { printf '%s\n' 'XCODE_TEMPLATES_DIR must not be empty'; exit 1; }
	@case "$(XCODE_TEMPLATES_DIR)" in \
		/|/usr|/usr/local|/System|/Applications|$(HOME)|$(HOME)/Library) \
			printf '%s\n' 'Refusing unsafe XCODE_TEMPLATES_DIR: $(XCODE_TEMPLATES_DIR)'; exit 1;; \
	esac
	@mkdir -p "$(XCODE_TEMPLATES_DIR)"
	@cp -R "$(XCODE_TEMPLATES_SRC)/." "$(XCODE_TEMPLATES_DIR)/"
	@printf '%s\n' "Installed Xcode File Templates to $(XCODE_TEMPLATES_DIR)"
	@printf '%s\n' "Restart Xcode and use File > New > File… > FSD iOS"

uninstall-xcode-templates:
	@test -n "$(XCODE_TEMPLATES_DIR)" || { printf '%s\n' 'XCODE_TEMPLATES_DIR must not be empty'; exit 1; }
	@case "$(XCODE_TEMPLATES_DIR)" in \
		/|/usr|/usr/local|/System|/Applications|$(HOME)|$(HOME)/Library) \
			printf '%s\n' 'Refusing unsafe XCODE_TEMPLATES_DIR: $(XCODE_TEMPLATES_DIR)'; exit 1;; \
	esac
	rm -rf "$(XCODE_TEMPLATES_DIR)"
	@printf '%s\n' "Removed $(XCODE_TEMPLATES_DIR)"

xcode-templates-smoke:
	rm -rf "$(XCODE_TEMPLATES_SMOKE_DIR)"
	$(MAKE) install-xcode-templates XCODE_TEMPLATES_DIR="$(XCODE_TEMPLATES_SMOKE_DIR)"
	@test -f "$(XCODE_TEMPLATES_SMOKE_DIR)/FSD Page.xctemplate/TemplateInfo.plist"
	@test -f "$(XCODE_TEMPLATES_SMOKE_DIR)/FSD Page.xctemplate/___FILEBASENAME___.swift"
	@test -f "$(XCODE_TEMPLATES_SMOKE_DIR)/FSD Feature Action.xctemplate/TemplateInfo.plist"
	@test -f "$(XCODE_TEMPLATES_SMOKE_DIR)/FSD Feature Action.xctemplate/___FILEBASENAME___.swift"
	@test -f "$(XCODE_TEMPLATES_SMOKE_DIR)/FSD Entity Model.xctemplate/TemplateInfo.plist"
	@test -f "$(XCODE_TEMPLATES_SMOKE_DIR)/FSD Entity Model.xctemplate/___FILEBASENAME___.swift"
	@test -f "$(XCODE_TEMPLATES_SMOKE_DIR)/FSD Widget.xctemplate/TemplateInfo.plist"
	@test -f "$(XCODE_TEMPLATES_SMOKE_DIR)/FSD Widget.xctemplate/___FILEBASENAME___.swift"
	@for plist in "$(XCODE_TEMPLATES_SMOKE_DIR)"/*.xctemplate/TemplateInfo.plist; do \
		plutil -lint "$$plist" > /dev/null || { printf '%s\n' "Invalid plist: $$plist"; exit 1; }; \
	done
	@for swift in "$(XCODE_TEMPLATES_SMOKE_DIR)"/*.xctemplate/___FILEBASENAME___.swift; do \
		grep -q '___FILEBASENAMEASIDENTIFIER___' "$$swift" || { printf '%s\n' "Missing identifier macro: $$swift"; exit 1; }; \
		grep -q '___FILEHEADER___' "$$swift" || { printf '%s\n' "Missing header macro: $$swift"; exit 1; }; \
		grep -q '<#.*#>' "$$swift" || { printf '%s\n' "Missing Xcode placeholder hint: $$swift"; exit 1; }; \
	done
	$(MAKE) uninstall-xcode-templates XCODE_TEMPLATES_DIR="$(XCODE_TEMPLATES_SMOKE_DIR)"
	@test ! -e "$(XCODE_TEMPLATES_SMOKE_DIR)"

install-smoke:
	rm -rf "$(INSTALL_SMOKE_PREFIX)"
	$(MAKE) install INSTALL_PREFIX="$(INSTALL_SMOKE_PREFIX)"
	@grep -F 'exec $(SWIFT) "$(abspath tools/fsd-ios.swift)" "$$@"' "$(INSTALL_SMOKE_PREFIX)/bin/fsd-ios" > /dev/null
	"$(INSTALL_SMOKE_PREFIX)/bin/fsd-ios" --help
	"$(INSTALL_SMOKE_PREFIX)/bin/fsd-ios" doctor --help
	$(MAKE) uninstall INSTALL_PREFIX="$(INSTALL_SMOKE_PREFIX)"
	@test ! -e "$(INSTALL_SMOKE_PREFIX)/bin/fsd-ios"

cli-help:
	$(SWIFT) tools/fsd-ios.swift --help

cli-smoke:
	rm -rf $(DERIVED_DATA_PATH)/CLICreateAppDryRun
	rm -rf $(DERIVED_DATA_PATH)/CLICreateSPMDryRun
	rm -rf $(DERIVED_DATA_PATH)/CLICreateSliceDryRun
	rm -rf $(DERIVED_DATA_PATH)/CLICreateModuleDryRun
	$(SWIFT) tools/fsd-ios.swift --help
	$(SWIFT) tools/fsd-ios.swift version
	$(SWIFT) tools/fsd-ios.swift --version
	$(SWIFT) tools/fsd-ios.swift lint --help
	$(SWIFT) tools/fsd-ios.swift lint --config .fsd-ios.yml --no-strict --no-architecture
	$(SWIFT) tools/fsd-ios.swift harmonize --help
	$(SWIFT) tools/fsd-ios.swift validate template --help
	$(SWIFT) tools/fsd-ios.swift doctor --help
	$(SWIFT) tools/fsd-ios.swift create app \
		--name CLICreateApp \
		--output $(DERIVED_DATA_PATH)/CLICreateAppDryRun \
		--dry-run
	@test ! -e $(DERIVED_DATA_PATH)/CLICreateAppDryRun
	$(SWIFT) tools/fsd-ios.swift create spm \
		--name CLICreateSPM \
		--output $(DERIVED_DATA_PATH)/CLICreateSPMDryRun \
		--dry-run
	@test ! -e $(DERIVED_DATA_PATH)/CLICreateSPMDryRun
	mkdir -p $(DERIVED_DATA_PATH)/CLICreateSliceDryRun
	$(SWIFT) tools/fsd-ios.swift create slice feature export-report \
		--root $(DERIVED_DATA_PATH)/CLICreateSliceDryRun \
		--dry-run
	@test ! -e $(DERIVED_DATA_PATH)/CLICreateSliceDryRun/features/export-report
	$(SWIFT) tools/fsd-ios.swift create module CLICreateModule \
		--output $(DERIVED_DATA_PATH)/CLICreateModuleDryRun \
		--dry-run
	@test ! -e $(DERIVED_DATA_PATH)/CLICreateModuleDryRun

cli-doctor:
	$(SWIFT) tools/fsd-ios.swift doctor
	@mkdir -p $(DERIVED_DATA_PATH)
	$(SWIFT) tools/fsd-ios.swift doctor --json > $(DERIVED_DATA_PATH)/DoctorSmoke.json
	$(SWIFT) -e 'import Foundation; _ = try JSONSerialization.jsonObject(with: Data(contentsOf: URL(fileURLWithPath: CommandLine.arguments[1])))' $(DERIVED_DATA_PATH)/DoctorSmoke.json

config-smoke:
	$(SWIFT) tools/fsd-ios.swift lint --config .fsd-ios.yml --no-strict --no-architecture
	$(SWIFT) tools/fsd-ios.swift lint --config tests/fixtures/config-explicit/.fsd-ios.yml
	$(SWIFT) tools/fsd-lint.swift --config tests/fixtures/config-explicit/.fsd-ios.yml
	cd tests/fixtures/config-explicit && $(SWIFT) ../../../tools/fsd-ios.swift lint
	@if $(SWIFT) tools/fsd-ios.swift lint --config tests/fixtures/config-invalid/.fsd-ios.yml; then \
		printf '%s\n' 'Expected invalid config fixture to fail'; \
		exit 1; \
	else \
		printf '%s\n' 'Invalid config fixture failed as expected'; \
	fi

report-smoke:
	@mkdir -p $(DERIVED_DATA_PATH)
	$(SWIFT) tools/fsd-ios.swift lint --config .fsd-ios.yml --format json > $(DERIVED_DATA_PATH)/LintReportPassing.json
	$(SWIFT) -e 'import Foundation; let data = try Data(contentsOf: URL(fileURLWithPath: CommandLine.arguments[1])); let payload = try JSONSerialization.jsonObject(with: data) as! [String: Any]; precondition(payload["tool"] as? String == "fsd-lint"); precondition(payload["format"] as? String == "json"); precondition((payload["findings"] as! [[String: Any]]).isEmpty)' $(DERIVED_DATA_PATH)/LintReportPassing.json
	@if $(SWIFT) tools/fsd-ios.swift lint --root tests/fixtures/report-violations/App --format text > $(DERIVED_DATA_PATH)/LintReportText.txt; then \
		printf '%s\n' 'Expected text report violation fixture to fail'; \
		exit 1; \
	else \
		printf '%s\n' 'Text report violation fixture failed as expected'; \
	fi
	@grep -q 'error: Loose.swift: Swift files should live inside an FSD layer' $(DERIVED_DATA_PATH)/LintReportText.txt
	@if $(SWIFT) tools/fsd-ios.swift lint --root tests/fixtures/report-violations/App --format json > $(DERIVED_DATA_PATH)/LintReportFailing.json; then \
		printf '%s\n' 'Expected report violation fixture to fail'; \
		exit 1; \
	else \
		printf '%s\n' 'Report violation fixture failed as expected'; \
	fi
	$(SWIFT) -e 'import Foundation; let data = try Data(contentsOf: URL(fileURLWithPath: CommandLine.arguments[1])); let payload = try JSONSerialization.jsonObject(with: data) as! [String: Any]; let findings = payload["findings"] as! [[String: Any]]; precondition(findings.first?["ruleId"] as? String == "fsd/root-swift-file"); precondition(findings.first?["severity"] as? String == "error")' $(DERIVED_DATA_PATH)/LintReportFailing.json
	@if $(SWIFT) tools/fsd-ios.swift lint --root tests/fixtures/report-violations/App --format xcode > $(DERIVED_DATA_PATH)/LintReportXcode.txt; then \
		printf '%s\n' 'Expected Xcode report violation fixture to fail'; \
		exit 1; \
	else \
		printf '%s\n' 'Xcode report violation fixture failed as expected'; \
	fi
	@grep -q 'Loose.swift:1: error: \[fsd/root-swift-file\]' $(DERIVED_DATA_PATH)/LintReportXcode.txt
	@if $(SWIFT) tools/fsd-ios.swift lint --format xml > /dev/null 2>&1; then \
		printf '%s\n' 'Expected unsupported lint report format to fail'; \
		exit 1; \
	else \
		printf '%s\n' 'Unsupported lint report format failed as expected'; \
	fi

action-smoke:
	@test -f action.yml
	@grep -q '^runs:' action.yml
	@grep -q 'using: composite' action.yml
	@grep -q 'tools/fsd-ios.swift' action.yml
	@grep -q 'INPUT_ROOT' action.yml
	@grep -q 'INPUT_CONFIG' action.yml
	@grep -q -- '--no-strict' action.yml
	@grep -q -- '--no-architecture' action.yml
	@grep -q 'INPUT_FORMAT' action.yml
	@grep -q -- '--format' action.yml
	$(SWIFT) tools/fsd-ios.swift lint --root $(APP_ROOT) --strict --architecture

lint:
	$(SWIFT) tools/fsd-lint.swift $(APP_ROOT)

lint-strict:
	$(SWIFT) tools/fsd-lint.swift --root $(APP_ROOT) --strict

lint-architecture:
	$(SWIFT) tools/fsd-lint.swift --root $(APP_ROOT) --strict --architecture

harmonize:
	$(SWIFT) tools/fsd-harmonize.swift --root $(APP_ROOT)

harmonize-fixture:
	$(SWIFT) tools/fsd-harmonize.swift \
		--root tests/fixtures/harmonize-advice/FSDApp \
		--expect-suggestions 2

template-create-dry-run:
	rm -rf $(DERIVED_DATA_PATH)/TemplateCreateDryRun
	rm -f $(DERIVED_DATA_PATH)/TemplateCreateFileOutput
	$(SWIFT) tools/fsd-template-create.swift \
		--template templates/fsd-ios \
		--app-name SmokeApp \
		--output $(DERIVED_DATA_PATH)/TemplateCreateDryRun \
		--dry-run
	@test ! -e $(DERIVED_DATA_PATH)/TemplateCreateDryRun
	@mkdir -p $(DERIVED_DATA_PATH)
	@printf '%s\n' 'not a directory' > $(DERIVED_DATA_PATH)/TemplateCreateFileOutput
	@if $(SWIFT) tools/fsd-template-create.swift \
		--template templates/fsd-ios \
		--app-name SmokeApp \
		--output $(DERIVED_DATA_PATH)/TemplateCreateFileOutput \
		--dry-run; then \
		printf '%s\n' 'Expected file output dry-run to fail'; \
		exit 1; \
	else \
		printf '%s\n' 'File output dry-run failed as expected'; \
	fi
	@rm -f $(DERIVED_DATA_PATH)/TemplateCreateFileOutput

template-create-fixture:
	rm -rf $(DERIVED_DATA_PATH)/TemplateCreateSmoke
	rm -rf $(DERIVED_DATA_PATH)/TemplateCreateNameSmoke
	rm -rf $(DERIVED_DATA_PATH)/TemplateCreateSymlinkTemplate
	rm -rf $(DERIVED_DATA_PATH)/TemplateCreateSymlinkSmoke
	$(SWIFT) tools/fsd-template-create.swift \
		--template templates/fsd-ios \
		--app-name SmokeApp \
		--output $(DERIVED_DATA_PATH)/TemplateCreateSmoke
	@test -f $(DERIVED_DATA_PATH)/TemplateCreateSmoke/SmokeApp/app/entrypoint/SmokeAppApp.swift
	@if grep -R 'AppName' $(DERIVED_DATA_PATH)/TemplateCreateSmoke > /dev/null; then \
		printf '%s\n' 'Generated template still contains AppName placeholder'; \
		exit 1; \
	fi
	$(SWIFT) tools/fsd-lint.swift --root $(DERIVED_DATA_PATH)/TemplateCreateSmoke/SmokeApp --strict --architecture
	$(SWIFT) tools/fsd-template-create.swift \
		--template templates/fsd-ios \
		--app-name MyAppName \
		--output $(DERIVED_DATA_PATH)/TemplateCreateNameSmoke
	@test -f $(DERIVED_DATA_PATH)/TemplateCreateNameSmoke/MyAppName/app/entrypoint/MyAppNameApp.swift
	$(SWIFT) tools/fsd-lint.swift --root $(DERIVED_DATA_PATH)/TemplateCreateNameSmoke/MyAppName --strict --architecture
	@cp -R templates/fsd-ios $(DERIVED_DATA_PATH)/TemplateCreateSymlinkTemplate
	@ln -s /etc/passwd $(DERIVED_DATA_PATH)/TemplateCreateSymlinkTemplate/external-link
	@if $(SWIFT) tools/fsd-template-create.swift \
		--template $(DERIVED_DATA_PATH)/TemplateCreateSymlinkTemplate \
		--app-name SmokeApp \
		--output $(DERIVED_DATA_PATH)/TemplateCreateSymlinkSmoke; then \
		printf '%s\n' 'Expected symlink template to fail'; \
		exit 1; \
	else \
		printf '%s\n' 'Symlink template failed as expected'; \
	fi
	@if $(SWIFT) tools/fsd-template-create.swift \
		--template templates/fsd-ios \
		--app-name SmokeApp \
		--output $(DERIVED_DATA_PATH)/TemplateCreateSmoke; then \
		printf '%s\n' 'Expected existing destination conflict to fail'; \
		exit 1; \
	else \
		printf '%s\n' 'Existing destination conflict failed as expected'; \
	fi

slice-create-fixture:
	rm -rf $(DERIVED_DATA_PATH)/SliceCreateSmoke
	mkdir -p $(DERIVED_DATA_PATH)/SliceCreateSmoke
	$(SWIFT) tools/fsd-ios.swift create slice page order-details \
		--root $(DERIVED_DATA_PATH)/SliceCreateSmoke
	$(SWIFT) tools/fsd-ios.swift create slice feature export-report \
		--root $(DERIVED_DATA_PATH)/SliceCreateSmoke
	$(SWIFT) tools/fsd-ios.swift create slice entity customer-account \
		--root $(DERIVED_DATA_PATH)/SliceCreateSmoke
	@test -f $(DERIVED_DATA_PATH)/SliceCreateSmoke/pages/order-details/ui/OrderDetailsPage.swift
	@test -f $(DERIVED_DATA_PATH)/SliceCreateSmoke/features/export-report/model/ExportReportAction.swift
	@test -f $(DERIVED_DATA_PATH)/SliceCreateSmoke/entities/customer-account/ui/CustomerAccountRow.swift
	$(SWIFT) tools/fsd-lint.swift --root $(DERIVED_DATA_PATH)/SliceCreateSmoke --strict --architecture
	@if $(SWIFT) tools/fsd-ios.swift create slice feature export-report \
		--root $(DERIVED_DATA_PATH)/SliceCreateSmoke; then \
		printf '%s\n' 'Expected existing slice conflict to fail'; \
		exit 1; \
	else \
		printf '%s\n' 'Existing slice conflict failed as expected'; \
	fi
	@if $(SWIFT) tools/fsd-ios.swift create slice feature ui \
		--root $(DERIVED_DATA_PATH)/SliceCreateSmoke; then \
		printf '%s\n' 'Expected reserved slice name to fail'; \
		exit 1; \
	else \
		printf '%s\n' 'Reserved slice name failed as expected'; \
	fi

module-create-fixture:
	rm -rf $(DERIVED_DATA_PATH)/ModuleCreateSmoke
	$(SWIFT) tools/fsd-ios.swift create module Reporting \
		--output $(DERIVED_DATA_PATH)/ModuleCreateSmoke
	@test -f $(DERIVED_DATA_PATH)/ModuleCreateSmoke/Package.swift
	@test -f $(DERIVED_DATA_PATH)/ModuleCreateSmoke/Sources/Reporting/ReportingModule.swift
	$(SWIFT) test --package-path $(DERIVED_DATA_PATH)/ModuleCreateSmoke

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

spm-template-test:
	$(SWIFT) package --package-path templates/fsd-ios-spm describe
	$(SWIFT) test --package-path templates/fsd-ios-spm

spm-template-create-fixture:
	rm -rf $(DERIVED_DATA_PATH)/SPMTemplateSmoke
	$(SWIFT) tools/fsd-template-create.swift \
		--template templates/fsd-ios-spm \
		--app-name LegacyFSD \
		--output $(DERIVED_DATA_PATH)/SPMTemplateSmoke
	@test -f $(DERIVED_DATA_PATH)/SPMTemplateSmoke/Package.swift
	@test -f $(DERIVED_DATA_PATH)/SPMTemplateSmoke/Sources/LegacyFSDProductListScreen/ProductListScreen.swift
	@if grep -R 'AppName' $(DERIVED_DATA_PATH)/SPMTemplateSmoke > /dev/null; then \
		printf '%s\n' 'Generated SPM template still contains AppName placeholder'; \
		exit 1; \
	fi
	$(SWIFT) test --package-path $(DERIVED_DATA_PATH)/SPMTemplateSmoke

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
	@printf 'Application template package:\n'
	@find templates/fsd-ios -maxdepth 7 -type f | sort
	@printf '\nTemplate manifest:\n'
	@sed -n '1,120p' templates/fsd-ios/template.yaml
	@printf '\nSPM module-island template package:\n'
	@find templates/fsd-ios-spm -maxdepth 7 -type f | sort
	@printf '\nSPM template manifest:\n'
	@sed -n '1,120p' templates/fsd-ios-spm/template.yaml

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

ci: lint lint-strict lint-architecture harmonize-fixture template-create-dry-run template-create-fixture slice-create-fixture module-create-fixture template-validate template-validate-negative spm-template-test spm-template-create-fixture cli-smoke cli-doctor config-smoke report-smoke install-smoke xcode-templates-smoke action-smoke test

clean:
	rm -rf $(DERIVED_DATA_PATH)
