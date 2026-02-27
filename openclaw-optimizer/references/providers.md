# OpenClaw Optimizer — Provider Reference
# Aligned with OpenClaw v2026.2.26 | Source: docs.openclaw.ai/providers

---

## Provider Quick Reference (All 29)

| Provider | Slug | Auth Env Var | Model Format | Notes |
|---|---|---|---|---|
| Anthropic | `anthropic` | `ANTHROPIC_API_KEY` | `anthropic/claude-opus-4-6` | Prompt caching; prefer direct for Opus/Sonnet |
| OpenAI | `openai` | `OPENAI_API_KEY` | `openai/gpt-5.1-codex` | — |
| OpenAI Codex (OAuth) | `openai-codex` | Device flow | `openai-codex/gpt-5.3-codex` | ChatGPT subscription |
| Google Gemini | `google` | `GEMINI_API_KEY` | `google/gemini-3-pro-preview` | 1M context Flash variant |
| Google Vertex AI | `google-vertex` | gcloud ADC | — | `gcloud auth application-default login` |
| Mistral | `mistral` | `MISTRAL_API_KEY` | `mistral/mistral-large-latest` | Also: audio via `voxtral-mini-latest` |
| Groq | `groq` | `GROQ_API_KEY` | `groq/<model-id>` | Run `openclaw models list` after auth |
| xAI (Grok) | `xai` | `XAI_API_KEY` | `xai/grok-code-fast-1` | — |
| OpenRouter | `openrouter` | `OPENROUTER_API_KEY` | `openrouter/anthropic/claude-sonnet-4-5` | `openclaw models scan` for free models |
| Amazon Bedrock | `amazon-bedrock` | AWS env chain | `amazon-bedrock/us.anthropic.claude-opus-4-6-v1:0` | Auto-discovery via `bedrockDiscovery` |
| Together AI | `together` | `TOGETHER_API_KEY` | `together/moonshotai/Kimi-K2.5` | — |
| Cloudflare AI Gateway | `cloudflare-ai-gateway` | `CLOUDFLARE_AI_GATEWAY_API_KEY` | `cloudflare-ai-gateway/claude-sonnet-4-5` | Analytics + caching layer |
| Vercel AI Gateway | `vercel-ai-gateway` | `AI_GATEWAY_API_KEY` | `vercel-ai-gateway/anthropic/claude-opus-4.6` | Shorthand auto-expanded |
| **Kilo Gateway** | `kilocode` | `KILOCODE_API_KEY` | `kilocode/anthropic/claude-opus-4.6` | New in v2026.2.23; single key → 9 providers |
| Moonshot (Kimi) | `moonshot` | `MOONSHOT_API_KEY` | `moonshot/kimi-k2.5` | 256K ctx; NOT interchangeable with kimi-coding |
| Kimi Coding | `kimi-coding` | `KIMI_API_KEY` | `kimi-coding/k2p5` | Separate product from Moonshot |
| Z.AI / GLM | `zai` | `ZAI_API_KEY` | `zai/glm-5` | `tool_stream` enabled by default |
| MiniMax | `minimax` | `MINIMAX_API_KEY` | `minimax/MiniMax-M2.1` | Anthropic-messages API type |
| Venice AI | `venice` | `VENICE_API_KEY` | `venice/llama-3.3-70b` | Privacy-first; 25 models; no logging |
| Hugging Face | `huggingface` | `HF_TOKEN` | `huggingface/deepseek-ai/DeepSeek-R1` | Add `:cheapest`/`:fastest` policy suffix |
| Synthetic | `synthetic` | `SYNTHETIC_API_KEY` | `synthetic/hf:MiniMaxAI/MiniMax-M2.1` | Zero-cost; 19 models |
| Ollama (local) | `ollama` | `OLLAMA_API_KEY` (any) | `ollama/llama3.3` | Auto-discovered when env var set |
| vLLM (local) | `vllm` | `VLLM_API_KEY` (any) | `vllm/<model-id>` | `http://127.0.0.1:8000/v1` default |
| Volcano Engine | `volcengine` | `VOLCANO_ENGINE_API_KEY` | `volcengine/<model-id>` | No dedicated doc page |
| BytePlus | `byteplus` | `BYTEPLUS_API_KEY` | `byteplus/<model-id>` | No dedicated doc page |
| Qianfan (Baidu) | `qianfan` | `bce-v3/ALTAK-...` | `qianfan/<model-id>` | China market |
| OpenCode Zen | `opencode` | `OPENCODE_API_KEY` | `opencode/claude-opus-4-6` | Beta; uses Kilo infra |
| GitHub Copilot | `github-copilot` | `COPILOT_GITHUB_TOKEN` | `github-copilot/gpt-4o` | ChatGPT subscription via device flow |
| Cerebras | `cerebras` | `CEREBRAS_API_KEY` | `cerebras/zai-glm-4.7` | — |

