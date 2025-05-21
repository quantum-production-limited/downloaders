#!/bin/bash
set -e

# Colors for terminal output
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;36m'
NC='\033[0m' # No Color

echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}          QPulse Download Script          ${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# Repository information
REPO="quantum-production-limited/QuantumPulse"

# Detect OS type
OS_TYPE="unknown"
if [[ "$OSTYPE" == "darwin"* ]]; then
    OS_TYPE="macos"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS_TYPE="linux"
fi

# Check for required commands
check_command() {
    if ! command -v "$1" &> /dev/null; then
        echo -e "${RED}Error: Required command '$1' not found.${NC}"
        echo "Please install it using your system's package manager."
        
        if [ "$OS_TYPE" == "macos" ]; then
            echo "For macOS: brew install $2"
        else
            echo "For Debian/Ubuntu: sudo apt-get install $2"
            echo "For Fedora/RHEL: sudo dnf install $2"
            echo "For Arch: sudo pacman -S $2"
        fi
        exit 1
    fi
}

check_command curl curl
check_command jq jq
check_command tar tar

# Determine appropriate user home directory
if [ $(id -u) -eq 0 ]; then
    # Script is running as root, use sudo user's home if SUDO_USER is set
    if [ ! -z "$SUDO_USER" ]; then
        if [ "$OS_TYPE" == "macos" ]; then
            USER_HOME=$(dscl . -read /Users/$SUDO_USER NFSHomeDirectory | awk '{print $2}')
        else
            USER_HOME=$(eval echo ~${SUDO_USER})
        fi
    else
        # Default to current user (root) if SUDO_USER is not set
        USER_HOME=$HOME
    fi
else
    # Script is running as non-root
    USER_HOME=$HOME
fi

OUTPUT_DIR="$USER_HOME/.qpulse"
TOKEN=""
VERSION=""

# Parse command line arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --token=*)
            TOKEN="${1#*=}"
            shift
            ;;
        --version=*)
            VERSION="${1#*=}"
            shift
            ;;
        --token)
            TOKEN="$2"
            shift 2
            ;;
        --version)
            VERSION="$2"
            shift 2
            ;;
        --help|-h)
            echo "Usage: $0 [OPTIONS]"
            echo "Options:"
            echo "  --token=TOKEN, --token TOKEN    GitHub personal access token with appropriate permissions"
            echo "  --version=VERSION, --version VERSION    Version to download (required)"
            echo "  --help, -h                      Show this help message"
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Check if token is provided
if [ -z "$TOKEN" ]; then
    echo -e "${RED}Error: GitHub token is required${NC}"
    echo "Please provide a GitHub personal access token with the --token option"
    echo "You can create a token at: https://github.com/settings/tokens"
    echo -e "${YELLOW}Note: This script requires a token with repository content read access${NC}"
    exit 1
fi

# Check if version is provided
if [ -z "$VERSION" ]; then
    echo -e "${RED}Error: Version is required${NC}"
    echo "Please provide a specific version to download with the --version option"
    echo "Example: $0 --token=your_token --version=0.4.6"
    exit 1
fi

ASSET_NAME="qpulse-docker-$VERSION.tar.gz"
TEMP_RESPONSE="/tmp/github_api_response.json"

echo -e "Setting up ${BLUE}QPulse v$VERSION${NC} in ${BLUE}$OUTPUT_DIR${NC}"

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Validate token has sufficient permissions to access the repository
echo "Validating token permissions..."
REPO_CHECK=$(curl -s -o /dev/null -w "%{http_code}" -H "Authorization: token $TOKEN" \
    "https://api.github.com/repos/$REPO")

if [ "$REPO_CHECK" != "200" ]; then
    echo -e "${RED}Error: Unable to access repository $REPO${NC}"
    echo "Please verify:"
    echo "1. Your token has appropriate repository access permissions"
    echo "2. The repository name is correct"
    echo "3. Your token hasn't expired"
    exit 1
fi

