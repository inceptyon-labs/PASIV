#!/bin/bash
# PASIV PreCompact hook — remind to write handoff before context compression
cat <<'EOF'
{
  "systemMessage": "[PASIV] STOP. Context is about to be compressed. You MUST write a session handoff NOW before continuing. Run: /handoff — This preserves decisions, progress, and open questions for the next session. Do NOT skip this step."
}
EOF
