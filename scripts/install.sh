#!/bin/bash

# XMLUI MCP Initialization Script
# Clones the XMLUI repository and sets up the required directory structure

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default XMLUI directory
DEFAULT_XMLUI_DIR="$HOME/xmlui"
XMLUI_REPO="https://github.com/xmlui-org/xmlui.git"

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Global variable for new directory path
NEW_XMLUI_DIR=""

# Global variable for manual configuration mode
MANUAL_CONFIG_MODE=false

# Function to prompt user for choice when directory exists
handle_existing_directory() {
    local dir_path="$1"

    echo
    print_warning "Directory $dir_path already exists!"
    echo
    echo "What would you like to do?"
    echo "1) Overwrite the existing directory (will delete current contents)"
    echo "2) Use a different location"
    echo "3) Skip this step (assume directory is correctly set up)"
    echo "4) Stop initialization"
    echo

    while true; do
        read -r -p "Enter your choice (1-4): " choice
        case $choice in
            1)
                print_status "Removing existing directory..."
                rm -rf "$dir_path"
                return 0
                ;;
            2)
                while true; do
                    read -r -p "Enter new path for XMLUI directory: " new_path
                    # Expand tilde to home directory
                    new_path="${new_path/#\~/$HOME}"
                    
                    if [ -d "$new_path" ]; then
                        print_warning "Directory $new_path also exists!"
                        read -r -p "Use this directory anyway? (y/n): " use_existing
                        if [[ $use_existing =~ ^[Yy]$ ]]; then
                            NEW_XMLUI_DIR="$new_path"
                            return 2
                        fi
                    else
                        NEW_XMLUI_DIR="$new_path"
                        return 0
                    fi
                done
                ;;
            3)
                return 1
                ;;
            4)
                print_status "Initialization cancelled."
                exit 0
                ;;
            *)
                echo "Invalid choice. Please enter 1, 2, 3, or 4."
                ;;
        esac
    done
}

# Function to verify required directory structure
verify_structure() {
    local xmlui_dir="$1"
    local required_dirs=(
        "$xmlui_dir/docs/content/components"
        "$xmlui_dir/docs/public/pages"
        "$xmlui_dir/xmlui/src/components"
    )
    
    print_status "Verifying directory structure..."
    
    for dir in "${required_dirs[@]}"; do
        if [ ! -d "$dir" ]; then
            print_error "Required directory not found: $dir"
            return 1
        fi
    done
    
    print_success "All required directories found!"
    return 0
}

# Function to check and handle jq dependency
ensure_jq_available() {
    # Check if jq is already available
    if command -v jq &> /dev/null; then
        return 0
    fi
    
    print_warning "jq is required for JSON configuration but is not installed."
    echo
    echo "What would you like to do?"
    echo "1) Install jq using your system package manager"
    echo "2) Download jq temporarily for this setup only"
    echo "3) Skip automatic configuration (manual setup required)"
    echo
    
    while true; do
        read -r -p "Enter your choice (1-3): " jq_choice
        case $jq_choice in
            1)
                if install_jq_system; then
                    return 0
                else
                    print_error "Failed to install jq via package manager."
                    echo "Would you like to try option 2 (temporary download)?"
                    read -r -p "(y/n): " try_temp
                    if [[ $try_temp =~ ^[Yy]$ ]]; then
                        if install_jq_local; then
                            return 0
                        fi
                    fi
                    manual_config_exit
                    return 1
                fi
                ;;
            2)
                if install_jq_local; then
                    return 0
                else
                    print_error "Failed to download jq locally."
                    manual_config_exit
                    return 1
                fi
                ;;
            3)
                manual_config_exit
                return 1
                ;;
            *)
                echo "Invalid choice. Please enter 1, 2, or 3."
                ;;
        esac
    done
}

# Function to detect and install jq via package manager
install_jq_system() {
    print_status "Detecting package manager..."
    
    if command -v brew &> /dev/null; then
        print_status "Found Homebrew. Installing jq..."
        if brew install jq; then
            print_success "jq installed successfully via Homebrew!"
            return 0
        fi
    elif command -v apt-get &> /dev/null; then
        print_status "Found APT. Installing jq..."
        if sudo apt-get update && sudo apt-get install -y jq; then
            print_success "jq installed successfully via APT!"
            return 0
        fi
    elif command -v yum &> /dev/null; then
        print_status "Found YUM. Installing jq..."
        if sudo yum install -y jq; then
            print_success "jq installed successfully via YUM!"
            return 0
        fi
    elif command -v dnf &> /dev/null; then
        print_status "Found DNF. Installing jq..."
        if sudo dnf install -y jq; then
            print_success "jq installed successfully via DNF!"
            return 0
        fi
    elif command -v pacman &> /dev/null; then
        print_status "Found Pacman. Installing jq..."
        if sudo pacman -S --noconfirm jq; then
            print_success "jq installed successfully via Pacman!"
            return 0
        fi
    else
        print_error "No supported package manager found (brew, apt, yum, dnf, pacman)."
        return 1
    fi
    
    return 1
}

