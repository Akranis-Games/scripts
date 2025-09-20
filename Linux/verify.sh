#!/bin/bash

# Installation Verification Script
# Verifies that the install.sh script is properly formatted and ready to use

set -e

SCRIPT_FILE="install.sh"
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}GTA V Server Installation Script Verification${NC}"
echo "=============================================="

# Check if script file exists
if [[ ! -f "$SCRIPT_FILE" ]]; then
    echo -e "${RED}❌ Error: $SCRIPT_FILE not found${NC}"
    exit 1
fi

echo -e "${GREEN}✓${NC} Script file exists"

# Check if script has proper shebang
if head -n 1 "$SCRIPT_FILE" | grep -q "#!/bin/bash"; then
    echo -e "${GREEN}✓${NC} Proper shebang found"
else
    echo -e "${RED}❌ Error: Missing or incorrect shebang${NC}"
    exit 1
fi

# Check if script is executable (on Unix systems)
if [[ -x "$SCRIPT_FILE" ]]; then
    echo -e "${GREEN}✓${NC} Script is executable"
else
    echo -e "${YELLOW}⚠${NC} Warning: Script is not executable"
    echo "  Run: chmod +x $SCRIPT_FILE"
fi

# Check for required functions
required_functions=(
    "detect_os"
    "install_ragemp"
    "install_altv"
    "install_fivem_txadmin"
    "show_main_menu"
    "server_management_menu"
)

echo
echo "Checking required functions..."

for func in "${required_functions[@]}"; do
    if grep -q "^$func()" "$SCRIPT_FILE"; then
        echo -e "${GREEN}✓${NC} Function $func found"
    else
        echo -e "${RED}❌ Error: Function $func not found${NC}"
        exit 1
    fi
done

# Check script syntax
echo
echo "Checking script syntax..."
if bash -n "$SCRIPT_FILE"; then
    echo -e "${GREEN}✓${NC} Script syntax is valid"
else
    echo -e "${RED}❌ Error: Script has syntax errors${NC}"
    exit 1
fi

# Check for common security issues
echo
echo "Checking for security issues..."

# Check for hardcoded passwords
if grep -i "password.*=" "$SCRIPT_FILE" | grep -v "YOUR_" | grep -v "#"; then
    echo -e "${YELLOW}⚠${NC} Warning: Possible hardcoded passwords found"
else
    echo -e "${GREEN}✓${NC} No hardcoded passwords detected"
fi

# Check for proper sudo usage
if grep -q "sudo " "$SCRIPT_FILE" && ! grep -q "check_sudo"; then
    echo -e "${YELLOW}⚠${NC} Warning: sudo usage detected without proper checking"
else
    echo -e "${GREEN}✓${NC} Proper sudo usage"
fi

echo
echo -e "${GREEN}✓ Verification completed successfully!${NC}"
echo
echo "Usage instructions:"
echo "1. Make sure you're on a supported Linux system"
echo "2. Run: chmod +x $SCRIPT_FILE"
echo "3. Run: ./$SCRIPT_FILE"
echo
echo "Supported systems:"
echo "- Debian 12/13"
echo "- Ubuntu 24.04"
echo "- CentOS 7/8/9"
echo "- Rocky Linux"
echo "- AlmaLinux"