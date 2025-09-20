#!/bin/bash

# GTA V Server Installation Script
# Supports RageMP, ALTV, and FiveM TX Admin
# Compatible with Debian 12, Debian 13, Ubuntu 24, and CentOS
# Author: Server Installation Script
# Date: $(date)

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Global variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$HOME/gta-server-install.log"
USER_HOME="/home/$(whoami)"
SERVER_USER="gta-server"

# Logging function
log() {
    local message="${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
    echo -e "$message"
    if [[ "$LOG_FILE" != "/dev/null" ]]; then
        echo -e "$message" >> "$LOG_FILE" 2>/dev/null || true
    fi
}

error_log() {
    local message="${RED}[ERROR $(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
    echo -e "$message"
    if [[ "$LOG_FILE" != "/dev/null" ]]; then
        echo -e "$message" >> "$LOG_FILE" 2>/dev/null || true
    fi
}

warn_log() {
    local message="${YELLOW}[WARNING $(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
    echo -e "$message"
    if [[ "$LOG_FILE" != "/dev/null" ]]; then
        echo -e "$message" >> "$LOG_FILE" 2>/dev/null || true
    fi
}

# Print banner
print_banner() {
    clear
    echo -e "${CYAN}"
    echo "╔═══════════════════════════════════════════════════════════════╗"
    echo "║                   GTA V SERVER INSTALLER                      ║"
    echo "║                                                               ║"
    echo "║  Supports: RageMP, ALTV, FiveM TX Admin                      ║"
    echo "║  Compatible: Debian 12/13, Ubuntu 24, CentOS                 ║"
    echo "╚═══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo
}

# Check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        error_log "This script should not be run as root for security reasons."
        echo -e "${RED}Please run this script as a regular user with sudo privileges.${NC}"
        exit 1
    fi
}

# Check sudo privileges
check_sudo() {
    if ! sudo -n true 2>/dev/null; then
        error_log "This script requires sudo privileges."
        echo -e "${RED}Please ensure your user has sudo access.${NC}"
        exit 1
    fi
}

# Main menu function
show_main_menu() {
    while true; do
        print_banner
        echo -e "${BLUE}Please select a GTA V server to install:${NC}"
        echo
        echo -e "${CYAN}1)${NC} RageMP Server"
        echo -e "${CYAN}2)${NC} ALTV Server"
        echo -e "${CYAN}3)${NC} FiveM TX Admin"
        echo -e "${CYAN}4)${NC} System Information"
        echo -e "${CYAN}5)${NC} Server Management"
        echo -e "${CYAN}6)${NC} Exit"
        echo
        read -p "Enter your choice [1-6]: " choice
        
        case $choice in
            1)
                install_ragemp
                ;;
            2)
                install_altv
                ;;
            3)
                install_fivem_txadmin
                ;;
            4)
                show_system_info
                ;;
            5)
                server_management_menu
                ;;
            6)
                echo -e "${GREEN}Thank you for using GTA V Server Installer!${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid option. Please select 1-6.${NC}"
                sleep 2
                ;;
        esac
    done
}

# Validation functions
validate_system() {
    log "Validating system requirements..."
    
    # Check available disk space (minimum 10GB)
    local available_space=$(df / | awk 'NR==2 {print $4}')
    local required_space=10485760  # 10GB in KB
    
    if [[ $available_space -lt $required_space ]]; then
        local available_gb=$((available_space / 1048576))
        error_log "Insufficient disk space. Required: 10GB, Available: ${available_gb}GB"
        return 1
    fi
    
    # Check available RAM (minimum 1GB)
    local available_ram=$(free -k | awk 'NR==2{print $2}')
    local required_ram=1048576  # 1GB in KB
    
    if [[ $available_ram -lt $required_ram ]]; then
        local available_ram_gb=$((available_ram / 1048576))
        warn_log "Low RAM detected. Recommended: 2GB+, Available: ${available_ram_gb}GB"
    fi
    
    # Check internet connectivity
    if ! ping -c 1 google.com &>/dev/null; then
        error_log "No internet connection detected"
        return 1
    fi
    
    log "System validation completed successfully"
    return 0
}

# Cleanup function
cleanup_on_exit() {
    local exit_code=$?
    if [[ $exit_code -ne 0 ]]; then
        error_log "Script exited with error code: $exit_code"
        echo -e "${RED}Installation failed. Check the log file: $LOG_FILE${NC}"
    fi
}

# Initialize script
init_script() {
    # Set up exit trap
    trap cleanup_on_exit EXIT
    
    # Create log file if it doesn't exist (in user's home directory)
    touch "$LOG_FILE" 2>/dev/null || {
        LOG_FILE="./gta-server-install.log"
        touch "$LOG_FILE" 2>/dev/null || {
            echo -e "${RED}Warning: Cannot create log file. Continuing without logging.${NC}"
            LOG_FILE="/dev/null"
        }
    }
    
    log "Starting GTA V Server Installation Script"
    log "Log file location: $LOG_FILE"
    
    check_root
    check_sudo
    
    # Detect operating system
    detect_os
    
    # Validate system requirements
    if ! validate_system; then
        error_log "System validation failed"
        exit 1
    fi
}

# OS Detection and System Information
detect_os() {
    log "Detecting operating system..."
    
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        OS_NAME=$NAME
        OS_VERSION=$VERSION_ID
        OS_ID=$ID
        
        case $OS_ID in
            "debian")
                if [[ $OS_VERSION == "12" ]]; then
                    OS_TYPE="debian12"
                    PACKAGE_MANAGER="apt"
                elif [[ $OS_VERSION == "13" ]]; then
                    OS_TYPE="debian13"
                    PACKAGE_MANAGER="apt"
                else
                    warn_log "Debian version $OS_VERSION may not be fully supported"
                    OS_TYPE="debian"
                    PACKAGE_MANAGER="apt"
                fi
                ;;
            "ubuntu")
                if [[ $OS_VERSION == "24.04" ]]; then
                    OS_TYPE="ubuntu24"
                    PACKAGE_MANAGER="apt"
                else
                    warn_log "Ubuntu version $OS_VERSION may not be fully supported"
                    OS_TYPE="ubuntu"
                    PACKAGE_MANAGER="apt"
                fi
                ;;
            "centos"|"rhel"|"rocky"|"almalinux")
                OS_TYPE="centos"
                PACKAGE_MANAGER="yum"
                if command -v dnf &> /dev/null; then
                    PACKAGE_MANAGER="dnf"
                fi
                ;;
            *)
                error_log "Unsupported operating system: $OS_NAME"
                echo -e "${RED}This script supports only Debian 12/13, Ubuntu 24, and CentOS.${NC}"
                exit 1
                ;;
        esac
        
        log "Detected OS: $OS_NAME $OS_VERSION ($OS_TYPE)"
        log "Package manager: $PACKAGE_MANAGER"
    else
        error_log "Cannot detect operating system"
        exit 1
    fi
}

show_system_info() {
    print_banner
    echo -e "${BLUE}System Information:${NC}"
    echo "================================"
    echo -e "${CYAN}OS:${NC} $OS_NAME $OS_VERSION"
    echo -e "${CYAN}Architecture:${NC} $(uname -m)"
    echo -e "${CYAN}Kernel:${NC} $(uname -r)"
    echo -e "${CYAN}CPU Cores:${NC} $(nproc)"
    echo -e "${CYAN}Memory:${NC} $(free -h | awk '/^Mem:/ {print $2}')"
    echo -e "${CYAN}Disk Space:${NC} $(df -h / | awk 'NR==2 {print $4" available of "$2}')"
    echo -e "${CYAN}Package Manager:${NC} $PACKAGE_MANAGER"
    echo
    
    # Check for required ports
    echo -e "${BLUE}Port Status:${NC}"
    echo "================================"
    check_port 22005 "RageMP"
    check_port 7788 "ALTV" 
    check_port 30120 "FiveM"
    check_port 40120 "TX Admin"
    echo
    
    read -p "Press Enter to return to main menu..."
}

check_port() {
    local port=$1
    local service=$2
    if netstat -tuln 2>/dev/null | grep -q ":$port "; then
        echo -e "${CYAN}$service Port $port:${NC} ${RED}In Use${NC}"
    else
        echo -e "${CYAN}$service Port $port:${NC} ${GREEN}Available${NC}"
    fi
}

# Package installation functions
install_base_packages() {
    log "Installing base packages for $OS_TYPE"
    
    case $PACKAGE_MANAGER in
        "apt")
            sudo apt update
            sudo apt install -y curl wget unzip build-essential software-properties-common \
                              apt-transport-https ca-certificates gnupg lsb-release \
                              screen tmux htop git vim net-tools
            ;;
        "yum"|"dnf")
            sudo $PACKAGE_MANAGER update -y
            sudo $PACKAGE_MANAGER groupinstall -y "Development Tools"
            sudo $PACKAGE_MANAGER install -y curl wget unzip epel-release \
                                          screen tmux htop git vim net-tools
            ;;
    esac
}

install_nodejs() {
    log "Installing Node.js LTS"
    
    # Install Node.js using NodeSource repository
    case $PACKAGE_MANAGER in
        "apt")
            curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
            sudo apt install -y nodejs
            ;;
        "yum"|"dnf")
            curl -fsSL https://rpm.nodesource.com/setup_lts.x | sudo bash -
            sudo $PACKAGE_MANAGER install -y nodejs
            ;;
    esac
    
    # Verify installation
    node_version=$(node --version 2>/dev/null || echo "not installed")
    npm_version=$(npm --version 2>/dev/null || echo "not installed")
    log "Node.js version: $node_version"
    log "NPM version: $npm_version"
}

install_dotnet() {
    log "Installing .NET Runtime"
    
    case $PACKAGE_MANAGER in
        "apt")
            # Install Microsoft package repository
            wget https://packages.microsoft.com/config/$OS_ID/$OS_VERSION/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
            sudo dpkg -i packages-microsoft-prod.deb
            rm packages-microsoft-prod.deb
            
            sudo apt update
            sudo apt install -y dotnet-runtime-6.0 aspnetcore-runtime-6.0
            ;;
        "yum"|"dnf")
            sudo rpm -Uvh https://packages.microsoft.com/config/centos/7/packages-microsoft-prod.rpm
            sudo $PACKAGE_MANAGER install -y dotnet-runtime-6.0 aspnetcore-runtime-6.0
            ;;
    esac
    
    # Verify installation
    dotnet_version=$(dotnet --version 2>/dev/null || echo "not installed")
    log ".NET version: $dotnet_version"
}

create_server_user() {
    log "Creating server user: $SERVER_USER"
    
    if id "$SERVER_USER" &>/dev/null; then
        log "User $SERVER_USER already exists"
    else
        sudo useradd -m -s /bin/bash "$SERVER_USER"
        sudo usermod -aG sudo "$SERVER_USER" 2>/dev/null || true
        log "Created user: $SERVER_USER"
    fi
}

