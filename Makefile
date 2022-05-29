###############################################################################
# Makefile for mxmake projects.
###############################################################################

# Defensive settings for make: https://tech.davis-hansson.com/p/make/
SHELL:=bash
.ONESHELL:
# for Makefile debugging purposes add -x to the .SHELLFLAGS
.SHELLFLAGS:=-eu -o pipefail -O inherit_errexit -c
.SILENT:
.DELETE_ON_ERROR:
MAKEFLAGS+=--warn-undefined-variables
MAKEFLAGS+=--no-builtin-rules

# Sentinel files
SENTINEL_FOLDER:=.sentinels
SENTINEL:=$(SENTINEL_FOLDER)/about.txt
$(SENTINEL):
	@mkdir -p $(SENTINEL_FOLDER)
	@echo "Sentinels for the Makefile process." > $(SENTINEL)

###############################################################################
# venv
###############################################################################

PYTHON_BIN?=python3
VENV_FOLDER?=venv
PIP_BIN:=$(VENV_FOLDER)/bin/pip

# This setting is for customizing the installation of mxdev. Normally only
# needed if working on mxdev development.
#MXDEV?=mxdev
MXDEV?=https://github.com/mxstack/mxdev/archive/remove_libvcs.zip

# This setting is for customizing the installation of mxmake. Normally only
# needed if working on mxmake development
#MXMAKE?=mxmake
MXMAKE?=https://github.com/mxstack/mxmake/archive/master.zip

VENV_SENTINEL:=$(SENTINEL_FOLDER)/venv.sentinel
$(VENV_SENTINEL): $(SENTINEL)
	@echo "Setup Python Virtual Environment under '$(VENV_FOLDER)'"
	@$(PYTHON_BIN) -m venv $(VENV_FOLDER)
	@$(PIP_BIN) install -U pip setuptools wheel
	@$(PIP_BIN) install -U $(MXDEV)
	@$(PIP_BIN) install -U $(MXMAKE)
	@touch $(VENV_SENTINEL)

.PHONY: venv
venv: $(VENV_SENTINEL)

.PHONY: venv-dirty
venv-dirty:
	@rm -f $(VENV_SENTINEL)

.PHONY: venv-clean
venv-clean: venv-dirty
	@rm -rf $(VENV_FOLDER)

###############################################################################
# files
###############################################################################

# set environment variables for mxmake
define set_files_env
	@export MXMAKE_VENV_FOLDER=$(1)
	@export MXMAKE_SCRIPTS_FOLDER=$(2)
	@export MXMAKE_CONFIG_FOLDER=$(3)
endef

# unset environment variables for mxmake
define unset_files_env
	@unset MXMAKE_VENV_FOLDER
	@unset MXMAKE_SCRIPTS_FOLDER
	@unset MXMAKE_CONFIG_FOLDER
endef

PROJECT_CONFIG?=mx.ini
SCRIPTS_FOLDER?=$(VENV_FOLDER)/bin
CONFIG_FOLDER?=cfg

FILES_SENTINEL:=$(SENTINEL_FOLDER)/files.sentinel
$(FILES_SENTINEL): $(PROJECT_CONFIG) $(VENV_SENTINEL)
	@echo "Create project files"
	$(call set_files_env,$(VENV_FOLDER),$(SCRIPTS_FOLDER),$(CONFIG_FOLDER))
	@$(VENV_FOLDER)/bin/mxdev -n -c $(PROJECT_CONFIG)
	$(call unset_files_env,$(VENV_FOLDER),$(SCRIPTS_FOLDER),$(CONFIG_FOLDER))
	@touch $(FILES_SENTINEL)

.PHONY: files
files: $(FILES_SENTINEL)

.PHONY: files-dirty
files-dirty:
	@rm -f $(FILES_SENTINEL)

.PHONY: files-clean
files-clean: files-dirty
	$(call set_files_env,$(VENV_FOLDER),$(SCRIPTS_FOLDER),$(CONFIG_FOLDER))
	@test -e $(VENV_FOLDER)/bin/mxmake && \
		$(VENV_FOLDER)/bin/mxmake clean -c $(PROJECT_CONFIG)
	$(call unset_files_env,$(VENV_FOLDER),$(SCRIPTS_FOLDER),$(CONFIG_FOLDER))
	@rm -f constraints-mxdev.txt requirements-mxdev.txt