# Step 1: Get the release information
echo -e "Looking up version ${BLUE}$VERSION${NC}..."
curl -s -H "Authorization: token $TOKEN" \
     -H "Accept: application/vnd.github.v3+json" \
     "https://api.github.com/repos/$REPO/releases/tags/v$VERSION" > $TEMP_RESPONSE

# Check if release exists
if grep -q "Not Found" $TEMP_RESPONSE; then
    echo -e "${RED}Error: Release v$VERSION not found${NC}"
    
    # List available releases
    echo "Available releases:"
    RELEASES=$(curl -s -H "Authorization: token $TOKEN" \
        "https://api.github.com/repos/$REPO/releases" | grep -o '"tag_name": "v[^"]*"' | sed 's/"tag_name": "v\(.*\)"/\1/')
    
    if [ -n "$RELEASES" ]; then
        echo "$RELEASES"
    else
        echo "No releases found or insufficient permissions to list releases"
    fi
    exit 1
fi

# Step 2: Find the asset download URL and size
echo "Locating the asset you're looking for..."
ASSET_INFO=$(jq -r ".assets[] | select(.name == \"$ASSET_NAME\") | {url: .url, size: .size}" $TEMP_RESPONSE)
ASSET_URL=$(echo "$ASSET_INFO" | jq -r ".url")
ASSET_SIZE=$(echo "$ASSET_INFO" | jq -r ".size")

if [ -z "$ASSET_URL" ]; then
    echo -e "${YELLOW}Warning: Asset $ASSET_NAME not found in release v$VERSION${NC}"
    echo "Available assets:"
    jq -r '.assets[].name' $TEMP_RESPONSE
    exit 1
fi

# Calculate size in MB for display - use portable calculation method
if command -v bc &> /dev/null; then
    SIZE_MB=$(echo "scale=2; $ASSET_SIZE / 1048576" | bc)
else
    # Fallback if bc is not available
    SIZE_MB=$(awk "BEGIN {printf \"%.2f\", $ASSET_SIZE/1048576}")
fi

# Step 3: Download the asset with progress tracking
echo -e "Downloading ${BLUE}$ASSET_NAME${NC} (${BLUE}${SIZE_MB} MB${NC}) from ${BLUE}${REPO}${NC}..."
curl -L -o "$OUTPUT_DIR/$ASSET_NAME" \
     -H "Accept: application/octet-stream" \
     -H "Authorization: token $TOKEN" \
     --progress-bar \
     "$ASSET_URL"

# Check if download was successful
if [ ! -f "$OUTPUT_DIR/$ASSET_NAME" ] || [ ! -s "$OUTPUT_DIR/$ASSET_NAME" ]; then
    echo -e "${RED}Error: Failed to download $ASSET_NAME${NC}"
    exit 1
fi

# Verify download size - use cross-platform method for file size
if [ "$OS_TYPE" == "macos" ]; then
    # macOS uses BSD stat
    DOWNLOADED_SIZE=$(stat -f%z "$OUTPUT_DIR/$ASSET_NAME")
else
    # Try GNU stat first, fall back to BSD stat, then ls as last resort
    if stat --version &> /dev/null 2>&1; then
        # GNU stat
        DOWNLOADED_SIZE=$(stat -c%s "$OUTPUT_DIR/$ASSET_NAME")
    elif stat -f%z /dev/null &> /dev/null 2>&1; then
        # BSD stat on some Linux systems
        DOWNLOADED_SIZE=$(stat -f%z "$OUTPUT_DIR/$ASSET_NAME")
    else
        # Fallback method using ls
        DOWNLOADED_SIZE=$(ls -l "$OUTPUT_DIR/$ASSET_NAME" | awk '{print $5}')
    fi
fi

# Calculate size in MB with fallback method
if command -v bc &> /dev/null; then
    DOWNLOADED_SIZE_MB=$(echo "scale=2; $DOWNLOADED_SIZE / 1048576" | bc)
else
    DOWNLOADED_SIZE_MB=$(awk "BEGIN {printf \"%.2f\", $DOWNLOADED_SIZE/1048576}")