# Function to download jq locally
install_jq_local() {
    print_status "Downloading jq for temporary use..."
    
    # Create bin directory if it doesn't exist
    mkdir -p bin
    
    # Detect system architecture
    local os_type
    local arch_type
    local jq_url
    
    case "$(uname -s)" in
        Darwin)
            os_type="osx"
            case "$(uname -m)" in
                x86_64) arch_type="amd64" ;;
                arm64) arch_type="arm64" ;;
                *) arch_type="amd64" ;;
            esac
            ;;
        Linux)
            os_type="linux"
            case "$(uname -m)" in
                x86_64) arch_type="amd64" ;;
                aarch64) arch_type="arm64" ;;
                *) arch_type="amd64" ;;
            esac
            ;;
        *)
            print_error "Unsupported operating system for automatic jq download."
            return 1
            ;;
    esac
    
    if [ "$os_type" = "osx" ]; then
        jq_url="https://github.com/jqlang/jq/releases/latest/download/jq-macos-$arch_type"
    else
        jq_url="https://github.com/jqlang/jq/releases/latest/download/jq-linux-$arch_type"
    fi
    
    print_status "Downloading from: $jq_url"
    
    # Download jq
    if command -v curl &> /dev/null; then
        if curl -L -o bin/jq "$jq_url"; then
            chmod +x bin/jq
            print_success "jq downloaded successfully to ./bin/jq"
            # Update PATH for this session
            export PATH="$(pwd)/bin:$PATH"
            return 0
        fi
    elif command -v wget &> /dev/null; then
        if wget -O bin/jq "$jq_url"; then
            chmod +x bin/jq
            print_success "jq downloaded successfully to ./bin/jq"
            # Update PATH for this session
            export PATH="$(pwd)/bin:$PATH"
            return 0
        fi
    else
        print_error "Neither curl nor wget found. Cannot download jq."
        return 1
    fi
    
    return 1
}

# Function to exit gracefully with manual config instructions
manual_config_exit() {
    echo
    print_status "No problem! You can configure your MCP client manually."
    echo
    echo "Documentation and setup guides are available at:"
    echo "https://docs.anthropic.com/en/docs/build-with-claude/computer-use"
    echo
    echo "We'll still create a configuration file with the settings you need."
    
    # Set global flag to indicate manual mode
    MANUAL_CONFIG_MODE=true
}

# Function to build the MCP server
build_mcp_server() {
    print_status "Preparing Go dependencies..."
    
    # Ensure dependencies are available
    if command -v go &> /dev/null; then
        if go mod tidy && go mod download; then
            print_success "Dependencies prepared successfully!"
        else
            print_error "Failed to prepare dependencies."
            return 1
        fi
    else
        print_error "Go command not found. Please install Go and try again."
        return 1
    fi
    
    print_status "Building the MCP server..."
    
    # Check if make is available
    if command -v make &> /dev/null; then
        if make build; then
            print_success "MCP server built successfully!"
            return 0
        else
            print_warning "Make build failed, trying direct Go build..."
        fi
    fi
    
    # Fallback to direct go build
    if go build -o bin/xmlui-mcp; then
        print_success "MCP server built successfully with Go!"
        return 0
    else
        print_error "Failed to build MCP server with Go."
        return 1
    fi
}

