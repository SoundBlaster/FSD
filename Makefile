.DEFAULT_GOAL := help

PROJECT := FSDDemoApp.xcodeproj
SCHEME := FSDDemoApp
APP_ROOT := FSDDemoApp
DERIVED_DATA_PATH := DerivedData
SIMULATOR ?= iPhone 17 Pro
DESTINATION := platform=iOS Simulator,name=$(SIMULATOR)
XCODEBUILD ?= xcodebuild
SWIFT ?= swift
SWIFTLINT ?= swiftlint
INSTALL_PREFIX ?= $(HOME)/.local
INSTALL_BIN_DIR := $(INSTALL_PREFIX)/bin
INSTALL_SMOKE_PREFIX := $(DERIVED_DATA_PATH)/LocalInstall
HOMEBREW_FORMULA := Formula/fsd-ios.rb
HOMEBREW_SMOKE_DIR := $(DERIVED_DATA_PATH)/HomebrewFormulaSmoke
HOMEBREW_SMOKE_TAP := fsd-ios/smoke
HOMEBREW_RELEASE_URL := https://github.com/SoundBlaster/FSD/releases/download/v0.4.0/fsd-ios-0.4.0.tar.gz
HOMEBREW_RELEASE_SHA256 := c1cccb45bbf2cad5d336a639a4c63996aa79b2d33b67f3a7a5eb3b124b692823
XCODE_TEMPLATES_SRC := templates/xcode/file-templates/FSD iOS
XCODE_TEMPLATES_DIR ?= $(HOME)/Library/Developer/Xcode/Templates/File Templates/FSD iOS
XCODE_TEMPLATES_SMOKE_DIR := $(DERIVED_DATA_PATH)/XcodeTemplatesSmoke/FSD iOS
DOCC_OUTPUT_PATH := $(DERIVED_DATA_PATH)/DocCPages
DOCC_HOSTING_BASE_PATH ?= FSD
RELEASE_GOALS := release-artifact release-artifact-smoke ci
RELEASE_GOAL_REQUESTED := $(filter $(RELEASE_GOALS),$(MAKECMDGOALS))
ifeq ($(origin RELEASE_VERSION), undefined)
ifneq ($(RELEASE_GOAL_REQUESTED),)
RELEASE_VERSION := $(shell $(SWIFT) tools/fsd-ios.swift --version 2>/dev/null | awk '/^fsd-ios [0-9]+[.][0-9]+[.][0-9]+$$/ { print $$2 }')
else
RELEASE_VERSION := 0.0.0
endif
endif
ifneq ($(RELEASE_GOAL_REQUESTED),)
RELEASE_VERSION_VALID := $(shell printf '%s\n' '$(RELEASE_VERSION)' | awk '/^[0-9]+[.][0-9]+[.][0-9]+$$/ { print "ok" }')
ifeq ($(RELEASE_VERSION_VALID),)
$(error Unable to resolve RELEASE_VERSION; expected MAJOR.MINOR.PATCH, got `$(RELEASE_VERSION)`)
endif
endif
RELEASE_PACKAGE_NAME := fsd-ios-$(RELEASE_VERSION)
RELEASE_ROOT := $(DERIVED_DATA_PATH)/Release
RELEASE_STAGING_DIR := $(RELEASE_ROOT)/$(RELEASE_PACKAGE_NAME)
RELEASE_LIBEXEC_DIR := $(RELEASE_STAGING_DIR)/libexec/fsd-ios
RELEASE_TAR := $(RELEASE_ROOT)/$(RELEASE_PACKAGE_NAME).tar
RELEASE_ARCHIVE := $(RELEASE_ROOT)/$(RELEASE_PACKAGE_NAME).tar.gz
RELEASE_CHECKSUM := $(RELEASE_ARCHIVE).sha256
RELEASE_FILE_LIST := $(RELEASE_ROOT)/$(RELEASE_PACKAGE_NAME).files
RELEASE_SMOKE_DIR := $(DERIVED_DATA_PATH)/ReleaseSmoke
RELEASE_TIMESTAMP ?= 202001010000
RELEASE_SYNC_EXCLUDES := --exclude .DS_Store --exclude .git --exclude .build --exclude .swiftpm --exclude DerivedData --exclude xcuserdata
RELEASE_PATHS := \
	README.md \
	CHANGELOG.md \
	LICENSE \
	ARCHITECTURE.md \
	CONTRIBUTING.md \
	Makefile \
	Package.swift \
	Package.resolved \
	.fsd-ios.yml \
	.swiftlint.yml \
	action.yml \
	FSDDemoApp \
	FSDDemoApp.xcodeproj \
	FSDDemoAppTests \
	FSDDemoAppUITests \
	LocalPackages \
	Plugins \
	Sources \
	docs \
	examples \
	specs \
	templates \
	tests \
	tools

