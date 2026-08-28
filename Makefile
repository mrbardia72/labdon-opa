APP_NAME := app
MAIN_FILE := app.go
POLICY_DIR := policy/authorization
BIN_DIR := bin

# -------------------------------------------------
# Tool Versions
# -------------------------------------------------

OPA_VERSION := 1.20.0
REGAL_VERSION := 0.42.0

# -------------------------------------------------
# Tools
# -------------------------------------------------

GO := go
OPA := opa
REGAL := regal

# -------------------------------------------------
# Phony Targets
# -------------------------------------------------

.PHONY: \
	run \
	build \
	start \
	test \
	test-go \
	test-policy \
	fmt \
	fmt-go \
	fmt-policy \
	fmt-check \
	policy-check \
	lint-policy \
	check \
	install \
	install-tools \
	install-opa \
	install-regal \
	verify \
	deps \
	tidy \
	clean \
	help


# =================================================
# Development
# =================================================

# Run the application
run:
	$(GO) run $(MAIN_FILE)


# Build the application
build:
	@mkdir -p $(BIN_DIR)
	$(GO) build -o $(BIN_DIR)/$(APP_NAME) $(MAIN_FILE)


# Build and run the application
start: build
	./$(BIN_DIR)/$(APP_NAME)


# =================================================
# Tests
# =================================================

# Run all tests
test: test-go test-policy

# Run Go tests
test-go:
	$(GO) test ./...

# Run Rego policy tests
test-policy:
	$(OPA) test $(POLICY_DIR) -v


# =================================================
# Formatting
# =================================================

# Format Go code
fmt-go:
	$(GO) fmt ./...

# Format Rego policies
fmt-policy:
	$(OPA) fmt -w $(POLICY_DIR)

# Format everything
fmt: fmt-go fmt-policy


# Check formatting without modifying files
fmt-check:
	@echo "Checking Go formatting..."
	@test -z "$$($(GO) fmt ./...)" || { \
		echo "❌ Go files are not formatted."; \
		exit 1; \
	}

	@echo "Checking Rego formatting..."
	@$(OPA) fmt $(POLICY_DIR) >/dev/null
	@echo "✅ Formatting check passed."


# =================================================
# Policy Quality
# =================================================

# Check Rego syntax and types
policy-check:
	$(OPA) check $(POLICY_DIR)

# Lint Rego policies
lint-policy:
	$(REGAL) lint $(POLICY_DIR)


# =================================================
# Full Validation
# =================================================

# Run all checks without modifying source files
check: fmt-check policy-check lint-policy test


# =================================================
# Dependencies
# =================================================

# Download Go dependencies
deps:
	$(GO) mod download

# Tidy Go dependencies
tidy:
	$(GO) mod tidy

# Install all development tools
install: install-tools deps


# -------------------------------------------------
# Install Development Tools
# -------------------------------------------------

install-tools: install-opa install-regal


# Install OPA CLI
install-opa:
	@echo "Installing OPA $(OPA_VERSION)..."
	$(GO) install github.com/open-policy-agent/opa@v$(OPA_VERSION)


# Install Regal
install-regal:
	@echo "Installing Regal $(REGAL_VERSION)..."
	$(GO) install github.com/open-policy-agent/regal@v$(REGAL_VERSION)


# =================================================
# Environment Verification
# =================================================

verify:
	@echo "Checking Go..."
	@$(GO) version

	@echo ""
	@echo "Checking OPA..."
	@$(OPA) version

	@echo ""
	@echo "Checking Regal..."
	@$(REGAL) version


# =================================================
# Clean
# =================================================

clean:
	@rm -rf $(BIN_DIR)


# =================================================
# Help
# =================================================

help:
	@echo ""
	@echo "Available commands:"
	@echo ""
	@echo "  make install          Install project dependencies and tools"
	@echo "  make install-tools    Install OPA and Regal"
	@echo "  make deps             Download Go dependencies"
	@echo "  make tidy             Tidy Go dependencies"
	@echo ""
	@echo "  make run              Run the application"
	@echo "  make build            Build the application"
	@echo "  make start            Build and run the application"
	@echo ""
	@echo "  make test             Run Go and Rego tests"
	@echo "  make test-go          Run Go tests"
	@echo "  make test-policy      Run Rego policy tests"
	@echo ""
	@echo "  make fmt              Format Go and Rego files"
	@echo "  make fmt-go           Format Go files"
	@echo "  make fmt-policy       Format Rego policies"
	@echo "  make fmt-check        Check formatting without modifying files"
	@echo ""
	@echo "  make policy-check     Check Rego policies"
	@echo "  make lint-policy      Lint Rego policies with Regal"
	@echo "  make check            Run all validation checks"
	@echo ""
	@echo "  make verify           Verify installed tools"
	@echo "  make clean            Remove build artifacts"
	@echo ""