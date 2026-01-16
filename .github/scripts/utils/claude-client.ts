import Anthropic from '@anthropic-ai/sdk';

export class ClaudeClient {
  private anthropic: Anthropic;

  constructor(apiKey: string) {
    this.anthropic = new Anthropic({ apiKey });
  }

  async chat(params: {
    model: string;
    prompt: string;
    maxTokens?: number;
  }): Promise<string> {
    const message = await this.anthropic.messages.create({
      model: params.model,
      max_tokens: params.maxTokens || 8000,
      messages: [{
        role: 'user',
        content: params.prompt,
      }],
    });

    const content = message.content[0];
    if (content.type !== 'text') {
      throw new Error('Unexpected response type from Claude');
    }

    return content.text;
  }

  extractJSON(text: string): string {
    // Try to extract JSON from markdown code blocks
    const jsonMatch = text.match(/```json\n([\s\S]*?)\n```/) ||
                      text.match(/```\n([\s\S]*?)\n```/);
    return jsonMatch ? jsonMatch[1] : text;
  }

  async parseJSON<T>(text: string): Promise<T> {
    const jsonText = this.extractJSON(text);
    return JSON.parse(jsonText) as T;
  }
}