.PHONY: help open install uninstall install-smoke install-xcode-templates uninstall-xcode-templates xcode-templates-smoke homebrew-formula-smoke cli-help cli-smoke cli-doctor config-smoke report-smoke action-smoke docc-mirror docc-mirror-check docc-pages docc-smoke release-docs release-artifact release-artifact-smoke lint lint-strict lint-architecture swiftlint harmonize harmonize-fixture template-create-dry-run template-create-fixture slice-create-fixture module-create-fixture template-validate template-validate-negative spm-template-test item-export-feature-test spm-template-create-fixture spm-plugin-smoke build test demo template-demo ci clean

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
		'  make homebrew-formula-smoke  Verify the reference Homebrew formula contract' \
		'  make cli-help     Print the unified fsd-ios CLI help' \
		'  make cli-smoke    Smoke-test the unified fsd-ios CLI' \
		'  make cli-doctor   Check local FSD iOS tooling prerequisites' \
		'  make config-smoke  Verify .fsd-ios.yml config loading' \
		'  make report-smoke  Verify lint text/json/xcode/sarif report formats' \
		'  make action-smoke  Smoke-test the reusable GitHub Action contract' \
		'  make docc-mirror  Generate DocC articles from repository Markdown docs' \
		'  make docc-mirror-check  Verify DocC mirror articles are synchronized' \
		'  make docc-pages   Build static DocC pages into DerivedData/DocCPages' \
		'  make docc-smoke   Verify the static DocC output contract' \
		'  make release-docs  Verify release process documentation links' \
		'  make release-artifact  Build a self-contained fsd-ios release tarball' \
		'  make release-artifact-smoke  Verify the release tarball and checksum' \
		'  make lint         Run the baseline FSD lint' \
		'  make lint-strict  Run the strict FSD lint' \
		'  make lint-architecture  Run the Swift symbol dependency lint' \
		'  make swiftlint    Run SwiftLint style checks' \
		'  make harmonize    Print read-only FSD refactoring suggestions' \
		'  make harmonize-fixture  Verify harmonize suggestions on a fixture' \
		'  make template-create-dry-run  Preview template materialization' \
		'  make template-create-fixture  Materialize and verify a generated template smoke app' \
		'  make slice-create-fixture  Generate sample page, feature, and entity slices' \
		'  make module-create-fixture  Generate and test a standalone SwiftPM module island' \
		'  make template-validate  Validate the copyable template bundle' \
		'  make template-validate-negative  Run the negative template fixture' \
		'  make spm-template-test  Build and test the SPM module-island template' \
		'  make item-export-feature-test  Test the local item export feature package' \
		'  make spm-template-create-fixture  Materialize and test the SPM template' \
		'  make spm-plugin-smoke  Verify the SwiftPM fsd-generate command plugin' \
		'  make build        Build the app for an iOS simulator' \
		'  make test         Run the xcodebuild test command from README' \
		'  make demo         Print the FSD map and run architecture lint' \
		'  make template-demo  Print the copyable template package map' \
		'  make ci           Run all lint targets and tests' \
		'  make clean        Remove local DerivedData' \
		'' \
		'Variables:' \
		'  SIMULATOR="iPhone 17 Pro"' \
		'  SWIFTLINT="swiftlint"' \
		'  DOCC_HOSTING_BASE_PATH="FSD"' \
		'  RELEASE_TIMESTAMP="202001010000"' \
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
		/|/usr|/usr/local|/System|/Applications|$(HOME)|$(HOME)/Library|$(HOME)/Library/Developer|$(HOME)/Library/Developer/Xcode|$(HOME)/Library/Developer/Xcode/Templates|$(HOME)/Library/Developer/Xcode/Templates/File\ Templates) \
			printf '%s\n' 'Refusing unsafe XCODE_TEMPLATES_DIR: $(XCODE_TEMPLATES_DIR)'; exit 1;; \
	esac
	@rm -rf "$(XCODE_TEMPLATES_DIR)"
	@mkdir -p "$(XCODE_TEMPLATES_DIR)"
	@cp -R "$(XCODE_TEMPLATES_SRC)/." "$(XCODE_TEMPLATES_DIR)/"
	@printf '%s\n' "Installed Xcode File Templates to $(XCODE_TEMPLATES_DIR)"
	@printf '%s\n' "Restart Xcode and use File > New > File… > FSD iOS"

