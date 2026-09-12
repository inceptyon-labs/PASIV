# TARS update-in-place (Phase 7)

For a project that already has a `project_metadata` row. The row carries the full schema
the desktop app requires (~55 keys); read it, overlay the corrections, write it back. Do not
rebuild it from scratch and do not drop keys. If the row is missing, use the builder in
`../../repo-ready/references/tars-registration.md` instead.

```bash
python3 <<'PY'
import sqlite3, json, os
from datetime import datetime, timezone

path = os.getcwd()                     # repo root
db = sqlite3.connect(os.path.expanduser("~/.tars/tars.db"))
db.execute("PRAGMA busy_timeout=5000")
row = db.execute(
    "select p.id, m.data from projects p join project_metadata m on m.project_id=p.id where p.path=?",
    (path,)).fetchone()
if not row:
    raise SystemExit("no TARS row for this path; use the repo-ready builder")
pid, m = row[0], json.loads(row[1])

# Overlay only what the manifest contradicts. Examples:
#   m["deploy_target"]   = "Uranus (Unraid, 192.168.2.222)"
#   m["deploy_command"]  = "deploy   # or /acp on main (.deploy marker)"
#   m["production_url"]  = "http://192.168.2.222:8087"
#   m["icon_path"]       = "assets/logo.svg"
#   m["start_command"]   = "cd dashboard && npm run dev"
# Custom fields are a list of {key, value}; update by key, keep the rest:
cf = {c["key"]: c for c in m.get("custom_fields", [])}
#   cf["Agents"] = {"key": "Agents", "value": "..."}
m["custom_fields"] = list(cf.values())

now = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%S.%fZ")
db.execute("update project_metadata set data=?, updated_at=? where project_id=?",
           (json.dumps(m), now, pid))
db.commit()
db.execute("PRAGMA wal_checkpoint(TRUNCATE)")
print(f"updated {pid}: {len(m)} keys")
PY
```

Rules:
- `platforms` takes only `"Web"`, `"iOS"`, `"Android"`, `"macOS"`, `"Homebrew"`.
- Never touch `project_secrets`.
- The app shows the change after a restart or after switching projects.
