SHELL := /usr/bin/env bash
PYTHON ?= /usr/bin/python3

.PHONY: all validate validate-plugin format-check lint test test-astronomy test-protocol test-qml test-integration test-accessibility test-performance package-check release-check safety-check

all: validate test

validate: validate-plugin package-check safety-check qml-check

validate-plugin:
	omarchy plugin validate .

format-check:
	./scripts/format-check.sh

lint: qml-check
	PYTHONPYCACHEPREFIX=/tmp/moonshot-lint-pycache $(PYTHON) -m py_compile scripts/moonshot_ephemeris.py
	@echo "lint: OK"

qml-check:
	./scripts/qml-check.sh

test:
	PYTHONDONTWRITEBYTECODE=1 $(PYTHON) -m unittest discover -s tests -v

test-astronomy:
	PYTHONDONTWRITEBYTECODE=1 $(PYTHON) -m unittest tests/test_classification.py tests/test_ephemeris.py tests/test_rise_set.py -v

test-protocol:
	PYTHONDONTWRITEBYTECODE=1 $(PYTHON) -m unittest tests/test_protocol.py tests/test_timezones.py -v

test-qml: qml-check
	./scripts/qml-runtime-check.sh

test-integration:
	PYTHONDONTWRITEBYTECODE=1 $(PYTHON) -m unittest discover -s tests -v

test-accessibility:
	./scripts/accessibility-check.sh

test-performance:
	PYTHONDONTWRITEBYTECODE=1 $(PYTHON) -m unittest tests/test_performance.py -v

package-check:
	./scripts/package-check.sh

safety-check:
	./scripts/safety-check.sh

release-check:
	./scripts/release-check.sh
