# Skill: get-hwo-wx

Fetch the Hazardous Weather Outlook (HWO) issued by the National Weather Service Morristown TN (MRX) and write it as Markdown to `WX/WX-HAZARD.md` in the personal-journal vault.

---

## Execution context

This skill runs **unattended inside a systemd service** (`get-hwo-wx.service`). There is no user present to answer prompts. You must:

- Proceed autonomously through all steps without asking for confirmation.
- Never pause to ask "shall I proceed?" or request approval.
- Use `WebFetch` for all data retrieval — do not use Gmail or any MCP tools.
- If a step fails, log the error to stdout and continue rather than stopping.

---

## Step 1 — Fetch the HWO product

Fetch the plain-text HWO product:

```
https://forecast.weather.gov/product.php?site=NWS&issuedby=MRX&product=HWO&format=txt&version=1&glossary=0
```

Request the verbatim text content. The page returns the raw NWS HWO text product — no HTML parsing is needed.

---

## Step 2 — Parse the HWO text

The text product follows standard NWS formatting:

- A WMO header block at the top (product type code, office ID, timestamp) — skip everything before the first section header
- An issuance time line (e.g., `249 AM EDT Sun Apr 12 2026`) — extract this for the generated header
- Section blocks introduced by `.SECTIONNAME...Description` headers
- A `$$` terminator at the end — discard this line

Typical sections:

| NWS header | Markdown heading |
|---|---|
| `.DAY ONE...Today and Tonight` | `## Day One — Today And Tonight` |
| `.DAYS TWO THROUGH SEVEN...Monday through Saturday` | `## Days Two Through Seven — Monday Through Saturday` |
| `.SPOTTER INFORMATION STATEMENT...` | `## Spotter Information Statement` |

Extract:
1. The **issuance time line** from the header block
2. All section blocks from the first `.` header through (but not including) `$$`

---

## Step 3 — Write `WX/WX-HAZARD.md`

Write to `WX/WX-HAZARD.md` relative to the WorkingDirectory (the personal-journal vault). Always overwrite the existing file.

Format:

```markdown
# Hazardous Weather Outlook

_Generated: YYYY-MM-DD HH:MM UTC — Source: National Weather Service Morristown TN — [forecast.weather.gov HWO](https://forecast.weather.gov/product.php?site=NWS&issuedby=MRX&product=HWO&format=txt&version=1&glossary=0)_

**Issued: <issuance time line>**

## <Section Name Title Case> — <Section Description Title Case>

<Section body: collapse runs of 3+ blank lines to one blank line; preserve paragraph breaks>

## <Next Section>

<Body>
```

Conversion rules:
- Convert `.SECTIONNAME...Description` to `## Section Name — Description` with both parts in title case
- If the description part is empty (e.g., `.SPOTTER INFORMATION STATEMENT...`), omit the ` — ` and description
- Strip the `$$` terminator line
- Collapse 3+ consecutive blank lines to a single blank line
- Do not include WMO header lines, product type codes, or zone/county code lines — only the issuance time and sections

---

## Step 4 — Regenerate the WX index (`WX/wx.md`)

After writing `WX/WX-HAZARD.md`, regenerate the index file `WX/wx.md` so its **Hazardous Weather Outlook** row reflects the outlook you just wrote. This is the human-facing table of contents for the `WX/` directory in Obsidian, shared with the `get-weekly-wx` skill.

Build the index by reading the current state of the four WX files (`WX-HAZARD.md`, which you just wrote, plus the three forecast files maintained by `get-weekly-wx`). For each file's **Created** value, use the timestamp from that file's own `_Generated:` header line; if a file has no such header, fall back to its filesystem modification time.

Overwrite `WX/wx.md` with exactly this structure:

```
---
tags:
  - weather
aliases: []
action: generated
---

# Weather Forecast Index

_Index regenerated: YYYY-MM-DD HH:MM UTC_

| Forecast | File | Created |
|---|---|---|
| Weather summary for the next 72 hours | [WX-THE-NEXT-72-HOURS.md](WX-THE-NEXT-72-HOURS.md) | <created> |
| <title of WX-THIS-WEEK.md, e.g. Weekly Forecast for Sunday July 12 through Saturday July 18> | [WX-THIS-WEEK.md](WX-THIS-WEEK.md) | <created> |
| Weather summary for the next 30 days | [WX-NEXT-30-DAY.md](WX-NEXT-30-DAY.md) | <created> |
| Hazardous Weather Outlook | [WX-HAZARD.md](WX-HAZARD.md) | <created> |
```

Notes:

- The `_Index regenerated:` line is the current UTC time of this run.
- The **Forecast** column is each file's human-readable title (the `# ` heading text). For `WX-THIS-WEEK.md`, use its full week-span title.
- Preserve the frontmatter block (`tags`, `aliases`, `action`) exactly as shown.
- If any of the three forecast files does not yet exist, omit its row rather than writing a broken link.
- `WX/wx.md` is **gitignored** (generated index content) — write it to disk only. Do **not** `git add` it in Step 5; Obsidian reads it directly from disk.

---

## Step 5 — Commit and push

After writing the file, check whether the content changed and commit only if it did:

```bash
cd "/home/kinscoe/Journal/personal-journal"
git add WX/WX-HAZARD.md
git diff --cached --quiet && echo "No change — skipping commit." || git commit -m "Update HWO"
git push
```

If the content is unchanged (diff is empty), print "No change detected — WX/WX-HAZARD.md is current." and do not commit. The push must succeed; if it fails, report the error to stdout.

> Note: `WX/WX-HAZARD.md` and `WX/wx.md` are both gitignored (generated content), so this step typically stages nothing and reports "No change" — the on-disk file updates are the operative result. Do not force-add either path.
