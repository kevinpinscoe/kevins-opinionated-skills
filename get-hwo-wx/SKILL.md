# Skill: get-hwo-wx

Fetch the Hazardous Weather Outlook (HWO) issued by the National Weather Service Morristown TN (MRX) and write it as Markdown to `WX/WX-HAZARD.md` in the Personal Journal vault.

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

Write to `WX/WX-HAZARD.md` relative to the WorkingDirectory (the Personal Journal vault). Always overwrite the existing file.

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

## Step 4 — Commit and push

After writing the file, check whether the content changed and commit only if it did:

```bash
cd "/home/kinscoe/Journal/Personal Journal"
git add WX/WX-HAZARD.md
git diff --cached --quiet && echo "No change — skipping commit." || git commit -m "Update HWO"
git push
```

If the content is unchanged (diff is empty), print "No change detected — WX/WX-HAZARD.md is current." and do not commit. The push must succeed; if it fails, report the error to stdout.