# Function to get example directories from user
get_example_directories() {
    echo
    print_status "Setting up example directories..."
    echo "The MCP server can help find examples in your XMLUI projects."
    echo "You can specify directories where your XMLUI example projects are located."
    echo
    
    local example_root="$HOME"
    local example_dirs=""
    
    read -r -p "Enter the root directory for your XMLUI projects (default: $HOME): " user_root
    if [ -n "$user_root" ]; then
        # Expand tilde to home directory
        example_root="${user_root/#\~/$HOME}"
    fi
    
    echo
    # Show available directories in the root path
    if [ -d "$example_root" ]; then
        local available_dirs=""
        while IFS= read -r -d '' dir; do
            local basename
            basename=$(basename "$dir")
            if [ -n "$available_dirs" ]; then
                available_dirs="$available_dirs, $basename"
            else
                available_dirs="$basename"
            fi
        done < <(find "$example_root" -maxdepth 1 -type d ! -path "$example_root" -print0 2>/dev/null | head -20)
        
        if [ -n "$available_dirs" ]; then
            echo "Available directories in $example_root:"
            echo "$available_dirs"
            echo
        fi
    fi
    
    echo "Enter example directory names (comma-separated, e.g., 'xmlui-examples,my-xmlui-projects'):"
    read -r -p "Example directories (default: xmlui-examples): " user_dirs
    if [ -n "$user_dirs" ]; then
        example_dirs="$user_dirs"
    else
        example_dirs="xmlui-examples"
    fi
    
    echo "$example_root|$example_dirs"
}

# Function to detect MCP clients and configure them
configure_mcp_clients() {
    local xmlui_dir="$1"
    local example_root="$2"
    local example_dirs="$3"
    local binary_path
    binary_path="$(pwd)/bin/xmlui-mcp"
    
    # If in manual mode, just create the config file and skip interactive config
    if [ "$MANUAL_CONFIG_MODE" = "true" ]; then
        print_status "Creating manual configuration file..."
        create_config_note "$xmlui_dir" "$example_root" "$example_dirs" "$binary_path"
        return 0
    fi
    
    print_status "Configuring MCP clients..."
    
    local configured_any=false
    
    # Claude Desktop configuration
    local claude_config="$HOME/Library/Application Support/Claude/claude_desktop_config.json"
    if [ -f "$claude_config" ] || [ -d "$(dirname "$claude_config")" ]; then
        echo
        print_status "Found Claude Desktop installation."
        read -r -p "Configure Claude Desktop? (y/n): " configure_claude
        if [[ $configure_claude =~ ^[Yy]$ ]]; then
            configure_claude_desktop "$claude_config" "$xmlui_dir" "$example_root" "$example_dirs" "$binary_path"
            configured_any=true
        fi
    fi
    
    # Cursor configuration
    local cursor_config="$HOME/.cursor.mcp.json"
    if command -v cursor &> /dev/null || [ -d "/Applications/Cursor.app" ]; then
        echo
        print_status "Found Cursor installation."
        read -r -p "Configure Cursor? (y/n): " configure_cursor
        if [[ $configure_cursor =~ ^[Yy]$ ]]; then
            configure_cursor_mcp "$cursor_config" "$xmlui_dir" "$example_root" "$example_dirs" "$binary_path"
            configured_any=true
        fi
    fi
    
    # VS Code configuration
    local vscode_config="$HOME/Library/Application Support/Code/User/mcp.json"
    if command -v code &> /dev/null || [ -d "/Applications/Visual Studio Code.app" ]; then
        echo
        print_status "Found VS Code installation."
        read -r -p "Configure VS Code Copilot? (y/n): " configure_vscode
        if [[ $configure_vscode =~ ^[Yy]$ ]]; then
            configure_vscode_mcp "$vscode_config" "$xmlui_dir" "$example_root" "$example_dirs" "$binary_path"
            configured_any=true
        fi
    fi
    
    if [ "$configured_any" = false ]; then
        echo
        print_warning "No MCP clients were configured automatically."
        create_config_note "$xmlui_dir" "$example_root" "$example_dirs" "$binary_path"
    fi
}

# Function to configure Claude Desktop
configure_claude_desktop() {
    local config_file="$1"
    local xmlui_dir="$2"
    local example_root="$3"
    local example_dirs="$4"
    local binary_path="$5"
    
    # Double-check that jq is available
    if ! command -v jq &> /dev/null; then
        print_error "jq is not available. Cannot update JSON configuration."
        return 1
    fi
    
    # Create directory if it doesn't exist
    mkdir -p "$(dirname "$config_file")"
    
    # Create or update config
    local temp_config
    temp_config=$(mktemp)
    
    if [ -f "$config_file" ]; then
        # Parse existing config and add/update xmlui server
        jq --arg cmd "$binary_path" --arg xmlui "$xmlui_dir" --arg root "$example_root" --arg dirs "$example_dirs" '
            .mcpServers.xmlui = {
                "command": $cmd,
                "args": [$xmlui, $root, $dirs]
            }
        ' < "$config_file" > "$temp_config"
    else
        # Create new config
        cat > "$temp_config" << EOF
{
  "mcpServers": {
    "xmlui": {
      "command": "$binary_path",
      "args": [
        "$xmlui_dir",
        "$example_root",
        "$example_dirs"
      ]
    }
  }
}
EOF
    fi
    
    mv "$temp_config" "$config_file"
    print_success "Claude Desktop configured successfully!"
}

