# Skill: get-weekly-wx

Fetch WEATHERAmerica Newsletter posts from the public Google Group and generate weather forecast markdown files for Eastern Tennessee USA into the `WX/` directory.

---

## Execution context

This skill runs **unattended inside a systemd service** (`get-weekly-wx.service`). There is no user present to answer prompts. You must:

- Proceed autonomously through all steps without asking for confirmation.
- Never pause to ask "shall I proceed?" or request approval.
- Use `WebFetch` for all data retrieval — no Gmail or MCP tools are needed.
- If a step fails, log the error to stdout and continue rather than stopping.

---

## Step 1 — Discover recent WEATHERAmerica posts

Fetch the group listing page:

```
https://groups.google.com/g/weatheramerica
```

The page lists up to 30 recent posts with titles, dates, and relative URLs in the form `./g/weatheramerica/c/<id>`. Resolve each relative URL to `https://groups.google.com/g/weatheramerica/c/<id>`.

Filter the listing to posts whose date falls within the last **7 days** (WEATHERAmerica publishes on a weekly cycle). For each post in scope, classify it by forecast type based on the title (case-insensitive):

| Forecast Type | Title keywords |
|---|---|
| **Short Range** | `SHORT RANGE` |
| **Weather Hazards** | `WEATHER HAZARD`, `HAZARD`, `SPECIAL WEATHER` |
| **Medium Range** | `MEDIUM RANGE` |
| **Extended Period / 30-Day** | `EXTENDED PERIOD`, `EXTENDED FORECAST`, `30-DAY`, `30 DAY` |

Ignore posts with titles matching: `ANALOG`, `RONI`, `NINO`, `LINKS`, `EXTREMES`, `SATELLITE`, `ENSO`, `SEA SURFACE`, `SUMMER FORECAST`, `MONTHLY BREAKDOWN`, `JUNE WEATHER` — these are supplemental and do not contain synthesizable forecast text.

If no posts matching any forecast type are found within the last 7 days, write all three output files with the no-data message (see Steps 3–5) and stop.

---

## Step 2 — Fetch and parse each qualifying post

For each qualifying post URL, call `WebFetch` requesting the full subject line, date, author, and complete body text. Ask for the content verbatim rather than summarized.

From the returned content:

- The **subject line** confirms the forecast type (use it to override the title-based classification if needed).
- The **body text** is the forecast content. It may reference meteorological charts and model visualizations — ignore those references; synthesize only the textual forecast guidance.
- Extract all content relevant to **Eastern Tennessee**: the Ridge and Valley region, the Tennessee Valley, the Appalachians/Smoky Mountains, and geographic markers such as Knoxville, Chattanooga, Johnson City, Tri-Cities, or the Upper Tennessee River basin. If the post covers a broad national area with no Tennessee-specific section, synthesize general guidance for the region based on latitude, terrain, and proximity to the Gulf.

---

## Step 3 — Generate `WX/WX-THE-NEXT-72-HOURS.md`

**Source posts:** Short Range + Weather Hazards

Write a narrative prose forecast for the next 72 hours for Eastern Tennessee. Include:

- A title header: `# Weather summary for the next 72 hours`
- A datestamp header: `_Generated: YYYY-MM-DD HH:MM_`
- An overall opening sentence summarizing the dominant weather pattern
- Day-by-day prose (Today / Tonight / Tomorrow / Tomorrow Night / Day 3) — do not use a table, use flowing sentences
- A dedicated **Hazards** paragraph if any hazard information was present; lead it with `> **⚠️ Weather Hazard:**` as a blockquote. If no hazards were reported, omit this section entirely.
- Highlight temperature extremes, significant wind events, heavy precipitation, winter weather, or severe storm threats as they arise naturally in the narrative

If **neither** Short Range nor Weather Hazards posts were found, write:

```
# Weather summary for the next 72 hours

_Generated: YYYY-MM-DD HH:MM_

No forecast guidance for this time period was received from WEATHERAmerica.
```

---

## Step 4 — Generate `WX/WX-THIS-WEEK.md`

**Source posts:** Medium Range

Determine the current week span: the most recent Sunday through the coming Saturday. Write the file with:

```
# Weekly Forecast for [Day] [Month] [D] through [Day] [Month] [D]

_Generated: YYYY-MM-DD HH:MM_
```

Then for each day of that Sunday–Saturday week, write a section:

```
## [Day Name] — [Month D]

[Prose paragraph: high/low temps, precipitation chances, sky conditions, wind.
 Highlight any extreme or notable conditions inline.]
```

Maintain continuity across days — if a pattern persists (e.g. a multi-day rain event), acknowledge that in the narrative rather than repeating identical language.

If **no** Medium Range post was found, write:

```
# Weekly Forecast

_Generated: YYYY-MM-DD HH:MM_

No forecast guidance for this time period was received from WEATHERAmerica.
```

---

## Step 5 — Generate `WX/WX-NEXT-30-DAY.md`

**Source posts:** Extended Period Forecast (primary). If no Extended Period post was received, fall back to the Medium Range post and synthesize an extended outlook from whatever forward guidance it contains, noting the limitation in the datestamp line.

Write a narrative outlook for the next 30 days for Eastern Tennessee. Include:

- A title header: `# Weather summary for the next 30 days`
- A datestamp header: `_Generated: YYYY-MM-DD HH:MM_`
- A lead paragraph summarizing the overall pattern (above/below normal temps, wetter/drier than average, dominant systems)
- Week-by-week prose sections (Week 1, Week 2, Week 3–4) if the data supports that breakdown; otherwise write a single flowing extended outlook
- Call out any significant pattern shifts, blocking patterns, or notable events the guidance suggests

If **neither** an Extended Period post **nor** a Medium Range post was found, write:

```
# Weather summary for the next 30 days

_Generated: YYYY-MM-DD HH:MM_

No forecast guidance for this time period was received from WEATHERAmerica.
```

---

## Step 6 — Commit and push WX files

After writing all three output files, commit and push the changes to the journal repository:

```bash
cd "/home/kinscoe/Journal/Personal Journal"
git add WX/WX-THE-NEXT-72-HOURS.md WX/WX-THIS-WEEK.md WX/WX-NEXT-30-DAY.md
git commit -m "Weekly WEATHERAmerica updates"
git push
```

If any of the three files was not changed (no diff), git will simply skip it — that is expected. The push must succeed; if it fails, report the error.

---

## Notes

- Always overwrite existing files — these are expected to rotate with each invocation.
- All three files must be written on every run, even if some or all are no-data placeholders.
- The geographic scope for all synthesis is **Eastern Tennessee USA**: the Ridge and Valley region, the Unaka/Smoky Mountain terrain influence, and the Tennessee Valley corridor. Apply terrain-aware reasoning (e.g. mountain snow/rain shadowing, valley fog) where the data permits.
- Do not include image content or chart references from the posts.
- The group listing page shows the 30 most recent posts. This is always sufficient — WEATHERAmerica publishes 3–6 posts per week and a 7-day window will always fit within 30 results.
