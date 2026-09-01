#!/bin/sh
# Fake supervisor for offline testing. Reads a prompt on stdin.
# - delegate call: emits a worker prompt.
# - review call (input contains the WORKER RESPONSE marker): emits a decision.
# FAKE_DECISION controls the review token (default YES); use "BOGUS" for a
# malformed control line.
set -u
input=$(cat)

case "$input" in
*"----- WORKER RESPONSE -----"*)
	case "${FAKE_DECISION:-YES}" in
	YES)
		echo "YES"
		echo "The worker response adequately answers the request."
		;;
	NO)
		echo "NO"
		echo "The worker refused or was unusable."
		;;
	MAYBE)
		echo "MAYBE"
		echo "The caller should decide."
		;;
	*)
		echo "PROBABLY"
		echo "Deliberately malformed control output."
		;;
	esac
	;;
*)
	echo "Answer the following question clearly and completely:"
	echo "Who is buried in Grant's Tomb?"
	;;
esac
