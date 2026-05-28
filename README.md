# Q-SIS Updater CLI

A modular PowerShell-based deployment engine designed to automate the update process for the Q Student Information System. It handles backing up existing files, deploying new application files to multiple web servers via UNC paths, and executing ordered SQL scripts against configured databases.

---

## Requirements

- **PowerShell 5.1** or later
- Network access to target web servers via **UNC paths** (e.g., `\\server\share`)
- Network access to target **SQL Server** instances
- The executing user account must have:
  - Read/write permissions on all UNC deployment paths
  - Read/write permissions on the `BackupDirectory` and `LogDirectory`
  - Execute permissions on the target SQL databases (if using Windows Authentication)

---

## First-Time Setup

1. **Clone or download** the repository to a local directory (e.g., `F:\Tools\Q-SIS-Updater`).

2. **Copy the example config** and fill it in with your environment details:
   ```powershell
   Copy-Item config.example.json config.json
   ```

3. **Edit `config.json`** — see the [Configuration](#configuration) section below.

4. **Place your update ZIP** in the `Payloads` folder (or any accessible path).

---

## Configuration

All environment-specific settings live in `config.json`. This file is excluded from version control — **never commit it to Git** as it may contain credentials.

### Full Example

```json
{
  "Settings": {
    "BackupDirectory": "F:\\Q-SIS-Updater\\Backups",
    "LogDirectory":    "F:\\Q-SIS-Updater\\Logs",
    "SqlExecutionTimeoutSeconds": 600
  },
  "TargetServers": [
    {
      "Name": "WebServer01",
      "Type": "Web",
      "DeploymentPath": "\\\\192.168.1.10\\c$\\inetpub\\wwwroot\\QSIS"
    },
    {
      "Name": "WebServer02",
      "Type": "Web",
      "DeploymentPath": "\\\\192.168.1.11\\c$\\inetpub\\wwwroot\\QSIS"
    }
  ],
  "Databases": [
    {
      "Name":           "QSIS_Prod",
      "Server":         "SQLServer01",
      "Authentication": "Windows",
      "Username":       "",
      "Password":       "",
      "ConnectionString": "Server=SQLServer01;Database=QSIS_Prod;Integrated Security=True;TrustServerCertificate=True"
    }
  ]
}
```

### Settings Reference

| Key | Description |
|-----|-------------|
| `BackupDirectory` | Local path where web file backups are stored before each deployment. |
| `LogDirectory` | Local path where timestamped log files are written. Defaults to `.\Logs` if omitted. |
| `SqlExecutionTimeoutSeconds` | Maximum time (in seconds) allowed for a single SQL batch to execute. Default: `600`. |

### TargetServers Reference

Each entry in `TargetServers` represents one web server to deploy to.

| Key | Description |
|-----|-------------|
| `Name` | A friendly label used in logs and backup folder names. |
| `Type` | Must be `"Web"`. Reserved for future server role types. |
| `DeploymentPath` | UNC path to the deployment root on the target server. |

### Databases Reference

Each entry in `Databases` represents one SQL Server database to run scripts against.

| Key | Description |
|-----|-------------|
| `Name` | The database name. |
| `Server` | The SQL Server hostname or IP address. |
| `Authentication` | `"Windows"` for Integrated Security, or `"SQL"` for username/password. |
| `Username` | SQL Auth username. Leave blank for Windows Authentication. |
| `Password` | SQL Auth password. Leave blank for Windows Authentication. |
| `ConnectionString` | Optional. If provided, overrides the values above. |

---

## Update Package Format

The updater expects a **ZIP file** containing any combination of:

- **Application files** — placed in an `Applications\` subfolder inside the ZIP, or at the ZIP root if no `Applications\` folder exists.
- **SQL scripts** — placed in a `SQL\` subfolder inside the ZIP. Scripts are executed in **alphabetical order** by filename.

### Recommended ZIP structure

```
MyUpdate_v2.5.zip
├── Applications\
│   ├── bin\
│   ├── web.config
│   └── ...
└── SQL\
    ├── 001_AlterTable.sql
    └── 002_InsertData.sql
```

> **Tip:** Prefix SQL filenames with a number (e.g., `001_`, `002_`) to control execution order reliably.

---

## Usage

All commands should be run from the root of the Q-SIS Updater directory in a PowerShell console.

### Standard Deployment

```powershell
.\Deploy-QSisUpdate.ps1 -UpdatePackagePath ".\Payloads\QSIS_v2.5.zip"
```

Uses `config.json` in the script directory by default.

---

### Dry Run (Recommended First Step)

Validates your configuration and SQL connectivity without making any changes to files or databases.

```powershell
.\Deploy-QSisUpdate.ps1 -UpdatePackagePath ".\Payloads\QSIS_v2.5.zip" -DryRun
```

During a dry run the script will:
- Confirm the ZIP file exists and is readable
- List the servers and paths it *would* deploy to
- **Test the SQL connection** to each configured database
- List the SQL scripts it *would* execute, in order
- Make **zero changes** to any files or databases

---

### Custom Config Path

Useful when managing multiple environments with separate config files.

```powershell
.\Deploy-QSisUpdate.ps1 -UpdatePackagePath ".\Payloads\QSIS_v2.5.zip" -ConfigPath ".\config.prod.json"
```

---

### Force Deployment Without a Backup

> ⚠️ **Use with caution.** This removes your ability to roll back if something goes wrong.

If the backup of a target server fails (e.g., the UNC path is temporarily unreachable), the deployment to that server is **blocked by default**. To override this and deploy anyway:

```powershell
.\Deploy-QSisUpdate.ps1 -UpdatePackagePath ".\Payloads\QSIS_v2.5.zip" -Force
```

---

### Combining Switches

```powershell
.\Deploy-QSisUpdate.ps1 -UpdatePackagePath ".\Payloads\QSIS_v2.5.zip" -ConfigPath ".\config.test.json" -DryRun
```

---

## Deployment Summary

After every run, the script prints a summary table showing the outcome of each step:

```
=========================================
 Deployment Summary
=========================================
[OK]   WebServer01 | Files
[OK]   WebServer02 | Files
[OK]   QSIS_Prod on SQLServer01 | SQL: 001_AlterTable.sql
[OK]   QSIS_Prod on SQLServer01 | SQL: 002_InsertData.sql
-----------------------------------------
All 4 deployment steps completed successfully.
```

| Icon | Meaning |
|------|---------|
| `[OK]` | Step completed successfully. |
| `[FAIL]` | Step failed. Remaining steps on other targets still attempted. |
| `[SKIP]` | Step was skipped because a backup could not be confirmed. Re-run with `-Force` to override. |
| `[DRY]` | Dry run — action was logged but not executed. |

The script exits with code `1` if any step failed or was skipped, making it compatible with Windows Task Scheduler failure detection.

---

## Logs

A timestamped log file is created in your configured `LogDirectory` for every run:

```
Logs\
└── QSisUpdate_20260523_131500.log
```

Each line is formatted as:
```
[2026-05-23 13:15:00] [Info] Loading configuration from: .\config.json
[2026-05-23 13:15:01] [Success] Backup completed successfully: F:\Backups\WebServer01_WebBackup_20260523_131500
[2026-05-23 13:15:03] [Warning] FAILED deploying to WebServer02: The network path was not found
```

---

## Scheduling with Windows Task Scheduler

To run a deployment automatically at a scheduled time:

1. Open **Task Scheduler** and create a new Basic Task.
2. Set the **Action** to `Start a program` with:
   - **Program:** `powershell.exe`
   - **Arguments:** `-ExecutionPolicy Bypass -NoProfile -File "F:\Tools\Q-SIS-Updater\Deploy-QSisUpdate.ps1" -UpdatePackagePath "F:\Tools\Q-SIS-Updater\Payloads\QSIS_v2.5.zip"`
   - **Start in:** `F:\Tools\Q-SIS-Updater\`
3. Under **General**, set the task to **Run whether user is logged on or not** and configure it to run under an account with the necessary network permissions.

---

## Project Structure

```
Q-SIS-Updater\
├── Deploy-QSisUpdate.ps1       # Main entry point — run this to deploy
├── config.json                 # Your environment config (not committed to Git)
├── config.example.json         # Safe template to copy and fill in
├── Modules\
│   ├── QSis.FileOps.psm1       # ZIP extraction, file backup, UNC deployment
│   ├── QSis.SqlOps.psm1        # SQL script discovery and execution
│   └── QSis.Logging.psm1       # Console + file logging
├── Payloads\                   # Drop your update ZIPs here (contents ignored by Git)
├── Backups\                    # Auto-created backups before each deployment
└── Logs\                       # Timestamped log files from each run
```