# Function to configure Cursor
configure_cursor_mcp() {
    local config_file="$1"
    local xmlui_dir="$2"
    local example_root="$3"
    local example_dirs="$4"
    local binary_path="$5"
    
    # Double-check that jq is available
    if ! command -v jq &> /dev/null; then
        print_error "jq is not available. Cannot update JSON configuration."
        return 1
    fi
    
    local temp_config
    temp_config=$(mktemp)
    
    if [ -f "$config_file" ]; then
        # Parse existing config and add/update xmlui server
        jq --arg cmd "$binary_path" --arg xmlui "$xmlui_dir" --arg root "$example_root" --arg dirs "$example_dirs" '
            .mcpServers.xmlui = {
                "command": $cmd,
                "args": [$xmlui, $root, $dirs]
            }
        ' < "$config_file" > "$temp_config"
    else
        # Create new config
        cat > "$temp_config" << EOF
{
  "mcpServers": {
    "xmlui": {
      "command": "$binary_path",
      "args": [
        "$xmlui_dir",
        "$example_root",
        "$example_dirs"
      ]
    }
  }
}
EOF
    fi
    
    mv "$temp_config" "$config_file"
    print_success "Cursor configured successfully!"
}

# Function to configure VS Code
configure_vscode_mcp() {
    local config_file="$1"
    local xmlui_dir="$2"
    local example_root="$3"
    local example_dirs="$4"
    local binary_path="$5"
    
    # Double-check that jq is available
    if ! command -v jq &> /dev/null; then
        print_error "jq is not available. Cannot update JSON configuration."
        return 1
    fi
    
    # Create directory if it doesn't exist
    mkdir -p "$(dirname "$config_file")"
    
    local temp_config
    temp_config=$(mktemp)
    
    if [ -f "$config_file" ]; then
        # Parse existing config and add/update xmlui server
        jq --arg cmd "$binary_path" --arg xmlui "$xmlui_dir" --arg root "$example_root" --arg dirs "$example_dirs" '
            .mcpServers.xmlui = {
                "command": $cmd,
                "args": [$xmlui, $root, $dirs]
            }
        ' < "$config_file" > "$temp_config"
    else
        # Create new config
        cat > "$temp_config" << EOF
{
  "mcpServers": {
    "xmlui": {
      "command": "$binary_path",
      "args": [
        "$xmlui_dir",
        "$example_root",
        "$example_dirs"
      ]
    }
  }
}
EOF
    fi
    
    mv "$temp_config" "$config_file"
    print_success "VS Code configured successfully!"
}

# Function to create configuration note as backup
create_config_note() {
    local xmlui_dir="$1"
    local example_root="$2"
    local example_dirs="$3" 
    local binary_path="$4"
    local config_file="xmlui-mcp-config.txt"
    
    cat > "$config_file" << EOF
XMLUI MCP Configuration
======================

XMLUI Directory: $xmlui_dir
Example Root: $example_root  
Example Directories: $example_dirs

For Claude Desktop, add this to ~/Library/Application Support/Claude/claude_desktop_config.json:

{
  "mcpServers": {
    "xmlui": {
      "command": "$binary_path",
      "args": [
        "$xmlui_dir",
        "$example_root",
        "$example_dirs"
      ]
    }
  }
}

For Cursor, add this to ~/.cursor.mcp.json:

{
  "mcpServers": {
    "xmlui": {
      "command": "$binary_path",
      "args": [
        "$xmlui_dir",
        "$example_root",
        "$example_dirs"
      ]
    }
  }
}

For VS Code Copilot, add this to ~/Library/Application Support/Code/User/mcp.json:

{
  "mcpServers": {
    "xmlui": {
      "command": "$binary_path",
      "args": [
        "$xmlui_dir",
        "$example_root",
        "$example_dirs"
      ]
    }
  }
}
EOF

    print_success "Configuration saved to $config_file"
}

