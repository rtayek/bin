# llm-relay

Smallest useful two-LLM relay: a supervisor delegates one request to a worker,
reviews the single response, and returns an accepted answer or an explicit
escalation. A Bourne-shell script is the deterministic mediator; the two LLMs
never call each other. Exactly one delegation and one review per run, so it
cannot loop.

## Run

```sh
export RELAY_SUPERVISOR_CMD="claude -p"
export RELAY_WORKER_CMD="codex exec -"
printf "Who is buried in Grant's Tomb?\n" | sh llm-relay.sh
```

Each provider command reads a prompt on stdin and writes its response to stdout.
The script prints the run directory path and exits with a decision code.

## Decision codes

| exit | token   | result                                   |
|------|---------|------------------------------------------|
| 0    | YES     | raw worker response                      |
| 10   | NO      | failure report (response unusable)       |
| 20   | MAYBE   | everything preserved for caller judgement|
| 30   | INVALID | malformed control output; escalated      |
| 40   | -       | worker execution failure (no review run) |
| 2    | -       | usage/setup error                        |

The decision is the first nonblank line of the review, trimmed, matched exactly
against `YES` / `NO` / `MAYBE`. Anything else is `INVALID`.

## Artifacts

One directory per run under `runs/` (gitignored): `00-request.md`,
`01-delegated-prompt.md`, `02-worker-response.md` (+ `.stderr`),
`03-supervisor-review.md`, `04-result.md`, `run-status.md`.

## Test

```sh
sh tst/llm-relay-test.sh
```

Offline fixtures cover all four parser outcomes plus worker failure, using the
fake providers in `tst/`.
