#!/usr/bin/env bun
import { readFile } from 'fs/promises';
import { execSync } from 'child_process';
import { ClaudeClient } from './utils/claude-client';

const claude = new ClaudeClient(process.env.ANTHROPIC_API_KEY!);

async function main() {
  // Load review findings
  const findings = JSON.parse(await readFile('review-findings.json', 'utf-8'));
  const errors = findings.errors;

  if (errors.length === 0) {
    console.log('No errors to fix');
    return;
  }

  // Get current codebase state
  const diff = execSync('git diff HEAD~1').toString();
  const affectedFiles = [...new Set(errors.map((e: any) => e.file).filter(Boolean))];

  const fileContents = await Promise.all(
    affectedFiles.map(async (file: string) => ({
      path: file,
      content: await readFile(file, 'utf-8').catch(() => null),
    }))
  );

  const prompt = `You are Claude Code fixing review findings in a pull request.

## Review Errors to Fix
${errors.map((e: any, i: number) => `
${i + 1}. **${e.category}** (${e.file}${e.line ? `:${e.line}` : ''})
   ${e.message}
   ${e.suggestion ? `Suggestion: ${e.suggestion}` : ''}
`).join('\n')}

## Current Code
${fileContents.map(f => `### ${f.path}\n\`\`\`\n${f.content}\n\`\`\``).join('\n\n')}

## Recent Diff
\`\`\`diff
${diff}
\`\`\`

Your task:
1. Fix ALL the errors listed above
2. Make minimal changes - only fix what's broken
3. Maintain code style and patterns
4. Don't introduce new issues
5. Provide the complete fixed file contents

Return a JSON array of fixes:
[
  {
    "file": "path/to/file.ts",
    "content": "complete fixed file content",
    "changes": "brief description of what you fixed"
  }
]`;

  const response = await claude.chat({
    model: 'claude-opus-4.5',
    prompt,
    maxTokens: 16000,
  });

  const fixes = await claude.parseJSON<Array<{
    file: string;
    content: string;
    changes: string;
  }>>(response);

  // Apply fixes
  for (const fix of fixes) {
    await Bun.write(fix.file, fix.content);
    console.log(`✅ Fixed ${fix.file}: ${fix.changes}`);
  }

  console.log(`\n🎉 Auto-fix complete! Fixed ${fixes.length} file(s)`);
}

main().catch(error => {
  console.error('Error:', error);
  process.exit(1);
});
