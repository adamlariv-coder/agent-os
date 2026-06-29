# Resource Index

Saved resources to learn from.
Each entry is either a **URL** (fetched via WebFetch) or a **local file path** (read from `personal/knowledge/resources/files/`).
On a refresh request, Claude processes each source, extracts relevant knowledge, and updates the target topic file.

---

## Refresh workflow

When asked to "refresh resources" or "refresh knowledge from resources":

1. Read this file — get all entries and their refresh targets
2. For each entry:
   - If **Source** is a URL → use `WebFetch` to retrieve it
   - If **Source** is a file path → use `Read` to load the local file
3. Extract relevant content (ignore nav, boilerplate, repeated chrome)
4. Update or create `personal/knowledge/topics/<target>.md` with what was learned
5. Update **Last refreshed** to today's date in this file
6. If a source fails (auth wall, missing file), note the error — do not skip silently

**File drop zone**: `personal/knowledge/resources/files/` — gitignored, not tracked.
Drop large files (PPTX, PDF, HTML exports) here, then reference them by path below.

---

## Entry format

```
### Title
- **Source**: https://... | personal/knowledge/resources/files/<filename>
- **Tags**: tag1, tag2
- **Refresh target**: personal/knowledge/topics/<file>.md
- **Last refreshed**: YYYY-MM-DD | never
- **Notes**: what this covers and why it's here
```

To add a new resource: append an entry below.
Set **Refresh target** to `new` if no topic file exists yet — Claude will create it on first refresh.
If a URL requires authentication, download the file to the drop zone and update **Source** to the local path.

---

## Resources

<!-- Add entries here -->
