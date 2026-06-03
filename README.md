**ImunifyAV-Free---Manual-Quarantine-Restore-Manager**

````markdown id="final_readme_01"
# ImunifyAV Free - Manual Quarantine & Restore Manager

A high-performance, lightweight bash utility layer designed for standalone or cPanel-managed servers running ImunifyAV (Free Edition).

Since the free tier of ImunifyAV scans and detects malware but lacks an automated isolation/quarantine system, this tool bridges the gap. It allows system administrators to safely quarantine infected files into a secure root vault, clear them from the Imunify UI dashboard in bulk, keep audit trails, and interactively restore files if a false positive occurs.

---

## 🚀 Quick One-Click Installation

```bash
wget -O install.sh https://raw.githubusercontent.com/bipulbd08/ImunifyAV-Free---Manual-Quarantine-Restore-Manager/main/install.sh && chmod +x install.sh && ./install.sh
````

---

## ⚙️ How It Works

The toolkit integrates with ImunifyAV and Linux filesystem operations to safely handle malware without requiring a premium license:

* **Threat Detection & Retrieval:**
  Queries ImunifyAV system to collect all active malicious file paths for a user or full server.

* **Secure Isolation (Quarantine):**
  Moves infected files from web directories into `/root/imunify_quarantine/[username]/` and renames them using an MD5 hash of the original full path while preserving file extensions.

* **Execution Lockdown:**
  Applies strict permissions (`chmod 000`) to prevent execution, access, or web exposure.

* **Dashboard Synchronization:**
  Bulk-removes processed threats from the Imunify UI dashboard to keep it clean and synced.

* **Audit Logging:**
  Every action is logged inside `quarantine_history.log` for tracking, auditing, and safe restoration.

---

## 🚀 Manual Installation

### Step 1: Deploy Command Engine

```bash
nano /usr/local/bin/imunify-q
```

Paste script content, then save:

```bash
Ctrl + O → Enter → Ctrl + X
```

Make executable:

```bash id="mk7q1p"
chmod +x /usr/local/bin/imunify-q
```

---

### Step 2: Deploy Cleanup Script

```bash id="2h9xsw"
nano /usr/local/bin/imunify_purge_cron.sh
```

Make executable:

```bash id="q9v3dn"
chmod +x /usr/local/bin/imunify_purge_cron.sh
```

---

### Step 3: Add Cron Job

```bash id="c8lm2z"
crontab -e
```

Add:

```bash id="w1nq0x"
0 0 * * * /usr/local/bin/imunify_purge_cron.sh >/dev/null 2>&1
```

---

## 🔍 Verification

```bash id="v6k2mp"
imunify-q
```

---

## 💻 How To Use It

### 1. Quarantining Active Threats

* For a specific cPanel account:

```bash id="u2p9lz"
imunify-q --user [username]
```

* For entire server:

```bash id="x8q1dv"
imunify-q --all
```

---

### 2. Restoring Files (False Positives)

```bash id="r5n1cw"
imunify-q --restore [username]
```

Restores:

* Original file paths
* Permissions (`644`)
* Correct ownership

---

### 3. Checking Logs

```bash id="t3k9ab"
cat /root/imunify_quarantine/quarantine_history.log
```

---

### 4. Dry Run Mode

```bash id="y7m2ld"
imunify-q --scan
```

* No changes made
* Only shows detected threats

---

## 📌 Notes

* Designed for ImunifyAV Free limitation workaround
* Safe for cPanel & standalone Linux servers
* Keeps full audit trail for all actions

```

---

