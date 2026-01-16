#!/usr/bin/env bun
import { parseSpec } from './parse-spec';
import { GitHubClient } from './utils/github-client';
import type { Epic, Issue } from './utils/types';

const owner = process.env.REPO_OWNER!;
const repo = process.env.REPO_NAME!;
const projectNumber = parseInt(process.env.PROJECT_NUMBER || '1');
const dryRun = process.env.DRY_RUN === 'true';

const github = new GitHubClient(
  process.env.GITHUB_TOKEN!,
  owner,
  repo
);

async function createEpic(epic: Epic) {
  if (dryRun) {
    console.log(`[DRY RUN] Would create epic: ${epic.title}`);
    return { number: 999, node_id: 'mock-node-id' };
  }

  const scopeText = `**In Scope:**\n${epic.scope.inScope.map(i => `- ${i}`).join('\n')}

**Out of Scope:**\n${epic.scope.outOfScope.map(i => `- ${i}`).join('\n')}`;

  const body = `${epic.description}

## Goals
${epic.goals.map(g => `- ${g}`).join('\n')}

## Scope
${scopeText}`;

  const issue = await github.createIssue({
    title: `[EPIC] ${epic.title}`,
    body,
    labels: ['epic', `priority: ${epic.priority}`],
  });

  console.log(`✅ Created epic #${issue.data.number}: ${epic.title}`);
  return { number: issue.data.number, node_id: issue.data.node_id };
}

async function createIssue(issue: Issue, epicNumber: number) {
  if (dryRun) {
    console.log(`[DRY RUN] Would create issue: ${issue.title}`);
    return { number: 888, node_id: 'mock-node-id' };
  }

  const body = `${issue.description}

## Acceptance Criteria
${issue.acceptanceCriteria.map(c => `- [ ] ${c}`).join('\n')}

**Epic:** #${epicNumber}
${issue.dependencies?.length ? `\n**Dependencies:** ${issue.dependencies.join(', ')}` : ''}`;

  const labels = [
    'enhancement',
    `size: ${issue.size}`,
    `priority: ${issue.priority}`,
    `area: ${issue.area}`,
  ];

  const createdIssue = await github.createIssue({
    title: issue.title,
    body,
    labels,
  });

  console.log(`  ✅ Created issue #${createdIssue.data.number}: ${issue.title}`);
  return { number: createdIssue.data.number, node_id: createdIssue.data.node_id };
}

async function main() {
  console.log('🚀 Starting backlog generation...\n');

  // Parse spec
  const specPath = process.env.SPEC_PATH || 'spec.md';
  const planPath = process.env.PLAN_PATH;

  console.log(`📖 Parsing ${specPath}${planPath ? ` and ${planPath}` : ''}...`);
  const backlog = await parseSpec(specPath, planPath);

  console.log(`\n✨ Found ${backlog.epics.length} epics\n`);

  // Get project ID
  const projectId = await github.getProjectId(projectNumber);

  // Create epics and issues
  const createdItems: any[] = [];

  for (const epic of backlog.epics) {
    console.log(`\n📦 Creating epic: ${epic.title}`);
    const epicIssue = await createEpic(epic);

    await github.addToProject(epicIssue.node_id, projectId);
    createdItems.push({ type: 'epic', number: epicIssue.number, title: epic.title });

    // Create child issues
    for (const issue of epic.issues) {
      const childIssue = await createIssue(issue, epicIssue.number);
      await github.addToProject(childIssue.node_id, projectId);
      createdItems.push({
        type: 'issue',
        number: childIssue.number,
        title: issue.title,
        epic: epicIssue.number,
      });
    }
  }

  // Print summary
  console.log('\n\n═══════════════════════════════════════');
  console.log('📊 BACKLOG CREATION SUMMARY');
  console.log('═══════════════════════════════════════\n');

  for (const epic of createdItems.filter(i => i.type === 'epic')) {
    console.log(`📦 Epic #${epic.number}: ${epic.title}`);
    const children = createdItems.filter(i => i.type === 'issue' && i.epic === epic.number);
    for (const child of children) {
      console.log(`   ├─ #${child.number}: ${child.title}`);
    }
    console.log('');
  }

  if (backlog.gaps?.length) {
    console.log('⚠️  SPEC GAPS DETECTED:');
    backlog.gaps.forEach(gap => console.log(`   - ${gap}`));
    console.log('');
  }

  if (backlog.questions?.length) {
    console.log('❓ QUESTIONS FOR SPEC AUTHOR:');
    backlog.questions.forEach(q => console.log(`   - ${q}`));
    console.log('');
  }

  console.log('✅ Backlog generation complete!');
  console.log(`\nView project: https://github.com/${owner}/${repo}/projects/${projectNumber}`);
}

main().catch(error => {
  console.error('Error:', error);
  process.exit(1);
});
