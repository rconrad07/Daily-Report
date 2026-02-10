# 9 AM Report Automation Setup Guide

This guide explains how to automate your Daily Intelligence Report using Windows built-in tools.

## Phase 1: Gmail App Password

1. Go to your [Google Account Security settings](https://myaccount.google.com/security).
2. Enable **2-Step Verification** if not already active.
3. Search for **App passwords** in the search bar.
4. Create a new password:
    - **App**: Mail
    - **Device**: Windows Computer
5. Copy the **16-character code** (e.g., `abcd efgh ijkl mnop`).

## Phase 2: Configuration

1. Open `config/email_config.json`.
2. Update the `sender_email` and `recipient_email` with your details.

## Phase 3: Setup Task Scheduler

1. Press `Win + R`, type `taskschd.msc`, and hit Enter.
2. Click **Create Basic Task...** on the right.
3. **Name**: Daily Intelligence Report.
4. **Trigger**: Daily, recur every 1 day, select **9:00:00 AM**.
5. **Action**: Start a program.
6. **Program/script**: `powershell.exe`
7. **Add arguments (Copy & Paste)**:
    - Replace `[PATH_TO_SCRIPT]` with the full path to `SendReport.ps1`.
    - Replace `[PASSWORD]` with your 16-character App Password.

    ```text
    -ExecutionPolicy Bypass -File "[PATH_TO_SCRIPT]" -AppPassword "[PASSWORD]"
    ```

8. Click **Finish**.

## Phase 4: Verification

- To test immediately, find your task in the "Task Scheduler Library", right-click it, and select **Run**.
- Check `logs/email_log.txt` (to be implemented) or your inbox for the report.