###############################################################################
# sources
###############################################################################

SOURCES_SENTINEL:=$(SENTINEL_FOLDER)/sources.sentinel
$(SOURCES_SENTINEL): $(FILES_SENTINEL)
	@echo "Checkout project sources"
	@$(VENV_FOLDER)/bin/mxdev -o -c $(PROJECT_CONFIG)
	@touch $(SOURCES_SENTINEL)

.PHONY: sources
sources: $(SOURCES_SENTINEL)

.PHONY: sources-dirty
sources-dirty:
	@rm -f $(SOURCES_SENTINEL)

.PHONY: sources-clean
sources-clean: sources-dirty
	@rm -rf sources

###############################################################################
# install
###############################################################################

INSTALLED_PACKAGES=.installed.txt

INSTALL_SENTINEL:=$(SENTINEL_FOLDER)/install.sentinel
$(INSTALL_SENTINEL): $(SOURCES_SENTINEL)
	@echo "Install python packages"
	@$(PIP_BIN) install -r requirements-mxdev.txt
	@$(PIP_BIN) freeze > $(INSTALLED_PACKAGES)
	@touch $(INSTALL_SENTINEL)

.PHONY: install
install: $(INSTALL_SENTINEL)

.PHONY: install-dirty
install-dirty:
	@rm -f $(INSTALL_SENTINEL)

###############################################################################
# system dependencies
###############################################################################

SYSTEM_DEPENDENCIES?=

.PHONY: system-dependencies
system-dependencies:
	@echo "Install system dependencies"
	@test -z "$(SYSTEM_DEPENDENCIES)" && echo "No System dependencies defined"
	@test -z "$(SYSTEM_DEPENDENCIES)" \
		|| sudo apt-get install -y $(SYSTEM_DEPENDENCIES)

###############################################################################
# docs
###############################################################################

DOCS_BIN?=$(VENV_FOLDER)/bin/sphinx-build
DOCS_SOURCE?=docs/source
DOCS_TARGET?=docs/html

.PHONY: docs
docs:
	@echo "Build sphinx docs"
	@test -e $(DOCS_BIN) && $(DOCS_BIN) $(DOCS_SOURCE) $(DOCS_TARGET)
	@test -e $(DOCS_BIN) || echo "Sphinx binary not exists"

.PHONY: docs-clean
docs-clean:
	@rm -rf $(DOCS_TARGET)

###############################################################################
# test
###############################################################################

TEST_COMMAND?=$(SCRIPTS_FOLDER)/run-tests.sh

.PHONY: test
test: $(FILES_SENTINEL) $(SOURCES_SENTINEL) $(INSTALL_SENTINEL)
	@echo "Run tests"
	@test -z "$(TEST_COMMAND)" && echo "No test command defined"
	@test -z "$(TEST_COMMAND)" || bash -c "$(TEST_COMMAND)"

###############################################################################
# coverage
###############################################################################

COVERAGE_COMMAND?=$(SCRIPTS_FOLDER)/run-coverage.sh

.PHONY: coverage
coverage: $(FILES_SENTINEL) $(SOURCES_SENTINEL) $(INSTALL_SENTINEL)
	@echo "Run coverage"
	@test -z "$(COVERAGE_COMMAND)" && echo "No coverage command defined"
	@test -z "$(COVERAGE_COMMAND)" || bash -c "$(COVERAGE_COMMAND)"

.PHONY: coverage-clean
coverage-clean:
	@rm -rf .coverage htmlcov

###############################################################################
# clean
###############################################################################

CLEAN_TARGETS?=

.PHONY: clean
clean: files-clean venv-clean docs-clean coverage-clean
	@rm -rf $(CLEAN_TARGETS) .sentinels .installed.txt

.PHONY: full-clean
full-clean: clean sources-clean

.PHONY: runtime-clean
runtime-clean:
	@echo "Remove runtime artifacts, like byte-code and caches."
	@find . -name '*.py[c|o]' -delete
	@find . -name '*~' -exec rm -f {} +
	@find . -name '__pycache__' -exec rm -fr {} +

###############################################################################
# Include custom make files
###############################################################################

INCLUDE_FOLDER?=mk

-include $(INCLUDE_FOLDER)/project.mk
