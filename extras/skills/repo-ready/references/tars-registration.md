# TARS Registration (Phase 4m)

Register the project in `~/.tars/tars.db` so it appears in the TARS desktop app's project list with populated metadata. TARS is an optional personal tool, not a pasiv dependency.

**Preflight:**
```bash
pgrep -fl tars-desktop >/dev/null && echo "warn: tars-desktop is running — writes may race with the app"
```

If tars-desktop is running, tell the user and ask whether to wait for them to quit, or proceed anyway (WAL mode makes concurrent writes safe but the app won't see new rows until it re-queries).

**Populate these fields from the repo-manifest (Phase 2) + answers (Phase 3).** Leave anything you can't confidently infer as `null` — the user can fill it in via the desktop app later.

| Field | Source |
|---|---|
| `description` | Phase 3 Question 4 answer |
| `icon_path` | Phase 4j logo path (relative to repo root), or existing logo found in the scan |
| `platforms` | Array: `["Web"]`, `["iOS"]`, `["Android"]`, `["Desktop"]`, or combinations. Infer from detected stack (Expo → iOS+Android, SvelteKit/Next → Web, Tauri → Desktop, etc.) |
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

Leave the rest as `null` / `false` / `[]` defaults.

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

metadata = {
    # ... fields from the table above, with null/false/[] defaults for the rest
}

conn.execute(
    "INSERT OR REPLACE INTO project_metadata (project_id, data, updated_at) VALUES (?, ?, ?)",
    (pid, json.dumps(metadata), now),
)
conn.commit()
conn.close()
print(f"{action}: {name} ({pid})")
PY
```

**Notes:**
- `INSERT OR REPLACE` on `project_metadata` lets re-runs update the metadata without duplicating.
- `projects.path` is UNIQUE — the lookup-then-insert pattern preserves the existing UUID if the project is already registered.
- Do NOT write to `project_secrets` — that table is encrypted with a key the desktop app owns; writing plaintext would corrupt the encryption scheme.
- The ProjectMetadata Rust struct uses `#[serde(default)]` on every field, so omitting any field from the JSON is safe — it'll deserialize to the type's default when the app reads it.
- Registration is reversible: `DELETE FROM projects WHERE path='…'` or the desktop app's delete-project action.

Report the action in Phase 5's final review (either "Registered in TARS as `<uuid>`" or "Updated TARS metadata for existing project `<uuid>`").
