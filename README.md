# Daily Intelligence Report System

## Implementation Context

This codebase implements a scrupulous, multi-agent pipeline designed to generate high-density Daily Intelligence Reports. It prioritizes **data integrity**, **citation reliability**, and **structural precision**. The system is powered by a **RALPH (Reasoning, Action, Logging, Process, Healing) loop** that ensures self-correction through targeted re-invocation.

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
      ^                          |                                 |
      |                          v                                 v
      |                 +------------------+             +-----------------------+
      |                 |    FORMATTER     | <---------- |        ARBITER        |
      |                 | (HTML/UX Styling,|             | (Atomic Judges,       |
      |                 |  Templating)     |             |  Weighted Scoring)    |
      |                 +------------------+             +-----------------------+
      |                          |                                 |
      |                          v                                 v
      |                 +------------------+             +-----------------------+
      +------- [RALPH]--|  SELF-HEALING    | <---------- |       GATEKEEP        |
                        | (Targeted Retry, |             | (Final Report &       |
                        |  URL Validator)  |             |  Manifest Update)     |
                        +------------------+             +-----------------------+
```

## 🛠️ Core Components

### 1. Agents & Skills

Agents utilize a structured `SKILL.md` format with mandatory `<thinking>` blocks and XML-tagged outputs.

- **Curator** (`/agents/curator/SKILL.md`): Sourcing specialist. Enforces "Article-Level Deep Linking" and premarket data gathering.
- **Summarizer** (`/agents/summarizer/SKILL.md`): Distillation expert. Strips footnote markers, preserves technical metrics, and ensures chronological context.
- **Filter** (`/agents/filter/SKILL.md`): Quality gate. Performs history-aware deduplication against previous reports and ranks remaining items globally.
- **Formatter** (`/agents/formatter/SKILL.md`): UI/UX engineer. Applies the dashboard template and ensures premium styling (numeric stock columns, glassmorphism).
- **Arbiter** (`/agents/arbiter/SKILL.md`): Auditor. Uses four **atomic binary judges** (Citation, Data, Structure, Content) and weighted scoring (0-100) to assess report quality.

### 2. Orchestration & Contracts

- **Orchestrator** (`/orchestrator/orchestrator.md`): The central logic defining the sequential execution, versioning rules, and the **RALPH self-healing loop**.
- **Schemas** (`/schemas/agent_contracts.json`): Formal JSON definitions for agent I/O, ensuring data contract enforcement across the pipeline.

### 3. Validation Gates (The "Self-Healing" Layer)

- **URL Validator** (`/scripts/validate_urls.ps1`): Verifies every citation in the generated HTML. Broken links trigger content purging.
- **Arbiter Evaluation**: If the Arbiter score falls below 70, it identifies a `responsible_agent` for each failure, triggering a targeted re-invocation (the RALPH loop).
- **Structure Test** (`/scripts/test_report_structure.ps1`): Final structural gate verifying DOM order and template integrity.

## 📁 Directory Mapping

- `/config`: Watchlists, tickers, and domain-specific keywords.
- `/evals`: Detailed logs of Arbiter audits and RALPH retry events.
- `/reports`: The final HTML output. Includes `reports_manifest.json` for history tracking.
- `/templates`: The core `dashboard_template.html` used for report rendering.
- `/logs`: Artifacts of URL validation and pipeline execution.

## 🚀 Execution Flow

1. **Source**: Run Curator based on `config/*.md` and global rules.
2. **Process**: Pipeline data through Summarizer -> Filter.
3. **Draft**: Formatter generates initial HTML from `dashboard_template.html`.
4. **Clean**: Validate URLs and purge broken fragments from the DOM.
5. **Evaluate**: Arbiter audit renders a weighted score (Citation 30%, Data 25%, Structure 25%, Content 20%).
6. **Heal (RALPH)**: If failing, re-invoke the upstream-most failing agent with corrective findings (max 1 retry).
7. **Verify**: Final Arbiter audit and Structure Tests.
8. **Publish**: Rebuild manifest and archive old reports.

---
*Target Audience: AI agents / LLMs designed for autonomous coding and project management.*
