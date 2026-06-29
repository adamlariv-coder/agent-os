# Agent Startup
Last updated: SCAFFOLD

## Sequence (always in this order)
1. `personal/agent/startup.md` ← you are here
2. `personal/memory/core/identity.md`
3. `framework/instructions/claude-code.md`

---

## Route a query → file to load

```bash
bash framework/agent/scripts/route.sh "QUERY"
```

---

## Indexes

| File | Contents | Rebuild |
|---|---|---|
| `personal/agent/topics-index.json` | All knowledge topics: path, status, updated, tags, summary | `build-index.sh` |
| `personal/agent/routing-manifest.json` | All routes: topics + skills + framework, queryable by trigger keyword | `build-index.sh` |
| `framework/skills/registry.json` | Installed skills: path, version, triggers | Manual (skill installs) |
| `personal/agent/framework-routes.json` | Static framework/memory/resource routing | Manual (rarely changes) |

---

## Quick queries

```bash
# All topics (key: updated | summary)
python3 -c "import json; [print(f'{k}: {v[\"updated\"]} | {v[\"summary\"][:70]}') for k,v in json.load(open('personal/agent/topics-index.json'))['topics'].items()]"

# Route keyword to file
bash framework/agent/scripts/route.sh "KEYWORD"

# Full-text search across knowledge
bash framework/agent/scripts/find-content.sh "KEYWORD" --knowledge

# Rebuild all indexes
bash framework/agent/scripts/build-index.sh

# Validate indexes are fresh and consistent
bash framework/agent/scripts/validate-indexes.sh
```

---

## After adding a topic file

1. Add `> status: active | created: YYYY-MM-DD | updated: YYYY-MM-DD` as line 1
2. `bash framework/agent/scripts/build-index.sh`
3. `bash framework/agent/scripts/validate-indexes.sh`
