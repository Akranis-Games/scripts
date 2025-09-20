# GTA V Server Installation Script - Windows Edition

Dieses PowerShell-Skript automatisiert die Installation von RageMP, ALTV und FiveM TX Admin Servern auf Windows-Systemen.

## Unterstützte Betriebssysteme
- Windows 10 (Version 1809 oder neuer)
- Windows 11
- Windows Server 2019
- Windows Server 2022

## Features
- **Multi-Server-Unterstützung**: RageMP, ALTV und FiveM TX Admin
- **Automatische Installation**: Lädt Server-Dateien herunter und konfiguriert sie automatisch
- **Windows-Dienste**: Erstellt Windows-Dienste für jeden Server
- **Firewall-Konfiguration**: Konfiguriert automatisch Windows Firewall-Regeln
- **Package-Management**: Installiert benötigte Abhängigkeiten über Chocolatey
- **Umfassendes Logging**: Vollständige Installation- und Betriebsprotokolle

## Voraussetzungen
- Windows 10/11 oder Windows Server 2019/2022
- Administrator-Berechtigung
- Mindestens 4GB RAM (8GB empfohlen)
- Mindestens 10GB freier Festplattenspeicher
- Internetverbindung für Downloads

## Installation

### 1. PowerShell als Administrator öffnen
Rechtsklick auf Start → "Windows PowerShell (Administrator)" oder "Terminal (Administrator)"

### 2. Execution Policy setzen (falls nötig)
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### 3. Skript herunterladen
```powershell
# Download des Skripts
Invoke-WebRequest -Uri "https://your-domain.com/install.ps1" -OutFile "install.ps1"
# oder
curl -O https://your-domain.com/install.ps1
```

### 4. Skript ausführen
```powershell
.\install.ps1
```

## Server-Informationen

### RageMP Server
- **Standard-Port**: 22005 (UDP)
- **Installationspfad**: `C:\GTA-Servers\RageMP\`
- **Konfiguration**: `C:\GTA-Servers\RageMP\conf.json`
- **Windows-Dienst**: `RageMP-Server`
- **Sprach-Unterstützung**: C# und JavaScript

### ALTV Server
- **Standard-Port**: 7788 (UDP)
- **Installationspfad**: `C:\GTA-Servers\ALTV\`
- **Konfiguration**: `C:\GTA-Servers\ALTV\server.cfg`
- **Windows-Dienst**: `ALTV-Server`
- **Sprach-Unterstützung**: JavaScript und C#

### FiveM Server (TX Admin)
- **Standard-Ports**: 30120 (Spiel), 40120 (TX Admin)
- **Installationspfad**: `C:\GTA-Servers\FiveM\`
- **Konfiguration**: `C:\GTA-Servers\FiveM\server.cfg`
- **Windows-Dienst**: `FiveM-Server`
- **TX Admin URL**: `http://localhost:40120`

## Server-Verwaltung

### Mit Windows-Diensten
```powershell
# Server starten
Start-Service -Name "RageMP-Server"
Start-Service -Name "ALTV-Server"
Start-Service -Name "FiveM-Server"

# Server stoppen
Stop-Service -Name "RageMP-Server"
Stop-Service -Name "ALTV-Server"
Stop-Service -Name "FiveM-Server"

# Server-Status prüfen
Get-Service -Name "RageMP-Server"
Get-Service -Name "ALTV-Server"
Get-Service -Name "FiveM-Server"
```

### Mit dem Skript-Menü
Führen Sie das Skript erneut aus und wählen Sie "Server Management" aus dem Hauptmenü für eine interaktive Benutzeroberfläche.

## Konfiguration

### RageMP Konfiguration
Bearbeiten Sie `C:\GTA-Servers\RageMP\conf.json`:
```json
{
    "maxplayers": 100,
    "name": "Mein RageMP Server",
    "port": 22005,
    "gamemode": "freeroam"
}
```

### ALTV Konfiguration
Bearbeiten Sie `C:\GTA-Servers\ALTV\server.cfg`:
```yaml
name: Mein ALTV Server
host: 0.0.0.0
port: 7788
players: 100
```