uninstall-xcode-templates:
	@test -n "$(XCODE_TEMPLATES_DIR)" || { printf '%s\n' 'XCODE_TEMPLATES_DIR must not be empty'; exit 1; }
	@case "$(XCODE_TEMPLATES_DIR)" in \
		/|/usr|/usr/local|/System|/Applications|$(HOME)|$(HOME)/Library|$(HOME)/Library/Developer|$(HOME)/Library/Developer/Xcode|$(HOME)/Library/Developer/Xcode/Templates|$(HOME)/Library/Developer/Xcode/Templates/File\ Templates) \
			printf '%s\n' 'Refusing unsafe XCODE_TEMPLATES_DIR: $(XCODE_TEMPLATES_DIR)'; exit 1;; \
	esac
	@case "$$(basename "$(XCODE_TEMPLATES_DIR)")" in \
		FSD\ iOS) ;; \
		*) printf '%s\n' 'Refusing to remove: path must end with "FSD iOS"'; exit 1;; \
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

homebrew-formula-smoke:
	@command -v brew > /dev/null || { \
		printf '%s\n' 'Homebrew is not installed. Install it from https://brew.sh/.'; \
		exit 1; \
	}
	@test -f "$(HOMEBREW_FORMULA)"
	@grep -q 'url "$(HOMEBREW_RELEASE_URL)"' "$(HOMEBREW_FORMULA)"
	@grep -q 'sha256 "$(HOMEBREW_RELEASE_SHA256)"' "$(HOMEBREW_FORMULA)"
	ruby -c "$(HOMEBREW_FORMULA)"
	brew style "$(HOMEBREW_FORMULA)"
	@set -e; \
		export HOMEBREW_NO_AUTO_UPDATE=1; \
		export HOMEBREW_NO_ENV_HINTS=1; \
		export HOMEBREW_NO_INSTALL_CLEANUP=1; \
		brew uninstall --force "$(HOMEBREW_SMOKE_TAP)/fsd-ios" > /dev/null 2>&1 || true; \
		brew untap "$(HOMEBREW_SMOKE_TAP)" > /dev/null 2>&1 || true; \
		rm -rf "$(HOMEBREW_SMOKE_DIR)"; \
		mkdir -p "$(HOMEBREW_SMOKE_DIR)"; \
		brew tap-new --no-git "$(HOMEBREW_SMOKE_TAP)" > /dev/null; \
		trap 'brew uninstall --force "$(HOMEBREW_SMOKE_TAP)/fsd-ios" > /dev/null 2>&1 || true; brew untap "$(HOMEBREW_SMOKE_TAP)" > /dev/null 2>&1 || true' EXIT; \
		tap_dir="$$(brew --repository "$(HOMEBREW_SMOKE_TAP)")"; \
		cp "$(HOMEBREW_FORMULA)" "$$tap_dir/Formula/fsd-ios.rb"; \
		brew install --formula "$(HOMEBREW_SMOKE_TAP)/fsd-ios"; \
		installed_bin="$$(brew --prefix "$(HOMEBREW_SMOKE_TAP)/fsd-ios")/bin/fsd-ios"; \
		test -x "$$installed_bin"; \
		"$$installed_bin" --version; \
		brew test "$(HOMEBREW_SMOKE_TAP)/fsd-ios"; \
		"$$installed_bin" doctor --json > "$(HOMEBREW_SMOKE_DIR)/doctor.json"
	@$(SWIFT) -e 'import Foundation; let data = try Data(contentsOf: URL(fileURLWithPath: CommandLine.arguments[1])); let payload = try JSONSerialization.jsonObject(with: data) as! [String: Any]; precondition(payload["tool"] as? String == "fsd-ios"); precondition(payload["version"] as? String == "0.4.0"); precondition(payload["passed"] as? Bool == true)' "$(HOMEBREW_SMOKE_DIR)/doctor.json"

