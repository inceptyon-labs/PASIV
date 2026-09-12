# TARS Registration (Phase 4m)

Register the project in `~/.tars/tars.db` so it appears in the TARS desktop app's project list with populated metadata. TARS is an optional personal tool, not a pasiv dependency.

**Preflight:**
```bash
pgrep -fl 'TARS.app/Contents/MacOS/tars-app|tars-desktop' && echo "warn: TARS is running"
```

The desktop binary is `tars-app` (inside `/Applications/TARS.app`), not `tars-desktop` — match both. If TARS is running, tell the user and ask whether to wait for them to quit, or proceed anyway. WAL mode makes concurrent writes safe, but the running app won't see the new metadata until it re-queries — the user must re-open the project (switch away and back) or restart the app after registration.

**Populate these fields from the repo-manifest (Phase 2) + answers (Phase 3).** Leave anything you can't confidently infer as `null` — the user can fill it in via the desktop app later.

| Field | Source |
|---|---|
| `description` | Phase 3 Question 4 answer |
| `icon_path` | Phase 4j logo path (relative to repo root), or existing logo found in the scan |
| `platforms` | Array of app-known tokens ONLY: `"Web"`, `"iOS"`, `"Android"`, `"macOS"`, `"Homebrew"`. Do NOT invent tokens like `"Desktop"` — an unknown value can fail enum deserialization and blank the whole panel. A macOS Tauri app is `["macOS"]`; a Cloudflare site is `["Web"]`. |
| `app_framework` | Detected primary framework (SvelteKit, Next, Expo, Tauri, Flutter…) |
| `web_hosting` | Cloudflare Workers, Vercel, Netlify, Fly.io, AWS, etc. — inferred from wrangler.toml, vercel.json, fly.toml, Dockerfile, etc. |
| `deploy_command` | From package.json `scripts.deploy` / `scripts.publish` / similar |
| `start_command` | From package.json `scripts.dev` / `scripts.start`, or `cargo run`, `flutter run`, etc. |
| `database_provider` | Neon, Supabase, Postgres, SQLite, Planetscale, etc. — inferred from deps (`@neondatabase/serverless`, `@supabase/*`, etc.) |
| `database_name` | From connection string in `.env.example` / `.dev.vars.example` (parse the path segment) |
| `github_url` | `https://github.com/<owner>/<name>` from Phase 3 answers |
| `ci_cd` | "GitHub Actions" if any `.github/workflows/*.yml` exists, else null |
| `monitoring` | Sentry / Datadog / etc. — inferred from deps |
| `ios_bundle_id` / `android_package_name` | Parse from `ios/` Info.plist / `android/app/build.gradle` if present |
| `custom_fields` | Array of `{key, value}` pairs for interesting signals that don't map to a standard field (backend framework if the web framework is frontend-only, ORM, test runner, email/LLM integrations, etc.) |

**CRITICAL — write the FULL schema, not just the fields above.** The app's `ProjectMetadata` struct does *not* tolerate missing keys: if any required field is absent, the whole row fails to deserialize and the app silently shows "No project info yet." Build the complete object with every key present at its typed default (`null` for strings, `false` for bools, `[]` for lists), then overlay the values you inferred. The builder below does exactly this — don't hand-write a partial dict.

**Insert via a single Python invocation** (Python 3 is always available on macOS/Linux, avoids shell-quoting pain with JSON values containing em-dashes, apostrophes, etc.):

