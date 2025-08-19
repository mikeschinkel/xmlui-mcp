# xmlui-mcp Makefile
# Model Context Protocol server for XMLUI development

# Variables
BINARY_NAME := xmlui-mcp
BIN_DIR := bin
DIST_DIR := dist
ANALYTICS_FILE := xmlui-mcp-analytics.json

# Default target
.DEFAULT_GOAL := help

# Help target
.PHONY: help
help: ## Show this help message
	@echo "xmlui-mcp - Model Context Protocol server for XMLUI"
	@echo ""
	@echo "Usage: make [target]"
	@echo ""
	@echo "Available targets:"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-15s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

# Build targets
.PHONY: build
build: ## Build the binary for current platform
	@./scripts/build.sh

.PHONY: build-all
build-all: ## Build binaries for all supported platforms
	@./scripts/build-all.sh

# Individual platform builds (for specific platform needs)
.PHONY: build-linux-amd64
build-linux-amd64: ## Build for Linux AMD64
	@./scripts/build.sh linux amd64 $(DIST_DIR)/linux-amd64

.PHONY: build-linux-arm64
build-linux-arm64: ## Build for Linux ARM64
	@./scripts/build.sh linux arm64 $(DIST_DIR)/linux-arm64

.PHONY: build-darwin-amd64
build-darwin-amd64: ## Build for macOS Intel
	@./scripts/build.sh darwin amd64 $(DIST_DIR)/darwin-amd64

.PHONY: build-darwin-arm64
build-darwin-arm64: ## Build for macOS Apple Silicon
	@./scripts/build.sh darwin arm64 $(DIST_DIR)/darwin-arm64

.PHONY: build-windows-amd64
build-windows-amd64: ## Build for Windows AMD64
	@./scripts/build.sh windows amd64 $(DIST_DIR)/windows-amd64

# Development targets
.PHONY: run
run: build ## Build and run the server in HTTP mode for testing
	@echo "Starting $(BINARY_NAME) in HTTP mode on port 8080..."
	@echo "Test with: curl http://localhost:8080/tools"
	$(BIN_DIR)/$(BINARY_NAME) --http --port 8080 $(HOME)/xmlui $(HOME) xmlui-examples || echo "Note: Adjust paths as needed for your setup"

.PHONY: test
test: ## Run tests (currently validates HTTP mode startup)
	@echo "Running validation tests..."
	go mod verify
	go vet ./...
	@echo "✓ Basic validation complete"
	@echo "For integration testing, use 'make run' and test HTTP endpoints"

.PHONY: deps
deps: ## Download and verify dependencies
	@echo "Downloading dependencies..."
	go mod download
	go mod verify
	@echo "✓ Dependencies updated"

.PHONY: tidy
tidy: ## Clean up go.mod and go.sum
	@echo "Tidying Go modules..."
	go mod tidy
	@echo "✓ Go modules tidied"

# Installation
.PHONY: install
install: ## Complete installation: clone repos, build, configure MCP clients
	@echo "Installing XMLUI MCP environment..."
	@./scripts/install.sh

# Analytics targets
.PHONY: analytics
analytics: ## Show analytics summary
	@if [ -f "$(ANALYTICS_FILE)" ]; then \
		./scripts/analytics-helper.sh summary; \
	else \
		echo "No analytics file found. Analytics will be created after agents start using the server."; \
	fi

.PHONY: analytics-tools
analytics-tools: ## Show tool usage statistics
	@./scripts/analytics-helper.sh tools

.PHONY: analytics-searches
analytics-searches: ## Show search query analysis
	@./scripts/analytics-helper.sh searches

.PHONY: analytics-clean
analytics-clean: ## Remove analytics file
	@if [ -f "$(ANALYTICS_FILE)" ]; then \
		rm $(ANALYTICS_FILE); \
		echo "✓ Analytics file removed"; \
	else \
		echo "No analytics file to remove"; \
	fi

# Distribution targets
.PHONY: dist
dist: build-all ## Create distribution packages for all platforms
	@./scripts/dist.sh

# Cleanup targets
.PHONY: clean
clean: ## Remove build artifacts
	@echo "Cleaning build artifacts..."
	rm -rf $(BIN_DIR)
	@echo "✓ Build artifacts cleaned"

.PHONY: clean-dist
clean-dist: ## Remove distribution artifacts
	@echo "Cleaning distribution artifacts..."
	rm -rf $(DIST_DIR)
	@echo "✓ Distribution artifacts cleaned"

.PHONY: clean-all
clean-all: clean clean-dist analytics-clean ## Remove all generated files
	@echo "✓ All artifacts cleaned"


# Development utilities
.PHONY: version
version: ## Show version information
	@echo "Version: $(VERSION)"
	@echo "Commit:  $(COMMIT)"
	@echo "Built:   $(BUILD_TIME)"

.PHONY: info
info: ## Show project information
	@echo "Project: xmlui-mcp"
	@echo "Package: $(PACKAGE)"
	@echo "Binary:  $(BINARY_NAME)"
	@echo "Go version: $$(go version)"
	@echo "Git status: $$(git status --porcelain | wc -l | tr -d ' ') files changed"

# Check if required tools are installed
.PHONY: check-deps
check-deps: ## Check if required tools are installed
	@echo "Checking dependencies..."
	@which go > /dev/null || (echo "❌ Go not installed" && exit 1)
	@which git > /dev/null || echo "⚠️  Git not installed (optional)"
	@which jq > /dev/null || echo "⚠️  jq not installed (analytics formatting will be limited)"
	@echo "✓ Dependencies check complete"