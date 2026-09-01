#!/bin/sh
# llm-relay.sh - one supervisor delegation, one worker call, one supervisor review.
#
# The shell script is the deterministic mediator. The two LLMs never invoke one
# another directly. Exactly one delegation and one review happen per run, so the
# flow cannot loop indefinitely.
#
# Providers are configurable commands that read a prompt on standard input and
# write their response to standard output:
#
#   RELAY_SUPERVISOR_CMD   e.g. "claude -p"
#   RELAY_WORKER_CMD       e.g. "codex exec -"
#
# Usage:
#   llm-relay.sh [-r REQUEST_FILE] [-o RUNS_DIR]   run the full flow
#   llm-relay.sh parse REVIEW_FILE                 print the decision token only
#
# Exit codes:
#   0   YES     worker response accepted; result is the raw worker response
#   10  NO      response wrong/empty/refused; result is a failure report
#   20  MAYBE   caller judgement required; result preserves everything
#   30  INVALID malformed protocol output; result preserves everything
#   40          worker execution failure (nonzero exit or empty output)
#   2           usage or setup error

set -u

EXIT_YES=0
EXIT_NO=10
EXIT_MAYBE=20
EXIT_INVALID=30
EXIT_WORKER_FAIL=40
EXIT_USAGE=2

here=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
PROMPTS_DIR="$here/prompts"

fail() {
	echo "llm-relay: $1" >&2
	exit "$EXIT_USAGE"
}

# --- decision parser -------------------------------------------------------
# The decision is the first nonblank line of the review, trimmed of surrounding
# whitespace, and must be exactly YES, NO, or MAYBE. Anything else is INVALID.
# The explanation on later lines is never interpreted.
parse_decision() {
	_file="$1"
	[ -f "$_file" ] || { echo INVALID; return; }
	_line=$(awk 'NF{print; exit}' "$_file" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')
	case "$_line" in
	YES) echo YES ;;
	NO) echo NO ;;
	MAYBE) echo MAYBE ;;
	*) echo INVALID ;;
	esac
}

# --- provider invocation ---------------------------------------------------
# Word-split the configured command (no eval, no sh -c). Prompt via stdin.
run_provider() {
	_cmd="$1"
	_in="$2"
	_out="$3"
	_err="$4"
	# shellcheck disable=SC2086
	$_cmd <"$_in" >"$_out" 2>"$_err"
}

# nonempty after stripping whitespace?
has_content() {
	[ -s "$1" ] && [ -n "$(tr -d '[:space:]' <"$1")" ]
}

next_run_dir() {
	_base="$1"
	_day=$(date +%Y-%m-%d)
	_n=1
	while :; do
		_seq=$(printf '%03d' "$_n")
		_dir="$_base/run-$_day-$_seq"
		if [ ! -e "$_dir" ]; then
			echo "$_dir"
			return
		fi
		_n=$((_n + 1))
	done
}

# --- subcommand: parse -----------------------------------------------------
if [ "${1:-}" = "parse" ]; then
	[ $# -eq 2 ] || fail "usage: llm-relay.sh parse REVIEW_FILE"
	parse_decision "$2"
	exit 0
fi

# --- main flow -------------------------------------------------------------
request_file=""
runs_dir="$here/runs"

while [ $# -gt 0 ]; do
	case "$1" in
	-r)
		shift
		[ $# -gt 0 ] || fail "-r needs a file argument"
		request_file="$1"
		;;
	-o)
		shift
		[ $# -gt 0 ] || fail "-o needs a directory argument"
		runs_dir="$1"
		;;
	-h | --help)
		sed -n '2,30p' "$0"
		exit 0
		;;
	*)
		fail "unknown argument: $1"
		;;
	esac
	shift
done

[ -n "${RELAY_SUPERVISOR_CMD:-}" ] || fail "RELAY_SUPERVISOR_CMD is not set"
[ -n "${RELAY_WORKER_CMD:-}" ] || fail "RELAY_WORKER_CMD is not set"
[ -f "$PROMPTS_DIR/delegate.md" ] || fail "missing $PROMPTS_DIR/delegate.md"
[ -f "$PROMPTS_DIR/review.md" ] || fail "missing $PROMPTS_DIR/review.md"

mkdir -p "$runs_dir" || fail "cannot create runs dir: $runs_dir"
run_dir=$(next_run_dir "$runs_dir")
mkdir -p "$run_dir" || fail "cannot create run dir: $run_dir"

req="$run_dir/00-request.md"
delegated="$run_dir/01-delegated-prompt.md"
worker_out="$run_dir/02-worker-response.md"
worker_err="$run_dir/02-worker-response.stderr"
review="$run_dir/03-supervisor-review.md"
result="$run_dir/04-result.md"
status="$run_dir/run-status.md"

run_id=$(basename "$run_dir")
started=$(date +%Y-%m-%dT%H:%M:%S%z)

# capture the request from file or stdin
if [ -n "$request_file" ]; then
	[ -f "$request_file" ] || fail "request file not found: $request_file"
	cat "$request_file" >"$req"
else
	cat >"$req"
fi
has_content "$req" || fail "empty request"

# status writer (rewritten as the run progresses)
write_status() {
	{
		echo "# run-status"
		echo
		echo "- run: $run_id"
		echo "- supervisor: $RELAY_SUPERVISOR_CMD"
		echo "- worker: $RELAY_WORKER_CMD"
		echo "- started: $started"
		echo "- completed: ${completed:-}"
		echo "- delegate-exit: ${delegate_exit:-}"
		echo "- worker-exit: ${worker_exit:-}"
		echo "- review-exit: ${review_exit:-}"
		echo "- decision: ${decision:-}"
		echo "- state: ${state:-}"
	} >"$status"
}
completed=""
delegate_exit=""
worker_exit=""
review_exit=""
decision=""
state="started"
write_status