```bash
python3 <<'PY'
import sqlite3, json, uuid
from datetime import datetime, timezone

now = datetime.now(timezone.utc).strftime('%Y-%m-%dT%H:%M:%S.%fZ')
path = "<absolute repo path>"       # e.g. "/Users/you/Development/myproj"
name = "<repo basename>"            # e.g. "myproj"

conn = sqlite3.connect('<expanded ~/.tars/tars.db>')
conn.execute("PRAGMA busy_timeout=5000")

row = conn.execute("SELECT id FROM projects WHERE path=?", (path,)).fetchone()
if row:
    pid = row[0]
    action = "existed"
else:
    pid = str(uuid.uuid4())
    project_data = {
        "id": pid, "path": path, "name": name,
        "git_info": None, "last_scanned": None, "assigned_profile_id": None,
        "local_overrides": {"mcp_servers": [], "skills": [], "agents": [], "hooks": []},
        "created_at": now, "updated_at": now,
    }
    conn.execute(
        "INSERT INTO projects (id, name, path, data, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?)",
        (pid, name, path, json.dumps(project_data), now, now),
    )
    action = "inserted"

# Full field set the app's ProjectMetadata struct expects. Every key MUST be
# present at a type-correct default, or the app rejects the row and shows
# "No project info yet." Build defaults first, then overlay inferred values.
STR_FIELDS = ["deploy_target","domain","production_url","staging_url","deploy_command",
  "database_provider","database_name","object_storage","object_storage_bucket","start_command",
  "tunnel_provider","tunnel_id","github_url","app_store_url","app_store_connect_url","play_store_url",
  "package_registry_url","ci_cd","monitoring","app_framework","web_hosting","ios_bundle_id",
  "description","android_package_name","android_min_sdk","android_target_sdk","android_signing_key",
  "android_deploy_command","google_play_console_url","ios_deploy_command","icon_path",
  "database_dashboard_url","ios_deploy_target","ios_signing_team","ios_cloudkit_container",
  "ios_cloudkit_dashboard_url","ios_provisioning","macos_bundle_id","macos_signing_team",
  "macos_app_category","macos_provisioning","homebrew_formula_name","homebrew_tap"]
BOOL_FIELDS = ["requires_tunnel","ios_uses_push_notifications","macos_hardened_runtime","macos_app_sandbox"]
LIST_FIELDS = ["custom_fields","platforms","ios_deploy_commands","android_deploy_commands",
  "macos_deploy_commands","homebrew_deploy_commands","deploy_commands","deploy_steps"]

metadata = {k: None for k in STR_FIELDS}
metadata.update({k: False for k in BOOL_FIELDS})
metadata.update({k: [] for k in LIST_FIELDS})

# Overlay the values inferred in Phase 2/3, e.g.:
#   metadata["description"] = "..."
#   metadata["platforms"] = ["macOS"]          # app-known tokens only
#   metadata["app_framework"] = "Tauri"
#   metadata["github_url"] = "https://github.com/<owner>/<name>"
#   metadata["custom_fields"] = [{"key": "...", "value": "..."}]

conn.execute(
    "INSERT OR REPLACE INTO project_metadata (project_id, data, updated_at) VALUES (?, ?, ?)",
    (pid, json.dumps(metadata), now),
)
conn.commit()
conn.execute("PRAGMA wal_checkpoint(TRUNCATE)")  # flush WAL into the main db file
conn.close()
print(f"{action}: {name} ({pid}) — {len(metadata)} metadata keys")
PY
```

**Notes:**
- `INSERT OR REPLACE` on `project_metadata` lets re-runs update the metadata without duplicating.
- `projects.path` is UNIQUE — the lookup-then-insert pattern preserves the existing UUID if the project is already registered.
- Do NOT write to `project_secrets` — that table is encrypted with a key the desktop app owns; writing plaintext would corrupt the encryption scheme.
- The `ProjectMetadata` struct requires the **full field set** (see the builder above). A partial row deserializes to nothing and the app shows "No project info yet." This is the #1 cause of a registration that "worked" but shows blank. It also means later edits to the project (CI removed, hosting changed) leave the row stale until you re-run — TARS only reflects reality at write time.
- The DB runs in WAL mode. After committing, run `conn.execute("PRAGMA wal_checkpoint(TRUNCATE)")` before closing so the main `tars.db` file reflects the write immediately (otherwise the change sits in `tars.db-wal` and the main file's mtime looks stale).
- To verify the write landed correctly, count the keys and confirm the panel is non-empty. A well-formed row carries all ~55 fields; if a hand-built row has only a dozen, it will be rejected.
- Registration is reversible: `DELETE FROM projects WHERE path='…'` or the desktop app's delete-project action.

Report the action in Phase 5's final review (either "Registered in TARS as `<uuid>`" or "Updated TARS metadata for existing project `<uuid>`").
