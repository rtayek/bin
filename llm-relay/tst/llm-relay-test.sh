#!/bin/sh
# Fixture tests for llm-relay.sh. No live providers; uses fake commands.
set -u

here=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
root=$(CDPATH= cd -- "$here/.." && pwd)
relay="$root/llm-relay.sh"
fixtures="$here/fixtures"

pass=0
fail=0

ok() {
	pass=$((pass + 1))
	echo "ok   - $1"
}
ng() {
	fail=$((fail + 1))
	echo "FAIL - $1"
}

check_eq() {
	# desc, expected, actual
	if [ "$2" = "$3" ]; then
		ok "$1"
	else
		ng "$1 (expected '$2', got '$3')"
	fi
}

echo "# parser tests"
check_eq "YES fixture" YES "$(sh "$relay" parse "$fixtures/yes.md")"
check_eq "NO fixture" NO "$(sh "$relay" parse "$fixtures/no.md")"
check_eq "MAYBE fixture (padded)" MAYBE "$(sh "$relay" parse "$fixtures/maybe.md")"
check_eq "punctuation is INVALID" INVALID "$(sh "$relay" parse "$fixtures/invalid-punct.md")"
check_eq "unknown token is INVALID" INVALID "$(sh "$relay" parse "$fixtures/invalid-token.md")"
check_eq "blank review is INVALID" INVALID "$(sh "$relay" parse "$fixtures/invalid-blank.md")"
check_eq "missing file is INVALID" INVALID "$(sh "$relay" parse "$fixtures/does-not-exist.md")"

echo
echo "# full-flow tests (fake providers)"

runs=$(mktemp -d) || { echo "mktemp -d failed" >&2; exit 1; }
trap 'rm -rf "$runs"' EXIT

export RELAY_SUPERVISOR_CMD="sh $here/fake-supervisor.sh"
export RELAY_WORKER_CMD="sh $here/fake-worker.sh"

run_flow() {
	# runs the relay with "Who is buried in Grant's Tomb?" and echoes exit code
	printf "Who is buried in Grant's Tomb?\n" | sh "$relay" -o "$runs" >/dev/null 2>&1
	echo $?
}

# YES success
FAKE_WORKER=good FAKE_DECISION=YES
export FAKE_WORKER FAKE_DECISION
rc=$(run_flow)
check_eq "YES flow exit 0" 0 "$rc"
last=$(ls -d "$runs"/run-* | sort | tail -1)
if grep -q "Ulysses S. Grant" "$last/04-result.md" 2>/dev/null; then
	ok "YES result is raw worker answer"
else
	ng "YES result is raw worker answer"
fi
for f in 00-request.md 01-delegated-prompt.md 02-worker-response.md 03-supervisor-review.md 04-result.md run-status.md; do
	[ -f "$last/$f" ] && ok "artifact $f present" || ng "artifact $f present"
done

# NO decision
FAKE_WORKER=refuse FAKE_DECISION=NO
rc=$(run_flow)
check_eq "NO flow exit 10" 10 "$rc"
last=$(ls -d "$runs"/run-* | sort | tail -1)
grep -q "I cannot answer" "$last/04-result.md" && ok "NO result preserves refusal" || ng "NO result preserves refusal"

# MAYBE decision
FAKE_WORKER=good FAKE_DECISION=MAYBE
rc=$(run_flow)
check_eq "MAYBE flow exit 20" 20 "$rc"

# INVALID (malformed control token)
FAKE_WORKER=good FAKE_DECISION=BOGUS
rc=$(run_flow)
check_eq "INVALID flow exit 30" 30 "$rc"
last=$(ls -d "$runs"/run-* | sort | tail -1)
grep -q "malformed" "$last/04-result.md" && ok "INVALID result explains escalation" || ng "INVALID result explains escalation"

# worker empty output -> worker failure, no review
FAKE_WORKER=empty FAKE_DECISION=YES
rc=$(run_flow)
check_eq "empty worker exit 40" 40 "$rc"
last=$(ls -d "$runs"/run-* | sort | tail -1)
[ ! -f "$last/03-supervisor-review.md" ] && ok "no review on worker failure" || ng "no review on worker failure"

# worker nonzero exit -> worker failure
FAKE_WORKER=fail FAKE_DECISION=YES
rc=$(run_flow)
check_eq "failing worker exit 40" 40 "$rc"

echo
echo "# $pass passed, $fail failed"
[ "$fail" -eq 0 ]
