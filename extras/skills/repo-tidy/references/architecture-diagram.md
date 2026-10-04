# Architecture diagram (Phase 5b)

Every project keeps an Archify system overview at `docs/architecture.json`, pinned to a
commit with file:line sources, plus a note in its agent file saying when to refresh it.
Rendered output lives in `.archify/`, which is gitignored. CLI:
`node ~/.claude/skills/archify/bin/archify.mjs`.

## Decide: create, refresh, or leave alone

- **No `docs/architecture.json`**: create it.
- **Spec exists**: run
  `node ~/.claude/skills/archify/bin/archify.mjs validate architecture docs/architecture.json --quality showcase --repo-root . --json`.
  A failure (a cited file deleted, renamed, or shortened) means refresh.
- **Spec validates**: run `git diff --stat <meta.repository.revision>..HEAD` and look for
  structural change only. Refresh if the range has any of these:
  - an added or removed app, package, crate, or service directory
  - a new external API client
  - changed compose, wrangler, Dockerfile, or deploy files
  - a new trust boundary (auth, a sandbox, a process split)

  Edits inside existing modules don't count. Neither do shifted line numbers.
- **No runtime at all** (docs only): skip it and say so.

## Create

Use this prompt verbatim. It is the one every existing spec was built from:

> Analyze this repository, then use Archify to create a high-level architecture diagram.
> Show 8–12 core runtime components, one primary request or data path, external
> dependencies, ownership or trust boundaries, and put supporting detail in cards instead
> of adding more edges.

For a small repo (a static site, a CLI, or a skills package), show what is real and never
invent components to reach 8.

1. Add the `.gitignore` entry first, so nothing that sweeps the tree (`/acp`, memex's
   nightly `git add -A`) can pick up render output:
   ```
   # Archify diagram output (local, regenerated on demand)
   .archify/
   ```
2. Invoke the `archify` skill and follow its repository-backed path. Edges show the actual
   actor: draw a write from the code that performs it, not from a neighbouring component.
3. Run `finalize architecture <candidate> <html> --repo-root . --quality showcase --json`.
   Then run `visual-check <html> --summary --require-provenance --out-dir <folder>/visual-check`
   and read the 2048x1320 dark PNG. Fix real overlaps or crossings, then re-finalize with
   `--out-dir <folder>/review-2`. Re-running into the same folder fails with an
   evidence-path conflict.
4. Run `cp <folder>/candidate.json docs/architecture.json`, then validate it from the repo
   root with the command above.
5. Add the agent note (below).

## Refresh

1. Copy `docs/architecture.json` into a new
   `.archify/architecture-<name>-overview-<YYYYMMDD-HHMMSS>/candidate.json`.
2. Set `meta.output` to that folder and re-pin `meta.repository.revision` to HEAD.
3. Update only the nodes, edges, sources, and cards the change touched.
4. Run Create steps 3 and 4. The note already exists.

## The agent note

Put the note in `AGENTS.md`. If only `CLAUDE.md` exists, put it there. If neither exists,
scaffold the file through the `agents-md` skill first.

**Exception:** an `AGENTS.md` that is loaded globally gets the note in `CLAUDE.md`
instead. Otherwise every session in every project would read it. A file is loaded globally
if `~/.claude/CLAUDE.md` imports it or `~/.codex/AGENTS.md` symlinks to it. Today that is
`~/memex/AGENTS.md`.

Insert the note before `## Deploy` if that heading exists, otherwise at the end. Adapt only
the parenthetical, and drop "or the deploy shape" if the project has no deployment.

```markdown
## Architecture diagram

`docs/architecture.json` is the Archify spec for the system overview
(<components, the primary path, trust boundaries, external services>), with
file:line sources pinned to a commit. If a change adds, removes, or rewires a
top-level component, external service, trust boundary, or the deploy shape,
update the spec after committing it: re-pin `meta.repository.revision` to
that commit, fix the affected nodes, edges, and sources, re-render with the
`archify` skill (`finalize ... --repo-root .`), and commit the spec. Internal
refactors and shifted line numbers don't need it. Rendered HTML goes in
`.archify/` (gitignored).
```

## Gotchas

- **Committed bytes only.** Evidence is checked against committed bytes at the pinned
  revision. For a dirty file, cite the line numbers from `git show HEAD:<path>`.
- **SSH origins.** Pin the exact URL `git remote get-url origin` prints, with
  `link_mode: "local-only"`. Web links need a GitHub or Gitee HTTPS origin.
- **`root@` remotes.** Upstream Archify only accepts the SSH user `git`. hoodmint, memex,
  and paydirt use `ssh://<ssh-target>/...` and work only because of a local patch in
  `~/.agents/skills/archify/renderers/shared/repository-location.mjs`. The patch accepts
  any SSH user and keeps it in the canonical URL. If `finalize` fails with
  `origin-mismatch` or `url-invalid` on such a remote, an Archify update reverted the
  patch. Report it. Do not rewrite the remote.