# Function to test the setup
test_setup() {
    local xmlui_dir="$1"
    
    print_status "Testing the MCP server..."
    
    # Test that the binary exists and is executable
    if [ ! -x "bin/xmlui-mcp" ]; then
        print_error "MCP server binary not found or not executable."
        return 1
    fi
    
    # Test the server in HTTP mode briefly
    print_status "Starting server test..."
    
    # Start server in background
    timeout 10s ./bin/xmlui-mcp --http --port 8899 "$xmlui_dir" "$HOME" "xmlui-examples" > /dev/null 2>&1 &
    local server_pid=$!
    
    # Give it a moment to start
    sleep 2
    
    # Test if server responds
    if curl -s http://localhost:8899/tools > /dev/null 2>&1; then
        print_success "MCP server test passed!"
        kill $server_pid 2>/dev/null || true
        return 0
    else
        print_warning "MCP server test failed, but this might be normal."
        kill $server_pid 2>/dev/null || true
        return 0
    fi
}

# Main setup completion function
complete_setup() {
    local xmlui_dir="$1"
    
    echo
    print_status "Completing XMLUI MCP setup..."
    
    # Step 1: Build the server
    if ! build_mcp_server; then
        print_error "Failed to build MCP server. Setup incomplete."
        exit 1
    fi
    
    # Step 2: Get example directories from user
    local example_info
    example_info=$(get_example_directories)
    local example_root
    example_root=$(echo "$example_info" | cut -d'|' -f1)
    local example_dirs
    example_dirs=$(echo "$example_info" | cut -d'|' -f2)
    
    # Step 3: Configure MCP clients
    configure_mcp_clients "$xmlui_dir" "$example_root" "$example_dirs"
    
    # Step 4: Test the setup  
    test_setup "$xmlui_dir"
    
    echo
    print_success "XMLUI MCP initialization completed successfully!"
    echo
    if [ "$MANUAL_CONFIG_MODE" = "true" ]; then
        print_status "Your MCP server is built and ready!"
        echo "Please review the configuration file 'xmlui-mcp-config.txt' and manually"
        echo "add the configuration to your MCP client, then restart it."
    else
        print_status "Your MCP server is ready to use!"
        echo "Restart your MCP client (Claude Desktop, Cursor, etc.) to load the new configuration."
    fi
}

# Main initialization function
main() {
    print_status "Starting XMLUI MCP initialization..."
    
    # Check if git is available
    if ! command -v git &> /dev/null; then
        print_error "Git is required but not installed. Please install git and try again."
        exit 1
    fi
    
    # Check and ensure jq is available
    if ! ensure_jq_available; then
        # If we're in manual mode, we'll still continue but skip JSON config
        if [ "$MANUAL_CONFIG_MODE" != "true" ]; then
            exit 1
        fi
    fi
    
    xmlui_dir="$DEFAULT_XMLUI_DIR"
    
    # Handle existing directory
    if [ -d "$xmlui_dir" ]; then
        handle_existing_directory "$xmlui_dir"
        choice_result=$?
        
        case $choice_result in
            0)
                # Overwrite or new directory - check if we have a new path
                if [ -n "$NEW_XMLUI_DIR" ]; then
                    xmlui_dir="$NEW_XMLUI_DIR"
                fi
                ;;
            1)
                # Skip - assume directory is set up
                print_status "Skipping clone, using existing directory..."
                if verify_structure "$xmlui_dir"; then
                    create_config_note "$xmlui_dir"
                    print_success "Initialization completed!"
                    return 0
                else
                    print_error "Existing directory does not have the required structure."
                    exit 1
                fi
                ;;
            2)
                # New directory that also exists - use it as-is
                xmlui_dir="$NEW_XMLUI_DIR"
                print_status "Using existing directory at $xmlui_dir"
                if verify_structure "$xmlui_dir"; then
                    create_config_note "$xmlui_dir"
                    print_success "Initialization completed!"
                    return 0
                else
                    print_error "Directory does not have the required structure."
                    exit 1
                fi
                ;;
        esac
    fi
    
    # Create parent directory if needed
    parent_dir=$(dirname "$xmlui_dir")
    if [ ! -d "$parent_dir" ]; then
        print_status "Creating parent directory: $parent_dir"
        mkdir -p "$parent_dir"
    fi
    
    # Clone the repository
    print_status "Cloning XMLUI repository to $xmlui_dir..."
    if git clone "$XMLUI_REPO" "$xmlui_dir"; then
        print_success "Repository cloned successfully!"
    else
        print_error "Failed to clone repository."
        exit 1
    fi
    
    # Verify the structure
    if verify_structure "$xmlui_dir"; then
        print_success "Repository cloned and verified successfully!"
        complete_setup "$xmlui_dir"
    else
        print_error "Repository was cloned but does not have the expected structure."
        print_error "This might indicate a problem with the repository or network issues."
        exit 1
    fi
}

# Run main function
main "$@"