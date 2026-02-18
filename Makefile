SHELL := /bin/bash

# Gather script files tracked by git
SCRIPTS := $(shell git ls-files 'src/bin/*' 'src/lib/*.sh' 'src/packaging/*.sh' 'src/tests/*.sh' | tr '\n' ' ')

.PHONY: all lint syntax test package clean

all: lint syntax test

lint:
	@command -v shellcheck >/dev/null 2>&1 || { echo "shellcheck not installed, skipping lint"; exit 0; }
	@shellcheck -e SC1090,SC1091 $(SCRIPTS) || true

syntax:
	@echo "Running bash -n syntax checks..."
	@for f in $(SCRIPTS); do \
		[ -f $$f ] || continue; \
		bash -n $$f || { echo "Syntax error in $$f"; exit 2; }; \
	done

test:
	@echo "Running tests..."
	@bash ./src/tests/test_convert_x265.sh

package:
	@echo "Building deb package..."
	@bash src/packaging/create_deb_package.sh

clean:
	@rm -rf src/build/* || true