# 1. supervisor formulates the delegated prompt
delegate_input=$(mktemp) || fail "mktemp failed"
{
	cat "$PROMPTS_DIR/delegate.md"
	echo
	echo "----- ORIGINAL REQUEST -----"
	cat "$req"
} >"$delegate_input"

sup_err="$run_dir/01-delegated-prompt.stderr"
run_provider "$RELAY_SUPERVISOR_CMD" "$delegate_input" "$delegated" "$sup_err"
delegate_exit=$?
rm -f "$delegate_input"

if [ "$delegate_exit" -ne 0 ] || ! has_content "$delegated"; then
	decision="NONE"
	state="supervisor-delegate-failed"
	completed=$(date +%Y-%m-%dT%H:%M:%S%z)
	{
		echo "# result: SUPERVISOR FAILURE"
		echo
		echo "The supervisor failed to produce a delegated prompt (exit $delegate_exit)."
		echo "No worker call was made. See 01-delegated-prompt.stderr."
	} >"$result"
	write_status
	echo "$run_dir"
	exit "$EXIT_WORKER_FAIL"
fi

# 2. worker answers the delegated prompt
run_provider "$RELAY_WORKER_CMD" "$delegated" "$worker_out" "$worker_err"
worker_exit=$?

# 3. worker execution failure short-circuits before review
if [ "$worker_exit" -ne 0 ] || ! has_content "$worker_out"; then
	decision="NONE"
	state="worker-failed"
	completed=$(date +%Y-%m-%dT%H:%M:%S%z)
	{
		echo "# result: WORKER FAILURE"
		echo
		echo "The worker did not produce a usable response."
		echo
		echo "- worker exit status: $worker_exit"
		echo "- worker stdout: 02-worker-response.md"
		echo "- worker stderr: 02-worker-response.stderr"
	} >"$result"
	write_status
	echo "$run_dir"
	exit "$EXIT_WORKER_FAIL"
fi

# 4. supervisor reviews the worker response
review_input=$(mktemp) || fail "mktemp failed"
{
	cat "$PROMPTS_DIR/review.md"
	echo
	echo "----- ORIGINAL REQUEST -----"
	cat "$req"
	echo
	echo "----- WORKER RESPONSE -----"
	cat "$worker_out"
	echo
	echo "----- END WORKER RESPONSE -----"
} >"$review_input"

review_err="$run_dir/03-supervisor-review.stderr"
run_provider "$RELAY_SUPERVISOR_CMD" "$review_input" "$review" "$review_err"
review_exit=$?
rm -f "$review_input"

if [ "$review_exit" -ne 0 ] || ! has_content "$review"; then
	decision="INVALID"
	state="review-failed"
	completed=$(date +%Y-%m-%dT%H:%M:%S%z)
	{
		echo "# result: INVALID (review unavailable)"
		echo
		echo "The supervisor review failed or was empty (exit $review_exit)."
		echo "Escalating to the caller. See 03-supervisor-review.stderr."
		echo
		echo "----- ORIGINAL REQUEST -----"
		cat "$req"
		echo
		echo "----- WORKER RESPONSE -----"
		cat "$worker_out"
	} >"$result"
	write_status
	echo "$run_dir"
	exit "$EXIT_INVALID"
fi

# 5. parse only the first nonblank review line
decision=$(parse_decision "$review")

case "$decision" in
YES)
	state="accepted"
	# return the raw, unmodified worker response
	cat "$worker_out" >"$result"
	exit_code="$EXIT_YES"
	;;
NO)
	state="rejected"
	{
		echo "# result: NO (worker response rejected)"
		echo
		echo "The supervisor judged the worker response wrong, empty, refused,"
		echo "or otherwise unusable."
		echo
		echo "----- ORIGINAL REQUEST -----"
		cat "$req"
		echo
		echo "----- WORKER RESPONSE -----"
		cat "$worker_out"
		echo
		echo "----- SUPERVISOR REVIEW -----"
		cat "$review"
	} >"$result"
	exit_code="$EXIT_NO"
	;;
MAYBE)
	state="escalated"
	{
		echo "# result: MAYBE (caller judgement required)"
		echo
		echo "----- ORIGINAL REQUEST -----"
		cat "$req"
		echo
		echo "----- WORKER RESPONSE -----"
		cat "$worker_out"
		echo
		echo "----- SUPERVISOR REVIEW -----"
		cat "$review"
	} >"$result"
	exit_code="$EXIT_MAYBE"
	;;
*)
	decision="INVALID"
	state="malformed-review"
	{
		echo "# result: INVALID (malformed control output)"
		echo
		echo "The supervisor review did not begin with YES, NO, or MAYBE."
		echo "Never guessing what it meant; escalating everything to the caller."
		echo
		echo "----- ORIGINAL REQUEST -----"
		cat "$req"
		echo
		echo "----- WORKER RESPONSE -----"
		cat "$worker_out"
		echo
		echo "----- SUPERVISOR REVIEW -----"
		cat "$review"
	} >"$result"
	exit_code="$EXIT_INVALID"
	;;
esac

completed=$(date +%Y-%m-%dT%H:%M:%S%z)
write_status
echo "$run_dir"
exit "$exit_code"
