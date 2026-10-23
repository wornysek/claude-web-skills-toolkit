---
name: ai-features
description: "Building LLM-powered features into web apps: architecture (server-side model calls, streaming, structured output, tools), chat and assistant UX (streaming, stop, retry, sources, feedback, AI disclosure), prompt injection and tool safety, treating model output as untrusted, privacy and data sent to providers, rate limits, cost budgets and kill switches, retrieval-augmented generation with pgvector (tenant isolation, chunking, citations), evaluation and monitoring. Use whenever you add a chat, assistant, summary, generation, semantic search, classification or any feature that calls a language model, or the user asks about AI integration, RAG, embeddings or prompt injection. For Claude/Anthropic API specifics use the claude-api skill if it is available."
triggers:
  - "add AI / chatbot / assistant / copilot to the app"
  - "summarize / generate / classify with an LLM"
  - "RAG / embeddings / vector search / pgvector"
  - "prompt injection / AI safety / jailbreak"
  - "AI costs / token limits / rate limits for AI"
metadata:
  author: claude-web-skills-toolkit
  license: MIT
  version: "1.0.0"
---

# AI features

A language model is a powerful, probabilistic and expensive dependency that reads
untrusted text and produces untrusted text. Build AI features like payments: server-side,
metered, logged, with limits — and with a UI that is honest about what the model is.

## Process

1. **Define the job** and a measurable "good answer" before writing prompts (section 8).
2. **Architecture:** server-side calls, streaming, structured output where possible (section 1).
3. **UX** for streaming, errors, sources and feedback (section 2).
4. **Safety:** prompt injection, tools, output handling (sections 3–4).
5. **Privacy, limits and costs** (sections 5–6).
6. **RAG** if the model needs your data (section 7).
7. **Evaluate and monitor** (section 8).

---

## 1. Architecture

- **Model calls only on the server.** API keys never reach the browser; the client talks to your endpoint, which authenticates the user, applies limits and calls the provider.
- **Stream** long responses so the first words appear in about a second.
- **Structured output** (JSON validated with a schema) for anything the app processes — classification, extraction, forms — instead of parsing free text.
- **Pin the model version** in configuration; upgrading is a tested change, not a surprise.
- **Timeouts and cancellation:** pass the request's `AbortSignal` so a closed tab stops the generation (and the cost).

```ts
// app/api/chat/route.ts — streaming chat with the Vercel AI SDK (v5 API; check current docs)
import { anthropic } from "@ai-sdk/anthropic";
import { convertToModelMessages, streamText, type UIMessage } from "ai";
import { requireUser } from "@/lib/authz";
import { aiLimiter, assertWithinBudget } from "@/lib/ai-limits";

export async function POST(req: Request) {
  const user = await requireUser();
  const { success } = await aiLimiter.limit(`user:${user.id}`);
  if (!success) return Response.json({ error: "rate_limited" }, { status: 429 });
  await assertWithinBudget(user.id);

  const { messages }: { messages: UIMessage[] } = await req.json();
  const result = streamText({
    model: anthropic(process.env.AI_MODEL ?? "claude-sonnet-5-5"),
    system: "You help users of Acme with questions about invoicing. Answer only from the provided context. If you don't know, say so.",
    messages: convertToModelMessages(messages.slice(-20)), // bounded history
    maxOutputTokens: 1024,
    abortSignal: req.signal,
    onFinish: ({ usage }) => recordUsage(user.id, usage),
  });
  return result.toUIMessageStreamResponse();
}
```

- Any provider and SDK works the same way; keep the provider behind one module so it can be swapped.
- Validate the incoming messages (size, count, roles) like any other input (`backend-security-auditor` C1).

## 2. UX

- **Disclose AI:** users must know when they talk to an AI system or see AI-generated content — label the assistant and generated text. In the EU this is a legal transparency obligation under the AI Act (scheduled from August 2026; check the current timeline → `[LEGAL: …]`).
- **Streaming UI:** show progress immediately, a **Stop** button while generating, **Retry** and **Edit prompt** after errors.
- **Sources:** when answers come from documents, show citations the user can open; "I couldn't find this in your documents" is a valid answer.
- **Feedback:** thumbs up/down with an optional reason, stored with the conversation ID for evaluation.
- **Set expectations:** what the assistant can and can't do, in one line; suggested prompts for an empty state.
- **Errors in plain language** ("The assistant is busy, try again in a minute"), never raw provider errors.
- **Accessibility:** announce the finished answer to screen readers (not every token); keyboard shortcuts don't conflict with typing (`a11y-auditor`).
- **Rendering:** model output is Markdown at most — render it with a sanitizing renderer, never as raw HTML (`frontend-security`).

## 3. Prompt injection

Anything the model reads can contain instructions: user messages, uploaded files, web
pages, emails, retrieved documents. **The model can't reliably tell data from
instructions.** Design so that a successful injection can't do damage.

- **No secrets in prompts** — the system prompt can leak; never put keys, internal URLs or other users' data in it.
- **Least-privilege tools:** read-only by default; tools act **as the current user** with their permissions, checked on the server — never with admin rights.
- **Human confirmation** for any tool with side effects (sending email, payments, deleting, changing settings): the model proposes, the user confirms in the UI.
- **Isolate untrusted content:** mark it clearly as data in the prompt, and don't let content from one user flow into another user's context.
- **No data exfiltration paths:** don't render model-generated links or images to arbitrary domains automatically (a classic exfiltration channel); restrict to allowlisted domains or show them as plain text.
- **Log and monitor** tool calls and refusals; alert on unusual patterns.

