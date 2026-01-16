import { z } from 'zod';

// Epic and Issue schemas for backlog generation
export const IssueSchema = z.object({
  title: z.string(),
  description: z.string(),
  acceptanceCriteria: z.array(z.string()),
  size: z.enum(['S', 'M', 'L']),
  priority: z.enum(['high', 'medium', 'low']),
  area: z.enum(['frontend', 'backend', 'infrastructure', 'database', 'documentation']),
  dependencies: z.array(z.string()).optional(),
});

export const EpicSchema = z.object({
  title: z.string(),
  description: z.string(),
  goals: z.array(z.string()),
  scope: z.object({
    inScope: z.array(z.string()),
    outOfScope: z.array(z.string()),
  }),
  priority: z.enum(['high', 'medium', 'low']),
  issues: z.array(IssueSchema),
});

export const BacklogSchema = z.object({
  epics: z.array(EpicSchema),
  gaps: z.array(z.string()).optional(),
  questions: z.array(z.string()).optional(),
});

// Review schemas
export const FindingSchema = z.object({
  severity: z.enum(['error', 'warning', 'suggestion']),
  category: z.string(),
  message: z.string(),
  file: z.string().optional(),
  line: z.number().optional(),
  suggestion: z.string().optional(),
});

export const ReviewResultSchema = z.object({
  pass: z.string(),
  findings: z.array(FindingSchema),
  summary: z.string(),
});

// Type exports
export type Issue = z.infer<typeof IssueSchema>;
export type Epic = z.infer<typeof EpicSchema>;
export type Backlog = z.infer<typeof BacklogSchema>;
export type Finding = z.infer<typeof FindingSchema>;
export type ReviewResult = z.infer<typeof ReviewResultSchema>;