fi

echo -e "Download complete. File size: ${BLUE}${DOWNLOADED_SIZE_MB} MB${NC}"

# Check file type - with fallback if file command is missing
if command -v file &> /dev/null; then
    echo "Examining downloaded file..."
    FILE_TYPE=$(file -b "$OUTPUT_DIR/$ASSET_NAME")

    if [[ ! "$FILE_TYPE" =~ "gzip" ]] && [[ ! "$FILE_TYPE" =~ "compressed data" ]]; then
        # Check if it's actually a JSON error response
        if grep -q "message" "$OUTPUT_DIR/$ASSET_NAME"; then
            echo -e "${RED}Error: GitHub API returned an error:${NC}"
            cat "$OUTPUT_DIR/$ASSET_NAME"
            rm -f "$OUTPUT_DIR/$ASSET_NAME"
            exit 1
        fi
        
        echo -e "${YELLOW}Warning: Downloaded file does not appear to be in gzip format${NC}"
        echo "Continuing extraction anyway..."
    fi
fi

# Remove existing 'images' directory if it exists so that old images do not load during installation.
if [ -d "$OUTPUT_DIR/images" ]; then
    rm -rf "$OUTPUT_DIR/images"
fi

# Extract the tarball
echo "Extracting files..."
tar -xzf "$OUTPUT_DIR/$ASSET_NAME" -C "$OUTPUT_DIR"

# Check extraction status
if [ $? -eq 0 ]; then    
    # Make install.sh executable if it exists
    INSTALL_SCRIPT="$OUTPUT_DIR/install.sh"
    if [ -f "$INSTALL_SCRIPT" ]; then
        chmod +x "$INSTALL_SCRIPT"
    else
        echo -e "${YELLOW}Warning: install.sh not found in the extracted files.${NC}"
        
        # Try to find install.sh recursively - ensure compatible with macOS find
        if [ "$OS_TYPE" == "macos" ]; then
            FOUND_INSTALL_SCRIPT=$(find "$OUTPUT_DIR" -name "install.sh" -type f | head -1)
        else
            FOUND_INSTALL_SCRIPT=$(find "$OUTPUT_DIR" -name "install.sh" | head -1)
        fi
        
        if [ -n "$FOUND_INSTALL_SCRIPT" ]; then
            echo -e "${GREEN}Found install script at: $FOUND_INSTALL_SCRIPT${NC}"
            chmod +x "$FOUND_INSTALL_SCRIPT"
        fi
    fi
    
    # Remove the original tar.gz file
    rm -f "$OUTPUT_DIR/$ASSET_NAME"
    
    echo -e "${GREEN}QPulse v$VERSION has been downloaded and prepared for installation.${NC}"
    if [ -f "$INSTALL_SCRIPT" ]; then
        if [ "$OS_TYPE" == "macos" ]; then
            echo -e "To install QPulse, run: ${BLUE}cd $OUTPUT_DIR && sudo ./install.sh --help${NC}"
            echo -e "${YELLOW}Note: You may need to allow the executable in macOS security settings${NC}"
        else
            echo -e "To install QPulse, run: ${BLUE}cd $OUTPUT_DIR && sudo ./install.sh --help${NC}"
        fi
    elif [ -n "$FOUND_INSTALL_SCRIPT" ]; then
        if [ "$OS_TYPE" == "macos" ]; then
            echo -e "To install QPulse, run: ${BLUE}sudo $FOUND_INSTALL_SCRIPT --help${NC}"
            echo -e "${YELLOW}Note: You may need to allow the executable in macOS security settings${NC}"
        else
            echo -e "To install QPulse, run: ${BLUE}sudo $FOUND_INSTALL_SCRIPT --help${NC}"
        fi
    fi
else
    echo -e "${RED}Error: Failed to extract the archive.${NC}"
    echo "The file may be corrupt or in an unexpected format."
    exit 1
fi

# Clean up temp file
rm -f $TEMP_RESPONSE

echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo

