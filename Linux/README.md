# GTA V Server Installation Script

This script automates the installation of RageMP, ALTV, and FiveM TX Admin servers on Linux systems.

## Supported Operating Systems
- Debian 12 (Bookworm)
- Debian 13 (Trixie)
- Ubuntu 24.04 LTS
- CentOS 7/8/9
- Rocky Linux
- AlmaLinux

## Features
- **Multi-platform support**: Automatic OS detection and package manager selection
- **Complete server setup**: Downloads, installs, and configures servers automatically
- **Systemd integration**: Creates proper system services for each server
- **Server management**: Built-in tools for starting, stopping, monitoring servers
- **Security focused**: Creates dedicated user accounts and proper permissions
- **Comprehensive logging**: Full installation and operation logging

## Prerequisites
- Linux system (supported distributions)
- User account with sudo privileges
- Internet connection for downloading server files
- At least 2GB RAM and 10GB disk space

## Installation

### 1. Download the script
```bash
wget https://your-domain.com/install.sh
# or
curl -O https://your-domain.com/install.sh
```

### 2. Make the script executable
```bash
chmod +x install.sh
```

### 3. Run the installation script
```bash
./install.sh
```

## Server Information

### RageMP Server
- **Default Port**: 22005
- **Installation Path**: `/home/gta-server/ragemp-server/`
- **Configuration**: `/home/gta-server/ragemp-server/conf.json`
- **Service**: `ragemp.service`
- **Language Support**: C# and JavaScript

### ALTV Server
- **Default Port**: 7788
- **Installation Path**: `/home/gta-server/altv-server/`
- **Configuration**: `/home/gta-server/altv-server/server.cfg`
- **Service**: `altv.service`
- **Language Support**: JavaScript and C#

### FiveM Server (TX Admin)
- **Default Port**: 30120 (Game), 40120 (TX Admin)
- **Installation Path**: `/home/gta-server/fivem-server/`
- **Configuration**: `/home/gta-server/fivem-server/server.cfg`
- **Service**: `fivem.service`
- **TX Admin URL**: `http://YOUR_SERVER_IP:40120`

## Server Management

### Using Systemd Commands
```bash
# Start a server
sudo systemctl start ragemp|altv|fivem

# Stop a server
sudo systemctl stop ragemp|altv|fivem

# Restart a server
sudo systemctl restart ragemp|altv|fivem

# Check server status
sudo systemctl status ragemp|altv|fivem

# View server logs
sudo journalctl -u ragemp|altv|fivem -f
```

### Using the Script Menu
Run the script again and select "Server Management" from the main menu for an interactive interface.

## Configuration

### RageMP Configuration
Edit `/home/gta-server/ragemp-server/conf.json`:
```json
{
    "maxplayers": 100,
    "name": "My RageMP Server",
    "port": 22005,
    "gamemode": "freeroam"
}
```

### ALTV Configuration
Edit `/home/gta-server/altv-server/server.cfg`:
```yaml
name: My ALTV Server
host: 0.0.0.0
port: 7788
players: 100
```

### FiveM Configuration
Edit `/home/gta-server/fivem-server/server.cfg`:
- **IMPORTANT**: Get a license key from [Keymaster](https://keymaster.fivem.net/)
- Replace `YOUR_LICENSE_KEY_HERE` with your actual license key

## Firewall Configuration

Make sure to open the following ports in your firewall:

```bash
# For UFW (Ubuntu/Debian)
sudo ufw allow 22005/udp  # RageMP
sudo ufw allow 7788/udp   # ALTV
sudo ufw allow 30120     # FiveM Game
sudo ufw allow 40120/tcp  # TX Admin

# For firewalld (CentOS/RHEL)
sudo firewall-cmd --permanent --add-port=22005/udp  # RageMP
sudo firewall-cmd --permanent --add-port=7788/udp   # ALTV
sudo firewall-cmd --permanent --add-port=30120/tcp  # FiveM Game
sudo firewall-cmd --permanent --add-port=30120/udp  # FiveM Game
sudo firewall-cmd --permanent --add-port=40120/tcp  # TX Admin
sudo firewall-cmd --reload
```

## Troubleshooting

### Common Issues

1. **Permission Denied**: Make sure the script is executable (`chmod +x install.sh`)
2. **Package Installation Failed**: Check your internet connection and package manager
3. **Service Won't Start**: Check logs with `sudo journalctl -u servicename`
4. **Port Already in Use**: Use `netstat -tulpn | grep PORT` to check port usage

### Log Files
- Installation log: `/var/log/gta-server-install.log`
- Server logs: `sudo journalctl -u ragemp|altv|fivem`

### Getting Help
1. Check the installation log for errors
2. Verify system requirements are met
3. Ensure all prerequisites are installed
4. Check firewall settings

## Security Considerations

- The script creates a dedicated user `gta-server` for running servers
- Services run with limited privileges
- All servers are configured to bind to specific ports only
- Log files are created with appropriate permissions

## Updates

To update a server:
1. Stop the service: `sudo systemctl stop servicename`
2. Backup your configuration files
3. Re-run the installation script to download latest files
4. Restore your configuration
5. Start the service: `sudo systemctl start servicename`

## License

This script is provided as-is for educational and server administration purposes.
Each server software (RageMP, ALTV, FiveM) has its own licensing terms.

## Support

For issues with:
- **RageMP**: Visit [RageMP Forum](https://rage.mp/)
- **ALTV**: Visit [ALTV Discord](https://altv.mp/discord)
- **FiveM**: Visit [FiveM Forum](https://forum.cfx.re/)
- **This Script**: Check the troubleshooting section above