# Server installation functions
install_ragemp() {
    print_banner
    echo -e "${BLUE}Installing RageMP Server...${NC}"
    
    install_base_packages
    install_nodejs
    create_server_user
    
    local ragemp_dir="/home/$SERVER_USER/ragemp-server"
    
    log "Creating RageMP directory: $ragemp_dir"
    sudo -u $SERVER_USER mkdir -p "$ragemp_dir"
    
    log "Downloading RageMP server files"
    cd /tmp
    wget -O ragemp-server.tar.gz "https://cdn.rage.mp/updater/prerelease/server-files/linux_x64.tar.gz"
    
    log "Extracting RageMP server"
    sudo -u $SERVER_USER tar -xzf ragemp-server.tar.gz -C "$ragemp_dir" --strip-components=1
    rm ragemp-server.tar.gz
    
    log "Setting up RageMP configuration"
    sudo -u $SERVER_USER tee "$ragemp_dir/conf.json" > /dev/null <<EOF
{
    "maxplayers": 100,
    "name": "My RageMP Server",
    "gamemode": "freeroam",
    "streamdistance": 500,
    "port": 22005,
    "disallow_multiple_connections_per_ip": true,
    "limit_time_of_connections_per_ip": 1000,
    "url": "",
    "language": "en",
    "sync_rate": 40,
    "resource_scan_thread_limit": 0,
    "max_ping": 120,
    "min_fps": 30,
    "max_packet_loss": 0.2,
    "allow_cef_debugging": false,
    "enable_nodejs": true,
    "csharp": "enabled"
}
EOF

    # Create systemd service
    create_ragemp_service
    
    log "RageMP server installed successfully!"
    log "Server location: $ragemp_dir"
    log "Configuration: $ragemp_dir/conf.json"
    log "Start server with: sudo systemctl start ragemp"
    
    read -p "Press Enter to return to main menu..."
}

