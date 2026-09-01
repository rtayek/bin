#!/bin/sh
# Fake worker for offline testing. Reads a prompt on stdin.
# FAKE_WORKER selects behaviour:
#   good    (default) a correct answer
#   refuse  a refusal (nonzero exit? no - refusal is content, exit 0)
#   empty   no output, exit 0
#   fail    error message on stderr, exit 1
set -u
cat >/dev/null

case "${FAKE_WORKER:-good}" in
refuse)
	echo "I cannot answer that request."
	;;
empty)
	: # nothing on stdout
	;;
fail)
	echo "provider error: not authenticated" >&2
	exit 1
	;;
*)
	echo "Ulysses S. Grant and his wife Julia Dent Grant are entombed in Grant's Tomb."
	;;
esac