release-artifact:
	rm -rf "$(RELEASE_STAGING_DIR)" "$(RELEASE_TAR)" "$(RELEASE_ARCHIVE)" "$(RELEASE_CHECKSUM)" "$(RELEASE_FILE_LIST)"
	@mkdir -p "$(RELEASE_STAGING_DIR)/bin" "$(RELEASE_LIBEXEC_DIR)"
	@{ \
		printf '%s\n' '#!/bin/sh'; \
		printf '%s\n' 'set -eu'; \
		printf '%s\n' 'SCRIPT_DIR="$$(cd "$$(dirname "$$0")" && pwd)"'; \
		printf '%s\n' 'exec "$${SWIFT:-swift}" "$$SCRIPT_DIR/../libexec/fsd-ios/tools/fsd-ios.swift" "$$@"'; \
	} > "$(RELEASE_STAGING_DIR)/bin/fsd-ios"
	@chmod +x "$(RELEASE_STAGING_DIR)/bin/fsd-ios"
	@set -e; for path in $(RELEASE_PATHS); do \
		if [ ! -e "$$path" ]; then \
			printf '%s\n' "Missing release path: $$path"; \
			exit 1; \
		fi; \
		rsync -a $(RELEASE_SYNC_EXCLUDES) "$$path" "$(RELEASE_LIBEXEC_DIR)/"; \
	done
	@find "$(RELEASE_STAGING_DIR)" -exec touch -t "$(RELEASE_TIMESTAMP)" {} +
	@find "$(RELEASE_STAGING_DIR)" -type f -print | sed 's#^$(RELEASE_ROOT)/##' | LC_ALL=C sort > "$(RELEASE_FILE_LIST)"
	@cd "$(RELEASE_ROOT)" && COPYFILE_DISABLE=1 tar --format ustar --uid 0 --gid 0 --uname root --gname wheel -cf "$(notdir $(RELEASE_TAR))" -T "$(notdir $(RELEASE_FILE_LIST))"
	@cd "$(RELEASE_ROOT)" && gzip -n -c "$(notdir $(RELEASE_TAR))" > "$(notdir $(RELEASE_ARCHIVE))"
	@rm -f "$(RELEASE_TAR)"
	@cd "$(RELEASE_ROOT)" && shasum -a 256 "$(notdir $(RELEASE_ARCHIVE))" > "$(notdir $(RELEASE_CHECKSUM))"
	@printf '%s\n' "Built $(RELEASE_ARCHIVE)"
	@printf '%s\n' "Wrote $(RELEASE_CHECKSUM)"

