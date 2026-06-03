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

## 🚀 Quick One-Click Installation

Log into your server via SSH as the `root` user and execute the following command:

```bash
wget -O install.sh [https://raw.githubusercontent.com/bipulbd08/ImunifyAV-Free---Manual-Quarantine-Restore-Manager/main/install.sh](https://raw.githubusercontent.com/bipulbd08/ImunifyAV-Free---Manual-Quarantine-Restore-Manager/main/install.sh) && chmod +x install.sh && ./install.sh

What the install.sh script does:

To maintain full security and transparency, the installation script automates the following backend operations upon execution:

    Privilege Validation: Verifies the current shell execution context has root access ($EUID -ne 0) before making changes.

    Core Utility Deployment: Automatically writes the optimized, high-performance imunify-q command string directly to the binary path /usr/local/bin/imunify-q.

    Cleanup Engine Setup: Deploys the automated lifecycle background worker script into /usr/local/bin/imunify_purge_cron.sh.

    Permissions Enforcement: Formally assigns global executable attributes (chmod +x) to both newly created binary applications.

    Cron Automation: Programmatically reviews the active root system crontab table. It checks for and removes any matching legacy or dead installations of this toolkit, then hooks a clean entry setting the retention utility to run exactly at midnight (00:00) on autopilot every single night.

💻 How To Use It
1. Quarantining Active Threats

The script operates in a quiet batch mode. It processes files rapidly in memory and clears the Imunify UI dashboard records using a high-performance bulk stream, printing clean progress indicators instead of scrolling text.

    Isolate malware for a specific account:

Bash

    imunify-q --user [username]
    ```

* **Isolate all malware detected globally across the entire server:**
```bash
    imunify-q --all
    ```

---

### 2. Restoring Files (Handling False Positives)

If a legitimate document or asset triggers a false positive, you can reverse the quarantine using the interactive CLI restore module.

```bash
imunify-q --restore [username]

What happens behind the scenes during a restore:

    The file is moved back to its exact original folder path.

    File security states are safely reset to standard readable web flags (644).

    The script checks the system user database and automatically updates file ownership back to the correct account user and group context (username:username), ensuring the website can read it instantly without throwing permission blocks.

3. Automated Retention & Cleanup (Cron)

The secondary script (imunify_purge_cron.sh) triggers every single night at midnight via crontab on autopilot:

    14-Day Purge: It scans the storage bunker and permanently deletes any isolated malicious payloads older than 14 days.

    Directory Management: It prunes out empty user directories once all their quarantined payloads have reached the 14-day deletion limit, keeping the root storage footprint clean.

    Log Rotation: It automatically cuts the tracking log history down to the freshest 5,000 lines to prevent data inflation over time.

File Layout & Vault Architecture

Isolated payloads are systematically renamed into unique MD5 strings matching their original absolute path to prevent duplication, then completely stripped of execution capabilities (chmod 000) within secure user directories:
Plaintext

/root/imunify_quarantine/
├── user_1/                      # User isolated subdirectories
│   ├── md5_hash_filename.jpg    # Permissions locked securely to 000
│   └── md5_hash_filename.pdf
├── user_2/
│   └── md5_hash_filename.php
└── quarantine_history.log       # Centralized audit map tracking restore locations

Security Design Fail-Safes

    Path Trapping: The retention cleanup system incorporates a strict conditional checkpoint (if [ -n "$QUARANTINE_BASE" ] && [ -d "$QUARANTINE_BASE" ]) to prevent accidental, catastrophic root directory cleanup if a variable ever drops or unsets in the shell environment.

License

This project is open-source software licensed under the MIT License.
