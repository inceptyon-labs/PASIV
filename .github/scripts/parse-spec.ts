#!/usr/bin/env bun
import { readFile } from 'fs/promises';
import { ClaudeClient } from './utils/claude-client';
import { BacklogSchema, type Backlog } from './utils/types';

export async function parseSpec(
  specPath: string,
  planPath?: string
): Promise<Backlog> {
  const claude = new ClaudeClient(process.env.ANTHROPIC_API_KEY!);

  // Read spec and plan files
  const specContent = await readFile(specPath, 'utf-8');
  const planContent = planPath
    ? await readFile(planPath, 'utf-8').catch(() => null)
    : null;

  // Construct prompt for Claude
  const prompt = `You are a software project analyst. Parse the following specification documents and create a structured backlog.

${planContent ? `## Plan Document\n\n${planContent}\n\n` : ''}

## Specification Document

${specContent}

---

Your task:
1. Identify high-level epics (major features)
2. Break each epic into specific, reviewable issues
3. Each issue should be:
   - Small enough to review in one session (prefer S/M over L)
   - Have clear acceptance criteria
   - Include definition of done
   - Properly sized and prioritized
4. Identify any gaps or ambiguities in the spec

Return a JSON object matching this schema:

{
  "epics": [
    {
      "title": "Epic title",
      "description": "What is this epic about?",
      "goals": ["Goal 1", "Goal 2"],
      "scope": {
        "inScope": ["Item 1", "Item 2"],
        "outOfScope": ["Item 1", "Item 2"]
      },
      "priority": "high" | "medium" | "low",
      "issues": [
        {
          "title": "Issue title",
          "description": "Detailed description",
          "acceptanceCriteria": ["Criterion 1", "Criterion 2"],
          "size": "S" | "M" | "L",
          "priority": "high" | "medium" | "low",
          "area": "frontend" | "backend" | "infrastructure" | "database" | "documentation",
          "dependencies": ["#123", "#124"]  // Optional: other issue numbers
        }
      ]
    }
  ],
  "gaps": ["Gap 1", "Gap 2"],  // Optional: things unclear in the spec
  "questions": ["Question 1", "Question 2"]  // Optional: questions for the author
}

Rules:
- Prefer multiple small epics over one giant epic
- Each issue should take 1-8 hours (most should be S or M)
- Be specific with acceptance criteria
- Flag anything unclear as a gap or question`;

  const response = await claude.chat({
    model: 'claude-opus-4.5',
    prompt,
    maxTokens: 16000,
  });

  const parsed = await claude.parseJSON(response);
  return BacklogSchema.parse(parsed);
}

// CLI usage
if (import.meta.main) {
  const specPath = process.env.SPEC_PATH || 'spec.md';
  const planPath = process.env.PLAN_PATH;

  try {
    const backlog = await parseSpec(specPath, planPath);
    console.log(JSON.stringify(backlog, null, 2));
  } catch (error) {
    console.error('Error parsing spec:', error);
    process.exit(1);
  }
}