## 4. Output is untrusted input

- Validate structured output with a schema; on failure retry once, then fail gracefully.
- Never execute generated code, SQL or shell commands directly; never pass generated text into `eval`, queries or templates without the usual escaping.
- Generated text shown to other users is user-generated content: moderation, reporting and the same XSS rules apply.
- For decisions with consequences (approvals, prices, medical, legal, financial advice), the model assists and a person or deterministic rule decides.

## 5. Privacy

- Send the provider **only what the task needs**; strip or pseudonymize personal data where possible.
- The provider is a **processor**: DPA, region, data retention and whether inputs are used for training — record it in the data inventory (`gdpr-privacy`).
- Tell users what is processed by AI in the privacy notice; offer an opt-out for optional AI features on personal data.
- Conversation logs contain personal data: retention period, access control, deletion with the account.

## 6. Limits and costs

- **Rate limits** per user and per workspace (requests per minute) with a shared store (`backend-security-auditor` G1).
- **Budgets:** maximum input and output tokens per request, a daily or monthly token budget per user / plan, and a global spend alert and cap at the provider.
- **Kill switch:** a feature flag to turn the AI feature off or switch to a cheaper model instantly (`deploy-and-ops`).
- **Cheaper paths first:** cache answers to repeated questions, use smaller models for classification and routing, use the provider's prompt caching for long, stable system prompts and documents.
- Record usage per request (model, tokens, cost, latency, user, feature) for billing, abuse detection and evaluation.

## 7. Retrieval-augmented generation (RAG)

```sql
CREATE EXTENSION IF NOT EXISTS vector;

CREATE TABLE document_chunks (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id   uuid NOT NULL,
  document_id uuid NOT NULL REFERENCES documents (id) ON DELETE CASCADE,
  content     text NOT NULL,
  embedding   vector(1536) NOT NULL,   -- dimension depends on the embedding model
  created_at  timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX document_chunks_embedding_idx ON document_chunks USING hnsw (embedding vector_cosine_ops);
CREATE INDEX document_chunks_tenant_idx ON document_chunks (tenant_id);
```

```sql
-- Retrieval: tenant filter FIRST — vector search must never cross tenants
SELECT id, document_id, content
FROM document_chunks
WHERE tenant_id = $1
ORDER BY embedding <=> $2
LIMIT 8;
```

- **Authorization in retrieval:** filter by tenant and by the user's document permissions in the query — a vector search without it is an IDOR (`backend-security-auditor` B1).
- **Chunking:** split by structure (headings, paragraphs), a few hundred tokens per chunk with a small overlap; keep the title and URL with each chunk for citations.
- **Hybrid search** (full-text + vector) handles names, codes and exact terms better than vectors alone.
- **Freshness:** re-embed when documents change; delete chunks when documents are deleted (cascade); version the embedding model.
- Start with Postgres + pgvector; a dedicated vector database only when measured scale requires it (`tech-stack-advisor`).

## 8. Evaluation and monitoring

- Build a **test set** of real tasks with expected answers or grading criteria (accuracy, citations, tone, refusals) before tuning prompts.
- Run it on every prompt or model change; track quality, latency and cost together.
- Monitor in production: error and refusal rates, latency (time to first token), cost per user, feedback scores, flagged conversations.
- Review a sample of real conversations regularly (with privacy rules) — that's where the useful test cases come from.

## Checklist

- [ ] Model calls server-side only; keys never in the client; model version pinned.
- [ ] Streaming with stop, retry, sources and feedback; AI is disclosed; output rendered safely.
- [ ] No secrets in prompts; tools least-privilege, acting as the user; side effects need confirmation.
- [ ] Output validated; never executed; shown to others with UGC rules.
- [ ] Data minimized; provider DPA, region and training settings recorded; logs with retention.
- [ ] Rate limits, token limits, budgets, spend alerts and a kill switch.
- [ ] RAG filters by tenant and permissions in the query; citations; deletion cascades.
- [ ] Evaluation set run on every prompt or model change; production monitoring in place.

## Output format

```markdown
## AI feature review: support assistant

| # | Area | Finding | Fix |
|---|------|---------|-----|
| 1 | Security | Assistant tool `sendEmail` runs without confirmation | propose → user confirms in UI → server sends |
| 2 | RAG | Vector query has no tenant filter | `WHERE tenant_id = $1` before `ORDER BY embedding <=> $2` |
| 3 | Costs | No per-user limit, one user spent €400 in a day | rate limit + daily token budget + spend alert |
| 4 | UX | No stop button, no sources | stop + citations with links |
```

## Related skills

- `backend-security-auditor` (auth, IDOR, rate limits), `frontend-security` (rendering output), `gdpr-privacy` (processors, retention), `database-design` (pgvector schema), `deploy-and-ops` (flags, budgets, monitoring), `tech-stack-advisor` (provider and vector store choice), `claude-api` (Anthropic API specifics, if installed).
