#!/bin/bash
# Remind Claude to write handoff before compaction
cat <<EOF
{
  "systemMessage": "[PASIV PreCompact] Context is about to be compressed. If you have uncommitted session state (decisions, progress, open questions), write a handoff now using: Skill(skill=\"handoff\")"
}
EOF
