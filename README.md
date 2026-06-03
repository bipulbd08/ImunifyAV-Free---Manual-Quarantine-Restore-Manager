**ImunifyAV Free - Manual Quarantine & Restore Manager**:

---

````markdown
# ImunifyAV Free - Manual Quarantine & Restore Manager

A high-performance, lightweight bash utility layer designed for standalone or cPanel-managed servers running ImunifyAV (Free Edition).

Since the free tier of ImunifyAV scans and detects malware but lacks an automated isolation/quarantine system, this tool bridges the gap. It allows system administrators to safely quarantine infected files into a secure root vault, clear them from the Imunify UI dashboard in bulk, keep audit trails, and interactively restore files if a false positive occurs.

---

## ⚙️ How It Works

The toolkit uses the native Imunify CLI and basic Linux file streams to safely isolate threats without needing a premium license:

- **Threat Detection & Retrieval:**  
  When executed, the tool queries the ImunifyAV database via its JSON API to pull all active, unresolved malicious file paths for a specific user or the entire server.

- **Secure Isolation (Quarantine):**  
  The files are moved out of the user's web directory into `/root/imunify_quarantine/[username]/`.  
  To prevent collisions, each file is renamed using an MD5 hash of its original absolute path while preserving its original extension.

- **Execution Lockdown:**  
  Once inside the vault, file permissions are stripped (`chmod 000`), ensuring malicious code cannot be executed or accessed via the web.

- **Dashboard Synchronization:**  
  Processed threats are bulk-removed from the Imunify UI dashboard using API calls, clearing detections quickly.

- **Audit Logging:**  
  Every action is logged in a centralized history file, enabling traceability and safe restoration with correct permissions and ownership.

---

## 🚀 Manual Installation

### Step 1: Deploy the Quarantine & Restore Command Engine

Create the core binary file:

```bash
nano /usr/local/bin/imunify-q
````

Paste the contents of `imunify-q`, then save:

```
Ctrl + O → Enter → Ctrl + X
```

Make it executable:

```bash
chmod +x /usr/local/bin/imunify-q
```

---

### Step 2: Deploy the Automated Retention Cleanup Script

Create the cleanup script:

```bash
nano /usr/local/bin/imunify_purge_cron.sh
```

Paste the script contents, then save.

Make it executable:

```bash
chmod +x /usr/local/bin/imunify_purge_cron.sh
```

---

### Step 3: Add Cron Job for Auto Cleanup

Open cron editor:

```bash
crontab -e
```

Add this line at the bottom:

```bash
0 0 * * * /usr/local/bin/imunify_purge_cron.sh >/dev/null 2>&1
```

Save and exit.

---

## 🔍 Verification Checklist

Run the tool:

```bash
imunify-q
```

---

## 🚀 Quick One-Click Installation

Run this command as root:

```bash
wget -O install.sh https://raw.githubusercontent.com/bipulbd08/ImunifyAV-Free---Manual-Quarantine-Restore-Manager/main/install.sh && chmod +x install.sh && ./install.sh
```

---

```

---

If you want, I can also:
- improve it to **professional open-source GitHub standard (badges, structure, screenshots)**
- or rewrite it to look like a **commercial SaaS security tool page**
```
