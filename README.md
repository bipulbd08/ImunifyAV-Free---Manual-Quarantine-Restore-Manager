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
