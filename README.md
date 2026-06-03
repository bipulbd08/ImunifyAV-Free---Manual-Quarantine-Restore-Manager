# ImunifyAV Free - Manual Quarantine & Restore Manager

A high-performance, lightweight bash utility layer designed for standalone or cPanel-managed servers running **ImunifyAV (Free Edition)**. 

Since the free tier of ImunifyAV scans and detects malware but lacks an automated isolation/quarantine system, this tool bridges the gap. It allows system administrators to safely quarantine infected files into a secure root vault, clear them from the Imunify UI dashboard in bulk, keep audit trails, and interactively restore files if a false positive occurs.

---

## ⚙️ How It Works

The toolkit uses the native Imunify CLI and basic Linux file streams to safely isolate threats without needing a premium license:

1. **Threat Detection & Retrieval:** When executed, the tool queries the ImunifyAV database via its JSON API to pull all active, unresolved malicious file paths for a specific user or the entire server.
2. **Secure Isolation (Quarantine):** The files are instantly moved out of the user's web directory and into `/root/imunify_quarantine/[username]/`. To prevent file collisions and path duplication, each file is safely renamed using an MD5 hash of its original absolute path while maintaining its original file extension.
3. **Execution Lockdown:** Once inside the vault, the file permissions are completely stripped (`chmod 000`), ensuring that the malicious code cannot be executed by the system or accessed via the web.
4. **Dashboard Synchronization:** Instead of resolving files one by one, the script pools the processed paths and pushes a bulk stream command to the Imunify API. This instantly clears the processed threats from your cPanel Imunify UI dashboard in seconds.
5. **Audit Logging:** Every file action is written to a centralized history log, allowing the interactive restore engine to map files back to their precise origins, fix permissions (`644`), and restore proper cPanel user/group ownership.

---
## 🚀 Manual Installation
Step 1: Deploy the Quarantine & Restore Command Engine

Create the core binary container file:
Bash

nano /usr/local/bin/imunify-q

Paste the exact contents of the imunify-q file from this repository into the window. Save and exit (Ctrl+O, Enter, Ctrl+X).

Make the command binary globally executable by the system:
Bash

chmod +x /usr/local/bin/imunify-q

Step 2: Deploy the Automated Retention Cleanup Script

Create the background lifecycle rotation script file:
Bash

nano /usr/local/bin/imunify_purge_cron.sh

Paste the exact contents of the imunify_purge_cron.sh file from this repository into the window. Save and exit (Ctrl+O, Enter, Ctrl+X).

Grant execution permissions to the rotation utility:
Bash

chmod +x /usr/local/bin/imunify_purge_cron.sh

Step 3: Hook the Retention Utility Into System Automation

To ensure older malicious payloads are systematically purged from your root filesystem, manually hook the script into the root user's system crontab table.

Open the interactive cron table configuration window:
Bash

crontab -e

Navigate to the very bottom line of the file and insert the following automation string:
Code snippet

0 0 * * * /usr/local/bin/imunify_purge_cron.sh >/dev/null 2>&1

Save and close the file. The terminal will confirm with crontab: installing new crontab.
🔍 Verification Checklist

Verify that your manual installation was successful by running the command directly:
Bash

imunify-q

## 🚀 Quick One-Click Installation

Log into your server via SSH as the `root` user and execute the following command:

```bash
wget -O install.sh [https://raw.githubusercontent.com/bipulbd08/ImunifyAV-Free---Manual-Quarantine-Restore-Manager/main/install.sh](https://raw.githubusercontent.com/bipulbd08/ImunifyAV-Free---Manual-Quarantine-Restore-Manager/main/install.sh) && chmod +x install.sh && ./install.sh