release-artifact-smoke: release-artifact
	rm -rf "$(RELEASE_SMOKE_DIR)"
	@mkdir -p "$(RELEASE_SMOKE_DIR)"
	@cd "$(RELEASE_ROOT)" && shasum -a 256 -c "$(notdir $(RELEASE_CHECKSUM))"
	@tar -xzf "$(RELEASE_ARCHIVE)" -C "$(RELEASE_SMOKE_DIR)"
	@test -x "$(RELEASE_SMOKE_DIR)/$(RELEASE_PACKAGE_NAME)/bin/fsd-ios"
	@SWIFT="$$(command -v swift)" "$(RELEASE_SMOKE_DIR)/$(RELEASE_PACKAGE_NAME)/bin/fsd-ios" --version
	@"$(RELEASE_SMOKE_DIR)/$(RELEASE_PACKAGE_NAME)/bin/fsd-ios" doctor --json > "$(RELEASE_SMOKE_DIR)/doctor.json"
	@$(SWIFT) -e 'import Foundation; _ = try JSONSerialization.jsonObject(with: Data(contentsOf: URL(fileURLWithPath: CommandLine.arguments[1])))' "$(RELEASE_SMOKE_DIR)/doctor.json"
	@"$(RELEASE_SMOKE_DIR)/$(RELEASE_PACKAGE_NAME)/bin/fsd-ios" create app \
		--name ReleaseSmokeApp \
		--output "$(RELEASE_SMOKE_DIR)/AppDryRun" \
		--dry-run
	@test ! -e "$(RELEASE_SMOKE_DIR)/AppDryRun"
	@"$(RELEASE_SMOKE_DIR)/$(RELEASE_PACKAGE_NAME)/bin/fsd-ios" create spm \
		--name ReleaseSmokeSPM \
		--output "$(RELEASE_SMOKE_DIR)/SPMDryRun" \
		--dry-run
	@test ! -e "$(RELEASE_SMOKE_DIR)/SPMDryRun"
	@bad="$$(tar -tzf "$(RELEASE_ARCHIVE)" | grep -E '(^|/)(\.DS_Store|\.build|\.swiftpm|DerivedData|xcuserdata)(/|$$)' || true)"; \
		if [ -n "$$bad" ]; then \
			printf '%s\n' "Release artifact contains ignored files:"; \
			printf '%s\n' "$$bad"; \
			exit 1; \
		fi

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
	$(SWIFT) tools/fsd-ios.swift lint --config .fsd-ios.yml --format sarif > $(DERIVED_DATA_PATH)/LintReportPassing.sarif
	$(SWIFT) -e 'import Foundation; let data = try Data(contentsOf: URL(fileURLWithPath: CommandLine.arguments[1])); let payload = try JSONSerialization.jsonObject(with: data) as! [String: Any]; precondition(payload["version"] as? String == "2.1.0"); let runs = payload["runs"] as! [[String: Any]]; let tool = runs[0]["tool"] as! [String: Any]; let driver = tool["driver"] as! [String: Any]; precondition(driver["name"] as? String == "fsd-lint"); precondition((runs[0]["results"] as! [[String: Any]]).isEmpty)' $(DERIVED_DATA_PATH)/LintReportPassing.sarif
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
	@if $(SWIFT) tools/fsd-ios.swift lint --root tests/fixtures/report-violations/App --format sarif > $(DERIVED_DATA_PATH)/LintReportFailing.sarif; then \
		printf '%s\n' 'Expected SARIF report violation fixture to fail'; \
		exit 1; \
	else \
		printf '%s\n' 'SARIF report violation fixture failed as expected'; \
	fi
	$(SWIFT) -e 'import Foundation; let data = try Data(contentsOf: URL(fileURLWithPath: CommandLine.arguments[1])); let payload = try JSONSerialization.jsonObject(with: data) as! [String: Any]; let runs = payload["runs"] as! [[String: Any]]; let results = runs[0]["results"] as! [[String: Any]]; let result = results[0]; precondition(result["ruleId"] as? String == "fsd/root-swift-file"); precondition(result["level"] as? String == "error"); let locations = result["locations"] as! [[String: Any]]; let physical = locations[0]["physicalLocation"] as! [String: Any]; let artifact = physical["artifactLocation"] as! [String: Any]; precondition(artifact["uri"] as? String == "tests/fixtures/report-violations/App/Loose.swift"); let region = physical["region"] as! [String: Any]; precondition(region["startLine"] as? Int == 1)' $(DERIVED_DATA_PATH)/LintReportFailing.sarif
	@if $(SWIFT) tools/fsd-lint.swift --root tests/fixtures/report-violations/App --format sarif --report-root tests/fixtures > $(DERIVED_DATA_PATH)/LintReportReportRoot.sarif; then \
		printf '%s\n' 'Expected SARIF report-root fixture to fail'; \
		exit 1; \
	else \
		printf '%s\n' 'SARIF report-root fixture failed as expected'; \
	fi
	$(SWIFT) -e 'import Foundation; let data = try Data(contentsOf: URL(fileURLWithPath: CommandLine.arguments[1])); let payload = try JSONSerialization.jsonObject(with: data) as! [String: Any]; let runs = payload["runs"] as! [[String: Any]]; let results = runs[0]["results"] as! [[String: Any]]; let locations = results[0]["locations"] as! [[String: Any]]; let physical = locations[0]["physicalLocation"] as! [String: Any]; let artifact = physical["artifactLocation"] as! [String: Any]; precondition(artifact["uri"] as? String == "report-violations/App/Loose.swift")' $(DERIVED_DATA_PATH)/LintReportReportRoot.sarif
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
	@grep -q 'INPUT_OUTPUT' action.yml
	@grep -q -- '--format' action.yml
	@grep -q -- 'text|json|xcode|sarif' action.yml
	$(SWIFT) tools/fsd-ios.swift lint --root $(APP_ROOT) --strict --architecture

docc-mirror:
	$(SWIFT) tools/fsd-docc-mirror.swift

