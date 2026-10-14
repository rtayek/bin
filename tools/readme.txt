The Thunderbird workflow is isolated to one script. The other files are a separate report-generation test and its outputs; nothing connects the two.

### Relevant files

- [send-dummy-report.sh](C:\Users\ray\bin\tools\send-dummy-report.sh:1) locates the first Thunderbird `Local Folders` directory, constructs an RFC-like message with fixed “Agent Architecture Research” text, and directly appends it to the extensionless `Inbox` mbox. It does not perform research, read another report, or send mail through a mail service.
- [task1.sh](C:\Users\ray\bin\tools\task1.sh:1) changes to the user’s home directory and saves the first ten entries from `ls -lt` as a timestamped `.md` file. It neither invokes `send-dummy-report.sh` nor interacts with Thunderbird.
- `task1-2026-09-27-1701.md`, `task1-2026-09-28-1701.md`, and `task1-2026-09-29-1701.md` are generated directory listings. Their identical 17:01 timestamps strongly suggest an external daily scheduler, but scheduled-task inspection was denied, so I could not confirm its configuration.

### Material risks

- [Line 25](C:\Users\ray\bin\tools\send-dummy-report.sh:25) appends directly to Thunderbird’s live mbox without coordinating locks or indexes. Thunderbird is currently running, making stale indexing, invisible messages, concurrent-write damage, and possible mailbox corruption the principal concern.
- The script’s success message proves only that the filesystem append succeeded. A previous observed run remained invisible until Thunderbird restarted and rebuilt its index.
- [Line 12](C:\Users\ray\bin\tools\send-dummy-report.sh:12) takes the first directory named `Local Folders`, rather than resolving Thunderbird’s selected profile. There is currently only one such directory, under `zghw16oz.default`, but the method is brittle if another profile is added.
- It assumes `Inbox` is an mbox file and could create or append the wrong object if Thunderbird’s storage arrangement changes.
- Message IDs have only one-second precision, so simultaneous runs can produce duplicates.

### Obsolete or inconsistent pieces

- `send-dummy-report.sh` is clearly test scaffolding: its filename and completion message say “dummy,” while the subject presents the hard-coded text as a real weekly research report. There is no weekly scheduling or research-generation logic in the script.
- `task1.sh` and its output files appear to be an unrelated scheduler experiment. Git history introduced the scripts with the commit message `test out reports.`
- The September 27 output is tracked in Git, while the September 28 and 29 outputs are untracked. That is an inconsistent artifact-retention policy.
- The `task1-*.md` files are plain `ls` output rather than meaningful Markdown reports and will accumulate indefinitely.
- Both scripts pass shell syntax validation, but the overall workflow is incomplete: there is no safe bridge from a generated report into Thunderbird.

I made no changes and did not run either script, because running the delivery script would mutate the live mailbox.