---

## Adding a Provider (CLI-First Workflow)

```bash
# Step 1 — Authenticate
openclaw onboard --auth-choice <provider>-api-key   # most providers
openclaw models auth login --provider <slug>          # alternative
openclaw onboard --auth-choice openai-codex           # ChatGPT OAuth
openclaw models auth login-github-copilot             # GitHub Copilot

# Step 2 — Verify
openclaw models list
openclaw models status --probe --probe-provider <slug>

# Step 3 — Set as primary
openclaw models set <provider/model>

# Step 4 — Add fallbacks
openclaw models fallbacks add openrouter/anthropic/claude-sonnet-4-5
openclaw models fallbacks add ollama/llama3.3
```

---

## Kilo Gateway (v2026.2.23+) — One Key, Nine Providers

```bash
openclaw onboard --kilocode-api-key <your-key>
# Routes to:
# kilocode/anthropic/claude-opus-4.6    (default)
# kilocode/anthropic/claude-sonnet-4.5
# kilocode/openai/gpt-5.2
# kilocode/google/gemini-3-pro-preview
# kilocode/google/gemini-3-flash-preview
# kilocode/x-ai/grok-code-fast-1
# kilocode/z-ai/glm-5:free
# kilocode/minimax/minimax-m2.5:free
# kilocode/moonshotai/kimi-k2.5
```

---

## Local Providers

**Ollama:**
```bash
ollama pull llama3.3
ollama serve
export OLLAMA_API_KEY="ollama-local"   # triggers auto-discovery
openclaw models list
```

**OpenRouter free-model scan:**
```bash
openclaw models scan
```

---

## Custom OpenAI-Compatible Provider

For any OpenAI-compatible endpoint (LM Studio, LiteLLM, koboldcpp, local APIs):

```bash
# AI-assisted (fastest): paste in OpenClaw chat:
# "Add custom provider: Name=[slug], Base URL=[url], API key=[key], type=openai-completions"

# Manual: edit ~/.openclaw/openclaw.json then apply:
openclaw gateway call config.apply
```

**Full config schema:**
```json5
{
  models: {
    mode: "merge",    // "merge" keeps built-ins; "replace" discards them
    providers: {
      "my-provider": {
        baseUrl: "http://localhost:4000/v1",
        apiKey: "${MY_API_KEY}",
        api: "openai-completions",   // openai-completions | openai-responses |
                                     // anthropic-messages | google-generative-ai |
                                     // bedrock-converse-stream | ollama
        authHeader: false,
        headers: { "X-Custom": "value" },
        params: { temperature: 0.7 },
        models: [{
          id: "my-model",            // ref: "my-provider/my-model"
          name: "My Model",
          reasoning: false,
          input: ["text"],           // text | image | audio | video
          output: ["text"],
          cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
          contextWindow: 128000,
          maxTokens: 32000,
        }],
      },
    },
  },
  env: { MY_API_KEY: "sk-..." },
  agents: {
    defaults: { model: { primary: "my-provider/my-model" } },
  },
}
```

**Common local setups:**
```json5
// LM Studio
lmstudio: { baseUrl: "http://127.0.0.1:1234/v1", apiKey: "lmstudio", api: "openai-responses" }

// koboldcpp
koboldcpp: { baseUrl: "http://localhost:5000/api/v1", apiKey: "123", api: "openai-completions" }

// LiteLLM proxy
"litellm-proxy": { baseUrl: "http://localhost:4000/v1", apiKey: "${LITELLM_KEY}", api: "openai-completions" }

// Anthropic-compatible endpoint (OpenClaw appends /v1)
"my-proxy": { baseUrl: "https://proxy.example.com/anthropic", apiKey: "${KEY}", api: "anthropic-messages" }
```

**Apply and verify:**
```bash
openclaw gateway call config.apply
openclaw models list
openclaw models status --probe --probe-provider my-provider
```

**Common mistake:** Custom provider defined but NOT set as primary → agent ignores it.
Always run `openclaw models set my-provider/my-model` after adding.

---

## Model Failover & Key Rotation

**Failover chain config:**
```json5
{
  agents: {
    defaults: {
      model: {
        primary: "anthropic/claude-opus-4-6",
        fallbacks: [
          "openrouter/anthropic/claude-sonnet-4-5",
          "venice/claude-opus-45",
          "ollama/llama3.3",
        ],
      },
    },
  },
}
```

Failover triggers on: auth failures, rate limits (429), timeouts.
Cooldown: `1m → 5m → 25m → 1h` (capped). Billing failures: `5h → 10h → 24h` max.
OpenClaw pins the chosen auth profile per session for cache efficiency.