docc-mirror-check:
	$(SWIFT) tools/fsd-docc-mirror.swift --check

docc-pages: docc-mirror
	rm -rf "$(DOCC_OUTPUT_PATH)"
	@mkdir -p "$$(dirname "$(DOCC_OUTPUT_PATH)")"
	$(SWIFT) package --allow-writing-to-directory "$(DOCC_OUTPUT_PATH)" \
		generate-documentation \
		--target FSDToolingSupport \
		--output-path "$(DOCC_OUTPUT_PATH)" \
		--transform-for-static-hosting \
		--hosting-base-path "$(DOCC_HOSTING_BASE_PATH)"
	@touch "$(DOCC_OUTPUT_PATH)/.nojekyll"
	@{ \
		printf '%s\n' '<!DOCTYPE html>'; \
		printf '%s\n' '<html>'; \
		printf '%s\n' '<head>'; \
		printf '%s\n' '  <meta charset="utf-8">'; \
		printf '%s\n' '  <title>Redirecting to FSD iOS Documentation</title>'; \
		printf '%s\n' '  <meta http-equiv="refresh" content="0; url=./documentation/fsdtoolingsupport/">'; \
		printf '%s\n' '  <link rel="canonical" href="./documentation/fsdtoolingsupport/">'; \
		printf '%s\n' '</head>'; \
		printf '%s\n' '<body>'; \
		printf '%s\n' '  <p>Redirecting to <a href="./documentation/fsdtoolingsupport/">FSD iOS Documentation</a>...</p>'; \
		printf '%s\n' '  <script>window.location.href = "./documentation/fsdtoolingsupport/";</script>'; \
		printf '%s\n' '</body>'; \
		printf '%s\n' '</html>'; \
	} > "$(DOCC_OUTPUT_PATH)/index.html"

docc-smoke: docc-pages
	@test -f "$(DOCC_OUTPUT_PATH)/.nojekyll"
	@test -f "$(DOCC_OUTPUT_PATH)/index.html"
	@test -d "$(DOCC_OUTPUT_PATH)/documentation/fsdtoolingsupport"
	@grep -q 'documentation/fsdtoolingsupport' "$(DOCC_OUTPUT_PATH)/index.html"
	@test -f "Sources/FSDToolingSupport/Documentation.docc/MirroredDocumentation/DocumentationMirror.md"
	@test -f "Sources/FSDToolingSupport/Documentation.docc/MirroredDocumentation/RepositoryOverview.md"
	@test -f "Sources/FSDToolingSupport/Documentation.docc/MirroredDocumentation/FeatureSlicedDesignSpecification.md"
	@test -f "Sources/FSDToolingSupport/Documentation.docc/MirroredDocumentation/FSDWithSwiftPackageManager.md"
	@test -f "$(DOCC_OUTPUT_PATH)/documentation/fsdtoolingsupport/documentationmirror/index.html"
	@test -f "$(DOCC_OUTPUT_PATH)/documentation/fsdtoolingsupport/repositoryoverview/index.html"
	@test -f "$(DOCC_OUTPUT_PATH)/documentation/fsdtoolingsupport/featuresliceddesignspecification/index.html"
	@test -f "$(DOCC_OUTPUT_PATH)/documentation/fsdtoolingsupport/fsdwithswiftpackagemanager/index.html"

release-docs:
	@test -f CHANGELOG.md
	@test -f docs/release.md
	@grep -q '## Unreleased' CHANGELOG.md
	@grep -q '## Versioning Policy' docs/release.md
	@grep -q '## Compatibility Contract' docs/release.md
	@grep -q 'make release-artifact' docs/release.md
	@grep -q 'make release-artifact-smoke' README.md
	@test -f "$(HOMEBREW_FORMULA)"
	@grep -q '## Homebrew Contract' docs/release.md
	@grep -q 'Formula/fsd-ios.rb' docs/release.md
	@grep -q 'docs/release.md' README.md
	@grep -q 'CHANGELOG.md' README.md
	@grep -q 'docs/release.md' docs/roadmap.md

lint:
	$(SWIFT) tools/fsd-lint.swift $(APP_ROOT)

lint-strict:
	$(SWIFT) tools/fsd-lint.swift --root $(APP_ROOT) --strict

