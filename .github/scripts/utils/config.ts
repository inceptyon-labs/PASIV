import { readFile } from 'fs/promises';
import { z } from 'zod';

const ConfigSchema = z.object({
  project: z.object({
    name: z.string(),
    owner: z.string(),
    repo: z.string(),
    projectNumber: z.number(),
  }),
  labels: z.object({
    areas: z.array(z.string()),
    priorities: z.array(z.string()),
    sizes: z.array(z.string()),
  }),
  review: z.object({
    maxAutoFixIterations: z.number().default(3),
    fastReviewModel: z.string().default('claude-sonnet-4.5'),
    deepReviewModel: z.string().default('claude-opus-4.5'),
  }),
  backlog: z.object({
    defaultSpecPath: z.string().default('spec.md'),
    defaultPlanPath: z.string().default('plan.md'),
  }),
});

export type Config = z.infer<typeof ConfigSchema>;

let cachedConfig: Config | null = null;

export async function loadConfig(): Promise<Config> {
  if (cachedConfig) return cachedConfig;

  const configPath = '.github/automation.config.json';
  const configText = await readFile(configPath, 'utf-8');
  const config = JSON.parse(configText);

  cachedConfig = ConfigSchema.parse(config);
  return cachedConfig;
}

/**
 * Get configuration with fallback to environment variables
 */
export async function getConfig(): Promise<Config> {
  try {
    return await loadConfig();
  } catch (error) {
    console.warn('Config file not found, using environment variables');

    // Fallback to environment variables
    return {
      project: {
        name: process.env.PROJECT_NAME || 'My Project',
        owner: process.env.REPO_OWNER || '',
        repo: process.env.REPO_NAME || '',
        projectNumber: parseInt(process.env.PROJECT_NUMBER || '1'),
      },
      labels: {
        areas: ['frontend', 'backend', 'infrastructure', 'database', 'documentation'],
        priorities: ['high', 'medium', 'low'],
        sizes: ['S', 'M', 'L'],
      },
      review: {
        maxAutoFixIterations: parseInt(process.env.MAX_AUTO_FIX_ITERATIONS || '3'),
        fastReviewModel: process.env.FAST_REVIEW_MODEL || 'claude-sonnet-4.5',
        deepReviewModel: process.env.DEEP_REVIEW_MODEL || 'claude-opus-4.5',
      },
      backlog: {
        defaultSpecPath: process.env.SPEC_PATH || 'spec.md',
        defaultPlanPath: process.env.PLAN_PATH || 'plan.md',
      },
    };
  }
}

/**
 * Get project-specific settings
 */
export async function getProjectSettings() {
  const config = await getConfig();
  return config.project;
}

/**
 * Get review settings
 */
export async function getReviewSettings() {
  const config = await getConfig();
  return config.review;
}
