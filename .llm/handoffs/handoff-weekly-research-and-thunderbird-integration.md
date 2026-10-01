# Handoff: Weekly Research and Thunderbird Integration

## Goal
Establish an automated recurring weekly research workflow tracking deterministic AI agent architectures and safely deliver reports to the user's Thunderbird email environment without mailbox corruption or unnecessary credential management.

## Key Invariants & Architectural Decisions
- **Deterministic vs. Probabilistic Separation:** LLM handles cognitive synthesis and unstructured information parsing; POSIX Bourne shell scripts handle file generation, timestamps, validation, and delivery.
- **Mailbox Integrity Protection:** Cease all direct append operations to raw local MBOX files (`./Profiles/.../Mail/...`) and index files (`*.msf`). Live mailboxes must remain strictly read-only to external tools to prevent data loss or desynchronization.
- **Delivery Selection (Path One):** Adopt Thunderbird's native `-compose` command-line IPC interface. This eliminates the need for managing Google App Passwords, avoids storing credentials in plaintext scripts, and removes all risk of mailbox corruption.

## Weekly Research Specification
- **Cadence:** Weekly execution (recommended via cron on Monday mornings).
- **Core Topics:**
  - Instruction engineering, RFC 2119 keywords, and formal contract definitions.
  - Skill dispatch protocols (e.g., Model Context Protocol, POSIX tool integration).
  - Linter-driven feedback loops and self-correcting agent harnesses.
- **Delivery Format:** Plain UTF-8 Markdown, LF line endings, no decorative Unicode or hype prose, matching repository invariants (`INV-PROSE`, `INV-NAME`, `INV-CHARS`).

## Delivery Options Summary
1. **Path 1: Thunderbird Native Compose CLI (`thunderbird -compose`) [Active Choice]**
   - Invokes the running application directly via IPC.
   - Zero credentials or tokens required; relies on the active desktop session.
   - Completely safe; no direct disk or MBOX manipulation.
2. **Path 2: SMTP via `curl` (`smtps://smtp.gmail.com:465`)**
   - Silent background delivery into Gmail cloud inbox; Thunderbird pulls down on sync.
   - Requires generating and storing a 16-character Google App Password.
3. **Path 3: Raw MBOX Append [Rejected]**
   - High risk of corrupting existing local mail archives or desynchronizing `.msf` indices.

## Active State
- Repository invariants (`INV-PROSE`, `INV-NAME`, `INV-CHARS`, `INV-HAND`) remain authoritative.
- Path One is slated for initial validation on the user's workstation.

## Next Steps
1. Execute the baseline Path One smoke test from the terminal:
   ```sh
   thunderbird -compose "to='ray@local',subject='Weekly Agent Architecture Research Test',message='/tmp/weekly-research.txt'"
   ```
2. Confirm the compose window launches cleanly with the text payload loaded.
3. Integrate the validated command into `scripts/run-weekly-research.sh`.