### FiveM Konfiguration
Bearbeiten Sie `C:\GTA-Servers\FiveM\server.cfg`:
- **WICHTIG**: Holen Sie sich einen Lizenzschlüssel von [Keymaster](https://keymaster.fivem.net/)
- Ersetzen Sie `YOUR_LICENSE_KEY_HERE` durch Ihren echten Lizenzschlüssel

## Firewall-Konfiguration

Das Skript konfiguriert automatisch die Windows Firewall. Falls manuelle Konfiguration nötig ist:

```powershell
# Windows Firewall Regeln hinzufügen
New-NetFirewallRule -DisplayName "RageMP Server" -Direction Inbound -Protocol UDP -LocalPort 22005 -Action Allow
New-NetFirewallRule -DisplayName "ALTV Server" -Direction Inbound -Protocol UDP -LocalPort 7788 -Action Allow
New-NetFirewallRule -DisplayName "FiveM Server TCP" -Direction Inbound -Protocol TCP -LocalPort 30120 -Action Allow
New-NetFirewallRule -DisplayName "FiveM Server UDP" -Direction Inbound -Protocol UDP -LocalPort 30120 -Action Allow
New-NetFirewallRule -DisplayName "FiveM TX Admin" -Direction Inbound -Protocol TCP -LocalPort 40120 -Action Allow
```

## Skript-Parameter

```powershell
# Hilfe anzeigen
.\install.ps1 -Help

# Nicht-interaktiver Modus (für Automatisierung)
.\install.ps1 -NoInteractive

# Benutzerdefinierten Log-Pfad verwenden
.\install.ps1 -LogPath "C:\Logs\gta-server.log"
```

## Problembehebung

### Häufige Probleme

1. **Execution Policy Fehler**:
   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```

2. **Keine Administrator-Berechtigung**:
   - Starten Sie PowerShell als Administrator
   - Rechtsklick auf PowerShell → "Als Administrator ausführen"

3. **Dienst startet nicht**:
   - Überprüfen Sie die Windows Event Logs
   - Stellen Sie sicher, dass die Ports nicht belegt sind
   - Überprüfen Sie die Server-Konfigurationsdateien

4. **Download-Fehler**:
   - Überprüfen Sie die Internetverbindung
   - Firewall/Antivirus kann Downloads blockieren
   - Versuchen Sie es mit einem VPN

### Log-Dateien
- **Installations-Log**: `%USERPROFILE%\gta-server-install.log`
- **Windows Event Logs**: Windows Event Viewer → Windows-Protokolle → Anwendung
- **Server-Logs**: `C:\GTA-Servers\[ServerType]\logs\`

### Dienste-Verwaltung
```powershell
# Alle GTA-Server-Dienste anzeigen
Get-Service -Name "*Server*" | Where-Object {$_.DisplayName -match "RageMP|ALTV|FiveM"}

# Dienst-Details anzeigen
Get-Service -Name "RageMP-Server" | Format-List *

# Dienst-Abhängigkeiten prüfen
Get-Service -Name "RageMP-Server" -RequiredServices
```

## Sicherheitshinweise

- Alle Server-Dienste laufen unter dem LocalSystem-Konto
- Firewall-Regeln werden automatisch konfiguriert
- Server-Dateien befinden sich in `C:\GTA-Servers\` mit entsprechenden Berechtigungen
- Log-Dateien werden mit angemessenen Berechtigungen erstellt

## Updates

Um einen Server zu aktualisieren:
1. Stoppen Sie den entsprechenden Dienst
2. Sichern Sie Ihre Konfigurationsdateien
3. Führen Sie das Installationsskript erneut aus
4. Stellen Sie Ihre Konfiguration wieder her
5. Starten Sie den Dienst

## Deinstallation

### Einzelnen Server entfernen
Verwenden Sie das Skript-Menü "Server Management" → "Remove Server"

### Komplette Deinstallation
```powershell
# Alle Dienste stoppen und entfernen
Stop-Service -Name "RageMP-Server", "ALTV-Server", "FiveM-Server" -Force -ErrorAction SilentlyContinue
sc.exe delete "RageMP-Server"
sc.exe delete "ALTV-Server"
sc.exe delete "FiveM-Server"

# Server-Dateien entfernen
Remove-Item -Path "C:\GTA-Servers" -Recurse -Force

# Firewall-Regeln entfernen
Remove-NetFirewallRule -DisplayName "*RageMP*", "*ALTV*", "*FiveM*" -ErrorAction SilentlyContinue
```

## Lizenz

Dieses Skript wird wie besehen für Bildungs- und Server-Administrationszwecke bereitgestellt.
Jede Server-Software (RageMP, ALTV, FiveM) hat ihre eigenen Lizenzbedingungen.

## Support

Bei Problemen mit:
- **RageMP**: Besuchen Sie das [RageMP Forum](https://rage.mp/)
- **ALTV**: Besuchen Sie den [ALTV Discord](https://altv.mp/discord)
- **FiveM**: Besuchen Sie das [FiveM Forum](https://forum.cfx.re/)
- **Diesem Skript**: Überprüfen Sie den Abschnitt zur Problembehebung oben

## Changelog

### Version 1.0
- Erstveröffentlichung für Windows
- Unterstützung für RageMP, ALTV und FiveM
- Automatische Chocolatey-Installation
- Windows-Dienst-Integration
- Firewall-Automatisierung