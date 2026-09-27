#!/bin/sh
set -eu

appDataDir="${APPDATA:-$HOME/AppData/Roaming}"
thunderbirdProfiles="${appDataDir}/Thunderbird/Profiles"

if [ ! -d "$thunderbirdProfiles" ]; then
    printf 'Error: Thunderbird profiles directory not found at: %s\n' "$thunderbirdProfiles" >&2
    exit 1
fi

localInbox=$(find "$thunderbirdProfiles" -type d -name "Local Folders" 2>/dev/null | head -n 1)

if [ -z "$localInbox" ]; then
    printf 'Error: Local Folders directory not found under Thunderbird profiles.\n' >&2
    exit 1
fi

inboxMbox="${localInbox}/Inbox"

timestamp=$(date +%Y-%m-%d-%H%M%S)
dateRfc=$(date -R 2>/dev/null || date +"%a, %d %b %Y %H:%M:%S %z")
dateFrom=$(date +"%a %b %e %H:%M:%S %Y")

cat <<EOF >> "$inboxMbox"
From daemon@local ${dateFrom}
From: Agent Architecture Daemon <daemon@local>
To: Ray <ray@local>
Subject: Weekly Agent Architecture Research: ${timestamp}
Date: ${dateRfc}
Message-ID: <${timestamp}-research@local>
MIME-Version: 1.0
Content-Type: text/plain; charset=utf-8
Content-Transfer-Encoding: 8bit

# Weekly Agent Architecture Research: ${timestamp}

## 1. Key Papers & Emerging Standards
- Verification in Autonomous Agent Systems: Analyzes the boundaries between probabilistic planning and formal contract validation in execution tools.
- Typed Interfaces for Tool Execution: Evaluates moving from open-ended natural language prompts to strict JSON/YAML schemas for effector boundaries.

## 2. Practical Industry Patterns
- Linter-Driven Agent Loops: Implementing deterministic POSIX shell scripts as exit gates to prevent instruction drift and format violations.
- In-Memory Configuration Defaults: Bootstrapping agent harnesses with minimal in-memory structures rather than external config layers.

## 3. Tooling & Protocol Changes
- POSIX-First Tool Calling: Emerging preference for simple, hermetic shell scripts over heavy framework runtimes.

## 4. Architectural Recommendations
- Retain invariant verification at the script level to ensure UTF-8, LF line endings, and underscore-free naming across all deliverables.

EOF

printf 'Dummy report successfully written to: %s\n' "$inboxMbox"