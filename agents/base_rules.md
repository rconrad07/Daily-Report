# Base Rules — Shared Agent Governance

All agents in this pipeline inherit the following rules. Individual SKILL.md files reference this document and do not need to repeat these constraints.

## Citation Rules

- Only include source URLs that appear verbatim in your search results. Never generate, guess, or infer a URL.
- Every item MUST include a working, article-level deep link.
- A valid citation MUST resolve directly to the referenced article — not a homepage, category page, search page, or login wall.
- Never use shortened links, tracking links, or generic domain homepages.
- If no verifiable URL exists for a claim, either omit the claim or state "No verified source available."

## Deduplication Rules

- Scan previous reports in `/reports/` before including any item. Do NOT include news already covered in a previous daily report.
- A story may only be included if it contains a **significant new development** not present in any prior report.

## Data Integrity Rules

- All numeric data (prices, percentages, volume) MUST specify the exact timeframe (e.g., "premarket", "as of 9:30 AM ET", "since prior close").
- Never use ambiguous or relative time descriptions (e.g., "recently", "today" without a time anchor).

## Output Discipline

- Be concise. Do not generate content beyond what is required by the task.
- Do not produce markdown output where HTML is expected, or vice versa.
- Do not add footnote markers like `[1]`, `[2]` unless they link to a defined source within the same document.
