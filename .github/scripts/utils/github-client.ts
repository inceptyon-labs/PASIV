import { Octokit } from '@octokit/rest';

export class GitHubClient {
  private octokit: Octokit;
  private owner: string;
  private repo: string;

  constructor(token: string, owner: string, repo: string) {
    this.octokit = new Octokit({ auth: token });
    this.owner = owner;
    this.repo = repo;
  }

  async getProjectId(projectNumber: number): Promise<string> {
    const query = `
      query($owner: String!, $number: Int!) {
        user(login: $owner) {
          projectV2(number: $number) {
            id
          }
        }
      }
    `;

    const result: any = await this.octokit.graphql(query, {
      owner: this.owner,
      number: projectNumber,
    });

    return result.user.projectV2.id;
  }

  async createIssue(params: {
    title: string;
    body: string;
    labels?: string[];
  }) {
    return await this.octokit.issues.create({
      owner: this.owner,
      repo: this.repo,
      ...params,
    });
  }

  async addToProject(issueNodeId: string, projectId: string) {
    const mutation = `
      mutation($projectId: ID!, $contentId: ID!) {
        addProjectV2ItemById(input: {projectId: $projectId, contentId: $contentId}) {
          item {
            id
          }
        }
      }
    `;

    await this.octokit.graphql(mutation, {
      projectId,
      contentId: issueNodeId,
    });
  }

  async createComment(issueNumber: number, body: string) {
    return await this.octokit.issues.createComment({
      owner: this.owner,
      repo: this.repo,
      issue_number: issueNumber,
      body,
    });
  }

  async getPullRequestDiff(prNumber: number): Promise<string> {
    const { data } = await this.octokit.pulls.get({
      owner: this.owner,
      repo: this.repo,
      pull_number: prNumber,
      mediaType: { format: 'diff' },
    });
    return data as unknown as string;
  }

  async addLabel(issueNumber: number, label: string) {
    await this.octokit.issues.addLabels({
      owner: this.owner,
      repo: this.repo,
      issue_number: issueNumber,
      labels: [label],
    });
  }

  async removeLabel(issueNumber: number, label: string) {
    try {
      await this.octokit.issues.removeLabel({
        owner: this.owner,
        repo: this.repo,
        issue_number: issueNumber,
        name: label,
      });
    } catch (error) {
      // Ignore if label doesn't exist
      if ((error as any).status !== 404) {
        throw error;
      }
    }
  }

  async getLabels(issueNumber: number): Promise<string[]> {
    const { data } = await this.octokit.issues.get({
      owner: this.owner,
      repo: this.repo,
      issue_number: issueNumber,
    });
    return data.labels.map(l => typeof l === 'string' ? l : l.name || '');
  }
}
