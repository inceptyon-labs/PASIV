#!/usr/bin/env bun
import { ClaudeClient } from './utils/claude-client';
import { GitHubClient } from './utils/github-client';
import { ReviewResultSchema, type ReviewResult, type Finding } from './utils/types';

const prNumber = parseInt(process.env.PR_NUMBER!);
const [owner, repo] = process.env.GITHUB_REPOSITORY!.split('/');

const claude = new ClaudeClient(process.env.ANTHROPIC_API_KEY!);
const github = new GitHubClient(process.env.GITHUB_TOKEN!, owner, repo);

const REVIEW_PROMPTS = {
  fast: `You are a fast code reviewer (like Claude Sonnet). Focus on:
- Obvious bugs and errors
- Code style and formatting
- Basic security issues (XSS, SQL injection, etc.)
- Missing error handling
- Unused imports/variables

Be quick and practical. Only flag clear issues.`,

  deep: `You are a deep code reviewer (like Claude Opus). Focus on:
- Architecture and design patterns
- Edge cases and error scenarios
- Performance implications
- Scalability concerns
- Over-engineering or under-engineering
- Code maintainability
- API design quality
- Database query optimization
- Security in depth

Be thorough and consider long-term implications.`,

  independent: `You are an independent reviewer providing a fresh perspective. Focus on:
- Things the other reviewers might have missed
- User experience implications
- Alternative approaches
- Potential technical debt
- Testing coverage gaps
- Documentation clarity

Don't repeat what other passes would catch - provide novel insights.`,
};

async function runReviewPass(
  pass: 'fast' | 'deep' | 'independent'
): Promise<ReviewResult> {
  const diff = await github.getPullRequestDiff(prNumber);

  const model = pass === 'deep' ? 'claude-opus-4.5' : 'claude-sonnet-4.5';

  const prompt = `${REVIEW_PROMPTS[pass]}

Here is the pull request diff:

\`\`\`diff
${diff}
\`\`\`

Analyze the changes and return a JSON object with your findings:

{
  "pass": "${pass}",
  "findings": [
    {
      "severity": "error" | "warning" | "suggestion",
      "category": "security" | "bugs" | "performance" | "architecture" | "style" | "other",
      "message": "Clear description of the issue",
      "file": "path/to/file.ts",  // optional
      "line": 42,  // optional
      "suggestion": "How to fix it"  // optional
    }
  ],
  "summary": "Overall assessment of the PR"
}

Severity definitions:
- error: Must be fixed before merge (bugs, security issues, broken functionality)
- warning: Should be fixed (code smells, performance issues, bad patterns)
- suggestion: Nice to have (improvements, alternative approaches)`;

  const response = await claude.chat({ model, prompt, maxTokens: 8000 });
  const parsed = await claude.parseJSON(response);
  return ReviewResultSchema.parse(parsed);
}

async function aggregateResults(results: ReviewResult[]) {
  const allFindings = results.flatMap(r => r.findings);

  const errors = allFindings.filter(f => f.severity === 'error');
  const warnings = allFindings.filter(f => f.severity === 'warning');
  const suggestions = allFindings.filter(f => f.severity === 'suggestion');

  const formatFinding = (f: Finding) =>
    `- **${f.category}**: ${f.message}${f.file ? ` (${f.file}${f.line ? `:${f.line}` : ''})` : ''}${f.suggestion ? `\n  💡 ${f.suggestion}` : ''}`;

  const comment = `## 🔍 Multi-Pass Review Results

### Pass Results
${results.map(r => `**${r.pass.charAt(0).toUpperCase() + r.pass.slice(1)} Review:** ${r.summary}`).join('\n')}

---

### Findings Summary
- **Errors:** ${errors.length} 🔴
- **Warnings:** ${warnings.length} 🟡
- **Suggestions:** ${suggestions.length} 💡

${errors.length > 0 ? `
### ❌ Errors (Must Fix)
${errors.map(formatFinding).join('\n')}
` : ''}

${warnings.length > 0 ? `
### ⚠️ Warnings (Should Fix)
${warnings.map(formatFinding).join('\n')}
` : ''}

${suggestions.length > 0 ? `
### 💡 Suggestions (Nice to Have)
${suggestions.map(formatFinding).join('\n')}
` : ''}

---

${errors.length > 0 ? '🤖 Auto-fix will be triggered for errors.' : '✅ No blocking issues found!'}
`;

  await github.createComment(prNumber, comment);

  // Set outputs for GitHub Actions
  console.log(`::set-output name=has_errors::${errors.length > 0}`);
  console.log(`::set-output name=error_count::${errors.length}`);
  console.log(`::set-output name=warning_count::${warnings.length}`);
  console.log(`::set-output name=suggestion_count::${suggestions.length}`);

  // Save findings to file for auto-fix
  if (errors.length > 0) {
    await Bun.write(
      'review-findings.json',
      JSON.stringify({ errors, warnings, suggestions }, null, 2)
    );
  }
}

async function main() {
  const args = process.argv.slice(2);
  const passArg = args.find(a => a.startsWith('--pass'))?.split('=')[1];
  const aggregate = args.includes('--aggregate');

  if (passArg && ['fast', 'deep', 'independent'].includes(passArg)) {
    const pass = passArg as 'fast' | 'deep' | 'independent';
    const result = await runReviewPass(pass);
    await Bun.write(`review-${pass}.json`, JSON.stringify(result, null, 2));
    console.log(`✅ ${pass} review complete`);
  } else if (aggregate) {
    const results = await Promise.all([
      Bun.file('review-fast.json').json(),
      Bun.file('review-deep.json').json(),
      Bun.file('review-independent.json').json(),
    ]);
    await aggregateResults(results);
    console.log('✅ Results aggregated and posted to PR');
  } else {
    console.error('Usage: bun run review-aggregator.ts --pass=fast|deep|independent OR --aggregate');
    process.exit(1);
  }
}

main().catch(error => {
  console.error('Error:', error);
  process.exit(1);
});
