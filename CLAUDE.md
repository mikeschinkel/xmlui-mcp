# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is the xmlui-mcp (Model Context Protocol) server, a Go-based MCP server that provides AI agents with tools to interact with XMLUI documentation and source code. The server enables AI assistants to help developers build XMLUI applications by providing access to component documentation, source code search, and usage examples.

## Build and Development Commands

**Using Makefile (recommended):**
```bash
make build              # Build for current platform
make build-all          # Build for all supported platforms
make install            # Build and prepare binary
make run                # Build and run in HTTP test mode
make dist               # Create distribution packages
make clean              # Remove build artifacts
make help               # Show all available targets
```

**Direct Go commands:**
```bash
go build -o bin/xmlui-mcp
# or use the provided script:
./scripts/build.sh
```

**Prepare binary for distribution (Mac/Linux):**
```bash
./scripts/prepare-binary.sh
# or use:
make prepare
```

**Run the server:**
```bash
# Stdio mode (default for MCP clients):
./xmlui-mcp <xmluiDir> [exampleRoot] [comma-separated-exampleDirs]

# HTTP mode (for testing):
./xmlui-mcp --http [--port 8080] <xmluiDir> [exampleRoot] [comma-separated-exampleDirs]
```

**View analytics:**
```bash
# Using Makefile:
make analytics           # Overall usage statistics
make analytics-tools     # Tool usage analysis  
make analytics-searches  # Search query analysis

# Using script directly:
./scripts/analytics-helper.sh summary    # Overall usage statistics
./scripts/analytics-helper.sh tools      # Tool usage analysis  
./scripts/analytics-helper.sh searches   # Search query analysis
```

**Test HTTP endpoints:**
```bash
curl http://localhost:8080/tools                    # List available tools
curl http://localhost:8080/prompts                  # List available prompts
curl http://localhost:8080/analytics/summary        # View analytics
```

## Architecture

### Core Components

- **main.go**: Entry point that sets up the MCP server, registers tools/prompts, and handles both stdio and HTTP modes
- **server/**: Contains all MCP tool implementations:
  - `component_docs.go` - XMLUI component documentation retrieval
  - `list_components.go` - Lists available XMLUI components
  - `search.go` - Searches XMLUI source and documentation files
  - `read_file.go` - Reads specific files from XMLUI directories
  - `examples.go` - Searches example applications for usage patterns
  - `howto.go` - Searches "How To" documentation
  - `analytics.go` - Usage tracking and analytics
  - `analytics_wrapper.go` - Analytics decorators for tools

### Key Features

1. **Dual Mode Operation**: Supports both stdio (for MCP clients) and HTTP (for testing/development)
2. **Analytics**: Comprehensive usage tracking with JSON output and analysis scripts
3. **Session Management**: Context injection for maintaining agent state across interactions
4. **File System Integration**: Direct access to XMLUI documentation and source trees

### MCP Tools Provided

- `xmlui_list_components` - Lists all available XMLUI components
- `xmlui_component_docs` - Returns component documentation
- `xmlui_search` - Searches XMLUI source and docs
- `xmlui_read_file` - Reads specific files
- `xmlui_examples` - Searches example applications
- `xmlui_list_howto` - Lists "How To" entries
- `xmlui_search_howto` - Searches "How To" documentation
- `xmlui_inject_prompt` - Injects guidance prompts into session context
- `xmlui_list_prompts` - Lists available prompts
- `xmlui_get_prompt` - Retrieves prompt content

### XMLUI Development Rules

The server includes an embedded `xmlui_rules` prompt with essential XMLUI development guidelines:

1. Always preview code changes and get approval before writing
2. Don't add custom XMLUI styling - use the theme engine
3. Work in small increments with minimal markup
4. Only use documented XMLUI syntax with cited sources
5. Never manipulate DOM directly - work within XMLUI abstractions
6. Keep complex logic in index.html or code-behind, not in XMLUI markup
7. Use MCP tools to search XMLUI resources first
8. Always choose the simplest approach
9. Use neutral tone without exclamation marks
10. Follow playground conventions for ---app and ---comp
11. VStack is default - don't specify unless necessary
12. Prioritize XMLUI resources over external sources

## Dependencies

- Go 1.23.5+
- `github.com/mark3labs/mcp-go` - MCP protocol implementation
- `github.com/chzyer/readline` - Interactive command line

## File Structure Requirements

The server expects this directory structure for XMLUI resources:
- `$HOME/xmlui/docs/content/components/` - Component documentation (.md files)
- `$HOME/xmlui/docs/public/pages/` - General documentation
- `$HOME/xmlui/xmlui/src/components/` - Source code (.tsx, .scss files)

## Testing

No formal test suite exists. Testing is done via:
1. HTTP mode endpoints for tool validation
2. Analytics output verification
3. Integration testing with MCP clients (Claude Desktop, Cursor, etc.)