install_altv() {
    print_banner
    echo -e "${BLUE}Installing ALTV Server...${NC}"
    
    install_base_packages
    install_nodejs
    create_server_user
    
    local altv_dir="/home/$SERVER_USER/altv-server"
    
    log "Creating ALTV directory: $altv_dir"
    sudo -u $SERVER_USER mkdir -p "$altv_dir"
    
    log "Downloading ALTV server files"
    cd /tmp
    
    # Download ALTV server
    wget -O altv-server "https://cdn.altv.mp/server/release/x64_linux/altv-server"
    wget -O data.vdf "https://cdn.altv.mp/server/release/data.vdf"
    wget -O libnode.so.108 "https://cdn.altv.mp/others/libnode.so.108"
    
    log "Setting up ALTV server"
    sudo -u $SERVER_USER cp altv-server data.vdf libnode.so.108 "$altv_dir/"
    sudo chmod +x "$altv_dir/altv-server"
    
    # Clean up temp files
    rm altv-server data.vdf libnode.so.108
    
    log "Creating ALTV configuration"
    sudo -u $SERVER_USER tee "$altv_dir/server.cfg" > /dev/null <<EOF
name: My ALTV Server
host: 0.0.0.0
port: 7788
players: 100
#password: changeme
announce: false
#token: YOUR_TOKEN_HERE
gamemode: Freeroam
website: example.com
language: en
description: My awesome ALTV server
debug: false
streamingDistance: 400
migrationDistance: 150
timeout: 60000
announceRetryErrorDelay: 10000
announceRetryErrorAttempts: 50
duplicatePlayers: 2
resources: [
  example-resource
]
modules: [
  js-module,
  #csharp-module
]
EOF

    # Create example resource
    local resource_dir="$altv_dir/resources/example-resource"
    sudo -u $SERVER_USER mkdir -p "$resource_dir"
    
    sudo -u $SERVER_USER tee "$resource_dir/resource.cfg" > /dev/null <<EOF
type: js
main: index.js
client-main: client.js
client-files: [
    client.js
]
deps: []
EOF

    sudo -u $SERVER_USER tee "$resource_dir/index.js" > /dev/null <<EOF
import alt from 'alt-server';

alt.log('Example resource loaded');

alt.on('playerConnect', (player) => {
    alt.log(\`\${player.name} connected\`);
});

alt.on('playerDisconnect', (player, reason) => {
    alt.log(\`\${player.name} disconnected: \${reason}\`);
});
EOF

    sudo -u $SERVER_USER tee "$resource_dir/client.js" > /dev/null <<EOF
import alt from 'alt-client';

alt.log('Client-side resource loaded');
EOF

    # Create systemd service
    create_altv_service
    
    log "ALTV server installed successfully!"
    log "Server location: $altv_dir"
    log "Configuration: $altv_dir/server.cfg"
    log "Start server with: sudo systemctl start altv"
    
    read -p "Press Enter to return to main menu..."
}

install_fivem_txadmin() {
    print_banner
    echo -e "${BLUE}Installing FiveM TX Admin...${NC}"
    
    install_base_packages
    install_nodejs
    create_server_user
    
    local fivem_dir="/home/$SERVER_USER/fivem-server"
    
    log "Creating FiveM directory: $fivem_dir"
    sudo -u $SERVER_USER mkdir -p "$fivem_dir"
    
    log "Downloading FiveM server files"
    cd /tmp
    
    # Download latest FiveM server
    wget -O fx.tar.xz "https://runtime.fivem.net/artifacts/fivem/build_proot_linux/master/$(curl -s https://runtime.fivem.net/artifacts/fivem/build_proot_linux/master/ | grep -oP '(?<=href=")[0-9]+-[a-f0-9]+(?=/")' | tail -1)/fx.tar.xz"
    
    log "Extracting FiveM server"
    sudo -u $SERVER_USER tar -xf fx.tar.xz -C "$fivem_dir"
    rm fx.tar.xz
    
    # Set executable permissions
    sudo chmod +x "$fivem_dir/FXServer"
    
    log "Creating FiveM server configuration"
    sudo -u $SERVER_USER tee "$fivem_dir/server.cfg" > /dev/null <<EOF
# FiveM Server Configuration

# Server Information
sv_hostname "My FiveM Server"
sv_maxclients 32
sv_endpointprivacy true

# Server Identity
sv_licenseKey "YOUR_LICENSE_KEY_HERE"

# Networking
endpoint_add_tcp "0.0.0.0:30120"
endpoint_add_udp "0.0.0.0:30120"

# Resources
ensure mapmanager
ensure chat
ensure spawnmanager
ensure sessionmanager
ensure basic-gamemode
ensure hardcap

# TX Admin
ensure txAdmin

# Server Security
sv_authMaxVariance 1
sv_authMinTrust 5

# Misc
sets tags "default"
sets banner_detail "https://example.com/banner.png"
sets banner_connecting "https://example.com/connecting.png"

# Convars
set steam_webApiKey "YOUR_STEAM_API_KEY"
set sv_tebex_secret "YOUR_TEBEX_SECRET"

# Performance
set server_ackTimeoutThreshold 60000
EOF

    # Create start script
    sudo -u $SERVER_USER tee "$fivem_dir/start.sh" > /dev/null <<EOF
#!/bin/bash
cd "\$(dirname "\$0")"
exec ./FXServer +exec server.cfg
EOF

    sudo chmod +x "$fivem_dir/start.sh"

    # Create systemd service
    create_fivem_service
    
    log "FiveM server with TX Admin installed successfully!"
    log "Server location: $fivem_dir"
    log "Configuration: $fivem_dir/server.cfg"
    log ""
    warn_log "IMPORTANT: You need to:"
    warn_log "1. Get a license key from https://keymaster.fivem.net/"
    warn_log "2. Replace 'YOUR_LICENSE_KEY_HERE' in server.cfg"
    warn_log "3. Start server with: sudo systemctl start fivem"
    warn_log "4. Access TX Admin at: http://YOUR_SERVER_IP:40120"
    
    read -p "Press Enter to return to main menu..."
}

# Systemd service creation functions
create_ragemp_service() {
    log "Creating RageMP systemd service"
    
    sudo tee /etc/systemd/system/ragemp.service > /dev/null <<EOF
[Unit]
Description=RageMP Server
After=network.target

[Service]
Type=simple
User=$SERVER_USER
WorkingDirectory=/home/$SERVER_USER/ragemp-server
ExecStart=/home/$SERVER_USER/ragemp-server/ragemp-server
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

    sudo systemctl daemon-reload
    sudo systemctl enable ragemp
    log "RageMP service created and enabled"
}

create_altv_service() {
    log "Creating ALTV systemd service"
    
    sudo tee /etc/systemd/system/altv.service > /dev/null <<EOF
[Unit]
Description=ALTV Server
After=network.target

[Service]
Type=simple
User=$SERVER_USER
WorkingDirectory=/home/$SERVER_USER/altv-server
ExecStart=/home/$SERVER_USER/altv-server/altv-server
Restart=always
RestartSec=10
Environment=LD_LIBRARY_PATH=/home/$SERVER_USER/altv-server

[Install]
WantedBy=multi-user.target
EOF

    sudo systemctl daemon-reload
    sudo systemctl enable altv
    log "ALTV service created and enabled"
}

create_fivem_service() {
    log "Creating FiveM systemd service"
    
    sudo tee /etc/systemd/system/fivem.service > /dev/null <<EOF
[Unit]
Description=FiveM Server
After=network.target

[Service]
Type=simple
User=$SERVER_USER
WorkingDirectory=/home/$SERVER_USER/fivem-server
ExecStart=/home/$SERVER_USER/fivem-server/start.sh
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

    sudo systemctl daemon-reload
    sudo systemctl enable fivem
    log "FiveM service created and enabled"
}

# Server management functions
server_management_menu() {
    while true; do
        print_banner
        echo -e "${BLUE}Server Management:${NC}"
        echo
        echo -e "${CYAN}1)${NC} Start Server"
        echo -e "${CYAN}2)${NC} Stop Server"
        echo -e "${CYAN}3)${NC} Restart Server"
        echo -e "${CYAN}4)${NC} Server Status"
        echo -e "${CYAN}5)${NC} View Logs"
        echo -e "${CYAN}6)${NC} Server Console"
        echo -e "${CYAN}7)${NC} Remove Server"
        echo -e "${CYAN}8)${NC} Back to Main Menu"
        echo
        read -p "Enter your choice [1-8]: " choice
        
        case $choice in
            1)
                start_server_menu
                ;;
            2)
                stop_server_menu
                ;;
            3)
                restart_server_menu
                ;;
            4)
                server_status_menu
                ;;
            5)
                view_logs_menu
                ;;
            6)
                server_console_menu
                ;;
            7)
                remove_server_menu
                ;;
            8)
                break
                ;;
            *)
                echo -e "${RED}Invalid option. Please select 1-8.${NC}"
                sleep 2
                ;;
        esac
    done
}

start_server_menu() {
    print_banner
    echo -e "${BLUE}Start Server:${NC}"
    echo
    echo -e "${CYAN}1)${NC} Start RageMP"
    echo -e "${CYAN}2)${NC} Start ALTV"
    echo -e "${CYAN}3)${NC} Start FiveM"
    echo -e "${CYAN}4)${NC} Back"
    echo
    read -p "Enter your choice [1-4]: " choice
    
    case $choice in
        1)
            if systemctl is-enabled ragemp &>/dev/null; then
                sudo systemctl start ragemp
                log "RageMP server started"
            else
                error_log "RageMP service not found. Please install RageMP first."
            fi
            ;;
        2)
            if systemctl is-enabled altv &>/dev/null; then
                sudo systemctl start altv
                log "ALTV server started"
            else
                error_log "ALTV service not found. Please install ALTV first."
            fi
            ;;
        3)
            if systemctl is-enabled fivem &>/dev/null; then
                sudo systemctl start fivem
                log "FiveM server started"
            else
                error_log "FiveM service not found. Please install FiveM first."
            fi
            ;;
        4)
            return
            ;;
        *)
            echo -e "${RED}Invalid option.${NC}"
            ;;
    esac
    
    sleep 2
}

stop_server_menu() {
    print_banner
    echo -e "${BLUE}Stop Server:${NC}"
    echo
    echo -e "${CYAN}1)${NC} Stop RageMP"
    echo -e "${CYAN}2)${NC} Stop ALTV"
    echo -e "${CYAN}3)${NC} Stop FiveM"
    echo -e "${CYAN}4)${NC} Back"
    echo
    read -p "Enter your choice [1-4]: " choice
    
    case $choice in
        1)
            sudo systemctl stop ragemp
            log "RageMP server stopped"
            ;;
        2)
            sudo systemctl stop altv
            log "ALTV server stopped"
            ;;
        3)
            sudo systemctl stop fivem
            log "FiveM server stopped"
            ;;
        4)
            return
            ;;
        *)
            echo -e "${RED}Invalid option.${NC}"
            ;;
    esac
    
    sleep 2
}

restart_server_menu() {
    print_banner
    echo -e "${BLUE}Restart Server:${NC}"
    echo
    echo -e "${CYAN}1)${NC} Restart RageMP"
    echo -e "${CYAN}2)${NC} Restart ALTV"
    echo -e "${CYAN}3)${NC} Restart FiveM"
    echo -e "${CYAN}4)${NC} Back"
    echo
    read -p "Enter your choice [1-4]: " choice
    
    case $choice in
        1)
            sudo systemctl restart ragemp
            log "RageMP server restarted"
            ;;
        2)
            sudo systemctl restart altv
            log "ALTV server restarted"
            ;;
        3)
            sudo systemctl restart fivem
            log "FiveM server restarted"
            ;;
        4)
            return
            ;;
        *)
            echo -e "${RED}Invalid option.${NC}"
            ;;
    esac
    
    sleep 2
}

server_status_menu() {
    print_banner
    echo -e "${BLUE}Server Status:${NC}"
    echo "================================"
    
    # Check each server service
    check_service_status "ragemp" "RageMP"
    check_service_status "altv" "ALTV"
    check_service_status "fivem" "FiveM"
    
    echo
    read -p "Press Enter to continue..."
}

check_service_status() {
    local service=$1
    local name=$2
    
    if systemctl is-enabled $service &>/dev/null; then
        if systemctl is-active $service &>/dev/null; then
            echo -e "${CYAN}$name:${NC} ${GREEN}Running${NC}"
            # Show some basic info
            local pid=$(systemctl show -p MainPID $service | cut -d= -f2)
            if [[ $pid != "0" ]]; then
                local memory=$(ps -o rss= -p $pid 2>/dev/null | awk '{print int($1/1024)" MB"}')
                local cpu=$(ps -o %cpu= -p $pid 2>/dev/null | awk '{print $1"%"}')
                echo -e "  ${CYAN}PID:${NC} $pid  ${CYAN}Memory:${NC} $memory  ${CYAN}CPU:${NC} $cpu"
            fi
        else
            echo -e "${CYAN}$name:${NC} ${RED}Stopped${NC}"
        fi
    else
        echo -e "${CYAN}$name:${NC} ${YELLOW}Not Installed${NC}"
    fi
}

view_logs_menu() {
    print_banner
    echo -e "${BLUE}View Server Logs:${NC}"
    echo
    echo -e "${CYAN}1)${NC} RageMP Logs"
    echo -e "${CYAN}2)${NC} ALTV Logs"
    echo -e "${CYAN}3)${NC} FiveM Logs"
    echo -e "${CYAN}4)${NC} Installation Logs"
    echo -e "${CYAN}5)${NC} Back"
    echo
    read -p "Enter your choice [1-5]: " choice
    
    case $choice in
        1)
            echo -e "${BLUE}RageMP Logs (Press Ctrl+C to exit):${NC}"
            sudo journalctl -u ragemp -f
            ;;
        2)
            echo -e "${BLUE}ALTV Logs (Press Ctrl+C to exit):${NC}"
            sudo journalctl -u altv -f
            ;;
        3)
            echo -e "${BLUE}FiveM Logs (Press Ctrl+C to exit):${NC}"
            sudo journalctl -u fivem -f
            ;;
        4)
            echo -e "${BLUE}Installation Logs:${NC}"
            if [[ "$LOG_FILE" != "/dev/null" && -f "$LOG_FILE" ]]; then
                tail -50 "$LOG_FILE"
            else
                echo "No log file available or logging is disabled."
            fi
            read -p "Press Enter to continue..."
            ;;
        5)
            return
            ;;
        *)
            echo -e "${RED}Invalid option.${NC}"
            sleep 2
            ;;
    esac
}

server_console_menu() {
    print_banner
    echo -e "${BLUE}Server Console Access:${NC}"
    echo
    echo -e "${CYAN}1)${NC} RageMP Console (Screen)"
    echo -e "${CYAN}2)${NC} ALTV Console (Screen)"
    echo -e "${CYAN}3)${NC} FiveM Console (Screen)"
    echo -e "${CYAN}4)${NC} Back"
    echo
    read -p "Enter your choice [1-4]: " choice
    
    case $choice in
        1)
            if systemctl is-active ragemp &>/dev/null; then
                echo -e "${YELLOW}Attaching to RageMP console (Press Ctrl+A, D to detach)${NC}"
                sleep 2
                sudo -u $SERVER_USER screen -r ragemp 2>/dev/null || echo "No console session found"
            else
                echo -e "${RED}RageMP server is not running${NC}"
                sleep 2
            fi
            ;;
        2)
            if systemctl is-active altv &>/dev/null; then
                echo -e "${YELLOW}Attaching to ALTV console (Press Ctrl+A, D to detach)${NC}"
                sleep 2
                sudo -u $SERVER_USER screen -r altv 2>/dev/null || echo "No console session found"
            else
                echo -e "${RED}ALTV server is not running${NC}"
                sleep 2
            fi
            ;;
        3)
            if systemctl is-active fivem &>/dev/null; then
                echo -e "${YELLOW}Attaching to FiveM console (Press Ctrl+A, D to detach)${NC}"
                sleep 2
                sudo -u $SERVER_USER screen -r fivem 2>/dev/null || echo "No console session found"
            else
                echo -e "${RED}FiveM server is not running${NC}"
                sleep 2
            fi
            ;;
        4)
            return
            ;;
        *)
            echo -e "${RED}Invalid option.${NC}"
            sleep 2
            ;;
    esac
}

remove_server_menu() {
    print_banner
    echo -e "${RED}Remove Server (DANGEROUS):${NC}"
    echo
    warn_log "This will completely remove the server and all data!"
    echo
    echo -e "${CYAN}1)${NC} Remove RageMP"
    echo -e "${CYAN}2)${NC} Remove ALTV"
    echo -e "${CYAN}3)${NC} Remove FiveM"
    echo -e "${CYAN}4)${NC} Back"
    echo
    read -p "Enter your choice [1-4]: " choice
    
    case $choice in
        1|2|3)
            local servers=("" "ragemp" "altv" "fivem")
            local names=("" "RageMP" "ALTV" "FiveM")
            local server=${servers[$choice]}
            local name=${names[$choice]}
            
            echo -e "${RED}Are you sure you want to remove $name server?${NC}"
            echo -e "${RED}This action cannot be undone!${NC}"
            echo
            read -p "Type 'YES' to confirm: " confirm
            
            if [[ $confirm == "YES" ]]; then
                # Stop and disable service
                sudo systemctl stop $server 2>/dev/null || true
                sudo systemctl disable $server 2>/dev/null || true
                sudo rm -f /etc/systemd/system/$server.service
                sudo systemctl daemon-reload
                
                # Remove server files
                sudo rm -rf "/home/$SERVER_USER/$server-server"
                
                log "$name server removed completely"
                echo -e "${GREEN}$name server has been removed.${NC}"
            else
                echo -e "${YELLOW}Removal cancelled.${NC}"
            fi
            sleep 2
            ;;
        4)
            return
            ;;
        *)
            echo -e "${RED}Invalid option.${NC}"
            sleep 2
            ;;
    esac
}

# Main execution
main() {
    init_script
    show_main_menu
}

# Run the script
main "$@"
