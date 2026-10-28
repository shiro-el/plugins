#!/usr/bin/env bash
# Waits for a Herdr agent to finish a turn that changed its status report.
# `herdr agent wait` returns early while the agent waits on its own background
# monitor, so this judges the turn by its side effects instead: the report's
# `state:` and `head:` lines differ from the fingerprint you pass, and the agent
# is idle, done, blocked, or gone. Polls once a minute. Never writes anything.
#
# Usage: wait-report.sh --fingerprint <report.md>
#        wait-report.sh <agent> <report.md> <old fingerprint>
#   The fingerprint is the report's `- state:` and `- head:` lines joined on one
#   line. Take it with --fingerprint before you prompt the agent, then pass it,
#   quoted, as the third argument.
# Exits 0 with the agent's status and the new fingerprint.
set -u

fingerprint() { grep -E '^- (state|head):' "$1" 2>/dev/null | tr '\n' ' '; }

if [ "${1:-}" = "--fingerprint" ]; then
  fingerprint "${2:?usage: wait-report.sh --fingerprint <report.md>}"
  exit 0
fi

usage='usage: wait-report.sh <agent> <report.md> <old fingerprint>'
agent=${1:?$usage}
report=${2:?$usage}
old=${3?$usage}

while :; do
  status=$(herdr agent get "$agent" 2>/dev/null | jq -r '.result.agent.agent_status // "gone"')
  status=${status:-gone}
  now=$(fingerprint "$report")
  case $status in
    blocked | gone)
      echo "agent=$agent status=$status"
      echo "$now"
      exit 0
      ;;
    idle | done)
      if [ "$now" != "$old" ]; then
        echo "agent=$agent status=$status"
        echo "$now"
        exit 0
      fi
      ;;
  esac
  sleep 60
done