**Known bug — fallback chain stops at 2 models (Issue #25926):**
If you see `"All models failed (2)"` with more fallbacks configured:
```bash
openclaw gateway restart   # resets cooldown state
```

**Multiple API keys (rate-limit resilience):**
```bash
export ANTHROPIC_API_KEYS="sk-ant-key1,sk-ant-key2,sk-ant-key3"  # comma-separated
export ANTHROPIC_API_KEY_1="sk-ant-key1"                          # numbered
export OPENCLAW_LIVE_ANTHROPIC_KEY="sk-ant-..."                   # live override (highest priority)
```
Replace `ANTHROPIC` with any provider slug in uppercase. Keys rotate on 429 only.

---

## Amazon Bedrock — Full Setup

```bash
export AWS_ACCESS_KEY_ID="AKIA..."
export AWS_SECRET_ACCESS_KEY="..."
export AWS_REGION="us-east-1"
```

Required IAM: `bedrock:InvokeModel`, `bedrock:InvokeModelWithResponseStream`, `bedrock:ListFoundationModels`
Or: attach `AmazonBedrockFullAccess`

```json5
{
  models: {
    bedrockDiscovery: {
      enabled: true,
      region: "us-east-1",
      providerFilter: ["anthropic", "amazon"],
      refreshInterval: 3600,
    },
    providers: {
      "amazon-bedrock": {
        baseUrl: "https://bedrock-runtime.us-east-1.amazonaws.com",
        api: "bedrock-converse-stream",
        auth: "aws-sdk",
        models: [{
          id: "us.anthropic.claude-opus-4-6-v1:0",
          contextWindow: 200000,
          maxTokens: 8192,
        }],
      },
    },
  },
}
```

---

## Synthetic Provider — 19 Zero-Cost Models

| Model (use as `synthetic/<id>`) | Context | Max Out |
|---|---|---|
| `hf:MiniMaxAI/MiniMax-M2.1` | 192K | 65,536 |
| `hf:moonshotai/Kimi-K2-Thinking` (reasoning) | 256K | 8,192 |
| `hf:zai-org/GLM-4.7` | 198K | 128K |
| `hf:deepseek-ai/DeepSeek-R1-0528` (reasoning) | 128K | 8,192 |
| `hf:deepseek-ai/DeepSeek-V3.2` | 159K | 8,192 |
| `hf:meta-llama/Llama-4-Maverick-17B-128E-Instruct-FP8` | 524K | 8,192 |
| `hf:Qwen/Qwen3-235B-A22B-Instruct-2507` | 256K | 8,192 |
| `hf:Qwen/Qwen3-Coder-480B-A35B-Instruct` | 256K | 8,192 |
| `hf:Qwen/Qwen3-VL-235B-A22B-Instruct` (vision) | 250K | 8,192 |
| `hf:Qwen/Qwen3-235B-A22B-Thinking-2507` (reasoning) | 256K | 8,192 |
| `hf:openai/gpt-oss-120b` | 128K | 8,192 |
| `hf:deepseek-ai/DeepSeek-V3.1` | 128K | 8,192 |
| `hf:deepseek-ai/DeepSeek-V3.1-Terminus` | 128K | 8,192 |
| `hf:moonshotai/Kimi-K2-Instruct-0905` | 256K | 8,192 |
| `hf:zai-org/GLM-4.5` | 128K | 128K |
| `hf:zai-org/GLM-4.6` | 198K | 128K |
| `hf:deepseek-ai/DeepSeek-V3-0324` | 128K | 8,192 |
| `hf:deepseek-ai/DeepSeek-V3` | 128K | 8,192 |
| `hf:meta-llama/Llama-3.3-70B-Instruct` | 128K | 8,192 |

---

## Venice AI — 25 Private Models

**Private (no logging, no storage):** `venice/llama-3.3-70b`, `venice/qwen3-235b-a22b-thinking-2507` (reasoning), `venice/qwen3-coder-480b-a35b-instruct`, `venice/deepseek-v3.2`, `venice/openai-gpt-oss-120b`, and 10 more.

**Anonymized proxy (metadata-stripped, routed to real providers):** `venice/claude-opus-45`, `venice/openai-gpt-52`, `venice/gemini-3-pro-preview`, `venice/grok-code-fast-1`, `venice/kimi-k2-thinking`, and 5 more.

Auth env: `VENICE_API_KEY` (format: `vapi_xxxxxxxxxxxx`)

---

## Hugging Face — Policy Suffixes

```
huggingface/<org>/<model>:cheapest   # lowest cost per output token
huggingface/<org>/<model>:fastest    # highest throughput
huggingface/<org>/<model>:together   # force Together backend
huggingface/<org>/<model>:sambanova  # force SambaNova backend
```

Requires fine-grained token with "Make calls to Inference Providers" permission.
