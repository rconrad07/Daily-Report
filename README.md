# Daily Intelligence Report System

## Implementation Context

This codebase implements a scrupulous, multi-agent pipeline designed to generate high-density Daily Intelligence Reports. It prioritizes **data integrity**, **citation reliability**, and **structural precision**. The system is designed for execution by a primary Orchestrator agent that coordinates specialized sub-agents.

## 🏗️ System Architecture

```ascii
[ Data Sourcing ]      [ Intelligence Processing ]      [ Validation & Guardrails ]
      |                          |                                 |
      v                          v                                 v
+--------------+        +------------------+             +-----------------------+
|   CURATOR    | ---->  |    SUMMARIZER    | ----------> |         FILTER        |
| (Search,     |        | (Fact Extraction,|             | (De-duplication,      |
| Deep Links)  |        |  Summarization)  |             |  Noise Removal)       |
+--------------+        +------------------+             +-----------------------+
                                 |                                 |
                                 v                                 v
                        +------------------+             +-----------------------+
                        |    FORMATTER     | <---------- |        ARBITER        |
                        | (HTML/UX Styling,|             | (Audit, Scoring,      |
                        |  Templating)     |             |  Citation Check)      |
                        +------------------+             +-----------------------+
                                 |                                 |
                                 v                                 v
                        +------------------+             +-----------------------+
                        |  SELF-HEALING    |             |       GATEKEEP        |
                        | (URL Validator,  | ----------> | (Final Report &       |
                        |  Structure Test) |             |  Manifest Update)     |
                        +------------------+             +-----------------------+
```

## 🛠️ Core Components

### 1. Agents & prompts

- **Curator** (`/agents/curator/prompt.md`): Sourcing specialist. Enforces "Article-Level Deep Linking" and premarket data gathering.
- **Summarizer** (`/agents/summarizer/prompt.md`): Distillation expert. Strips footnote markers, preserves technical metrics, and ensures chronological context.
- **Filter** (`/agents/filter/prompt.md`): Quality gate. Performs history-aware deduplication against previous reports.
- **Formatter** (`/agents/formatter/prompt.md`): UI/UX engineer. Applies `dashboard_template.html` and ensures numeric-only stock columns.
- **Arbiter** (`/agents/arbiter/prompt.md`): Auditor. Scores reports (0-100) using strict calibration examples; acts as the primary quality judge.

### 2. Orchestration & Contracts

- **Orchestrator** (`/orchestrator/orchestrator.md`): The "brain" defining the sequential execution, data handling, and error-recovery rules.
- **Schemas** (`/schemas/agent_contracts.json`): Formal JSON definitions for agent I/O, ensuring data contract enforcement across the pipeline.

### 3. Validation Gates (The "Self-Healing" Layer)

- **URL Validator** (`/scripts/validate_urls.ps1`): Verifies every citation in the generated HTML. If a link fails, the system is instructed to purge the associated content from the report.
- **Structure Test** (`/scripts/test_report_structure.ps1`): Validates section order, CSS class presence, and ensures no unresolved template placeholders (e.g., `{{TOKEN}}`) exist.

## 📁 Directory Mapping

- `/config`: Watchlists, tickers, and domain-specific keywords.
- `/evals`: Detailed logs of Arbiter and Manual evaluations (used for iterative calibration).
- `/reports`: The final HTML output. Includes `reports_manifest.json` for history tracking.
- `/templates`: The core `dashboard_template.html` used for report rendering.
- `/logs`: Artifacts of the URL validation runs.

## 🚀 Execution Flow

1. **Source**: Run Curator based on `config/*.md` and `orchestrator.md`.
2. **Process**: Pipeline data through Summarizer -> Filter.
3. **Draft**: Formatter generates initial HTML from `dashboard_template.html`.
4. **Clean**: Validate URLs and purge broken fragments.
5. **Verify**: Run Arbiter audit and Structure Tests.
6. **Publish**: Rebuild manifest and archive old reports.

---
*Target Audience: AI agents / LLMs designed for autonomous coding and project management.*