lint-architecture:
	$(SWIFT) tools/fsd-lint.swift --root $(APP_ROOT) --strict --architecture

swiftlint:
	@command -v "$(SWIFTLINT)" > /dev/null || { \
		printf '%s\n' 'SwiftLint is not installed. Install it with `brew install swiftlint`.'; \
		exit 1; \
	}
	$(SWIFTLINT) lint --strict

harmonize:
	$(SWIFT) tools/fsd-harmonize.swift --root $(APP_ROOT)

harmonize-fixture:
	@mkdir -p $(DERIVED_DATA_PATH)
	$(SWIFT) tools/fsd-harmonize.swift \
		--root tests/fixtures/harmonize-advice/FSDApp \
		--expect-suggestions 2 > $(DERIVED_DATA_PATH)/HarmonizeFixture.txt
	@grep -q '\[harmonize/vague-slice-name\] features/do-stuff' $(DERIVED_DATA_PATH)/HarmonizeFixture.txt
	@grep -q '\[harmonize/shared-domain-language\] shared/product-utils' $(DERIVED_DATA_PATH)/HarmonizeFixture.txt
	@grep -q 'Confidence: high' $(DERIVED_DATA_PATH)/HarmonizeFixture.txt
	@grep -q 'Impact: architecture' $(DERIVED_DATA_PATH)/HarmonizeFixture.txt
	@grep -q 'Evidence:' $(DERIVED_DATA_PATH)/HarmonizeFixture.txt
	@grep -q 'Recommendation:' $(DERIVED_DATA_PATH)/HarmonizeFixture.txt
	@grep -q 'Next steps:' $(DERIVED_DATA_PATH)/HarmonizeFixture.txt

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

item-export-feature-test:
	$(SWIFT) package --package-path LocalPackages/ItemExportFeature describe
	$(SWIFT) test --package-path LocalPackages/ItemExportFeature

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

spm-plugin-smoke:
	rm -rf $(DERIVED_DATA_PATH)/SPMPluginSmoke
	mkdir -p $(DERIVED_DATA_PATH)/SPMPluginSmoke/Sources/App
	$(SWIFT) package plugin --list | grep -F 'fsd-generate'
	$(SWIFT) package --allow-writing-to-package-directory fsd-generate --help | grep -F -- '--output Packages/ReportingModule'
	$(SWIFT) package --allow-writing-to-package-directory fsd-generate slice --help | grep -F 'Template kinds:'
	$(SWIFT) package --allow-writing-to-package-directory fsd-generate \
		slice feature export-report \
		--root $(DERIVED_DATA_PATH)/SPMPluginSmoke/Sources/App \
		--dry-run
	@test ! -e $(DERIVED_DATA_PATH)/SPMPluginSmoke/Sources/App/features/export-report
	$(SWIFT) package --allow-writing-to-package-directory fsd-generate \
		slice feature export-report \
		--root $(DERIVED_DATA_PATH)/SPMPluginSmoke/Sources/App
	@test -f $(DERIVED_DATA_PATH)/SPMPluginSmoke/Sources/App/features/export-report/model/ExportReportAction.swift
	$(SWIFT) package --allow-writing-to-package-directory fsd-generate \
		module Reporting \
		--output $(DERIVED_DATA_PATH)/SPMPluginSmoke/ReportingModule \
		--dry-run
	@test ! -e $(DERIVED_DATA_PATH)/SPMPluginSmoke/ReportingModule
	$(SWIFT) package --allow-writing-to-package-directory fsd-generate \
		module Reporting \
		--output $(DERIVED_DATA_PATH)/SPMPluginSmoke/ReportingModule
	@test -f $(DERIVED_DATA_PATH)/SPMPluginSmoke/ReportingModule/Package.swift
	$(SWIFT) test --package-path $(DERIVED_DATA_PATH)/SPMPluginSmoke/ReportingModule

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

ci: lint lint-strict lint-architecture swiftlint harmonize-fixture template-create-dry-run template-create-fixture slice-create-fixture module-create-fixture template-validate template-validate-negative spm-template-test item-export-feature-test spm-template-create-fixture spm-plugin-smoke cli-smoke cli-doctor config-smoke report-smoke install-smoke xcode-templates-smoke action-smoke docc-mirror-check docc-smoke release-docs release-artifact-smoke test

clean:
	rm -rf $(DERIVED_DATA_PATH)
