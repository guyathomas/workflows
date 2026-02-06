# MCP Server Usage Guidelines

Reference guide for MCP (Model Context Protocol) servers used by workflows skills. These servers extend agent capabilities with live documentation, web search, browser debugging, code search, and web scraping.

## Quick Reference: When to Use Which MCP

| Need | MCP Server | Key Tool |
|------|-----------|----------|
| Up-to-date library/framework docs | **Context7** | `resolve-library-id` → `get-library-docs` |
| Real-time Google search results | **Serper** | `google_search` |
| Search code across GitHub repos | **GitHub** | `search_code`, `search_repositories` |
| Scrape web pages into clean markdown | **Firecrawl** | `firecrawl_scrape` |
| Debug web app runtime errors | **Chrome DevTools** | `evaluate_script`, `list_console_messages` |
| Visual verification of UI changes | **Chrome DevTools** | `take_screenshot` |
| Web performance analysis | **Chrome DevTools** | `performance_start_trace` → `performance_analyze_insight` |

---

## Context7

**Purpose:** Fetches current, version-specific library documentation directly from source. Solves the problem of stale training data causing hallucinated APIs and deprecated patterns.

**Repo:** [github.com/upstash/context7](https://github.com/upstash/context7)

### Tools

| Tool | Parameters | Purpose |
|------|-----------|---------|
| `resolve-library-id` | `libraryName` (required), `query` (required) | Resolves a library name into a Context7-compatible ID. Call this first. |
| `get-library-docs` | `context7CompatibleLibraryID` (required), `topic` (optional), `tokens` (optional, default 5000) | Fetches documentation chunks and code examples for the resolved library. |

### Usage Rules

1. **Always call `resolve-library-id` first** to get the exact Context7-compatible library ID, unless you already know the ID in `/org/project` format.
2. **Use specific topic queries.** Good: `"How to set up authentication with JWT in Express.js"`. Bad: `"auth"`.
3. **Limit to 3 calls per question.** If you cannot find what you need after 3 calls, use the best information available and move on.
4. **Skip `resolve-library-id`** if you already know the library's Context7 ID — provide it directly.
5. **Token budget:** Each `resolve-library-id` call returns ~7,000 tokens. Each `get-library-docs` returns 4,000–10,000 tokens depending on the `tokens` parameter. Set `tokens` to the minimum needed.

### When to Use

- Writing code with libraries that may have changed since model training cutoff
- Need version-specific API docs, recommended patterns, or deprecation notices
- Validating approach against current official documentation

### When NOT to Use

- Working with proprietary/internal libraries not indexed by Context7
- Working offline (requires network access)
- Very niche packages unlikely to be indexed

### Fallback

If Context7 is unavailable, use `WebSearch` to find official documentation and `WebFetch` or `firecrawl_scrape` to read it.

---

## Serper Search

**Purpose:** Real-time Google search via the Serper.dev API. Returns structured JSON results (organic, knowledge graph, "people also ask", related searches) without HTML parsing.

**Repo:** [github.com/marcopesani/mcp-server-serper](https://github.com/marcopesani/mcp-server-serper)

### Tools

| Tool | Parameters | Purpose |
|------|-----------|---------|
| `google_search` | `query` (required), `numResults` (default 10, max 100), `gl` (country), `hl` (language) | Perform Google searches with structured results. |

### Usage Rules

1. **Keep queries short and specific** for best result quality.
2. **Use `numResults` wisely.** Default 10 is usually sufficient. Only increase for broad research.
3. **Use locale parameters** (`gl`, `hl`) when searching for region-specific information.
4. **Serper returns snippets, not full page content.** To read a full page from search results, follow up with Firecrawl (`firecrawl_scrape`) or `WebFetch`.
5. **Combine with other MCPs:** Use Serper to find URLs, then Firecrawl to scrape them, or Context7 for library-specific docs.

### When to Use

- Finding real-world implementations, blog posts, comparison articles
- Searching for best practices with current year context
- Market research or competitive intelligence
- Fact-checking claims against multiple sources
- Finding official guides and tutorials

### When NOT to Use

- You need full page content (use Firecrawl or WebFetch after getting the URL)
- You need library-specific documentation (use Context7)
- You need to interact with web pages (use Chrome DevTools)

### Fallback

If Serper is unavailable, use the built-in `WebSearch` tool.

---

## GitHub Search

**Purpose:** Direct access to GitHub's platform — search code across repositories, browse files, manage issues/PRs, inspect CI/CD workflows, and surface security alerts.

**Repo:** [github.com/github/github-mcp-server](https://github.com/github/github-mcp-server)

### Key Toolsets

| Toolset | Purpose |
|---------|---------|
| `repos` | Browse code, search files, analyze commits, understand project structure |
| `issues` | Create, update, triage, label, and manage issues |
| `pull_requests` | File, review, label, merge PRs |
| `actions` | Monitor GitHub Actions runs, analyze build failures |
| `code_security` | Surface code scanning and Dependabot alerts |

### Tools for Research (most relevant to workflows)

| Tool | Purpose |
|------|---------|
| `search_code` | Find how a pattern/API is used across real codebases |
| `search_repositories` | Find projects solving the same problem |
| `get_file_contents` | Read specific files from any public repo |

### Usage Rules

1. **Use `search_code` for pattern validation.** Find how production codebases implement a pattern before committing to an approach.
2. **Use `search_repositories` for prior art.** Find projects that already solve your problem.
3. **Use read-only mode** (`--read-only`) when doing research to prevent accidental modifications.
4. **Be aware of rate limits.** GitHub API has rate limits — batch related queries and avoid redundant calls.
5. **Filter by language and quality.** When searching code, filter by language and look at repos with meaningful star counts for higher-quality examples.

### When to Use

- Validating implementation approaches against real codebases (planning skill)
- Finding how production code structures a specific pattern
- Searching for common pitfalls in a library/API usage
- Identifying popular libraries that solve a problem

### When NOT to Use

- You need documentation, not code examples (use Context7)
- You need general web results (use Serper)
- You need to perform operations the GitHub API does not support

### Fallback

If GitHub MCP is unavailable, use `WebSearch` with `site:github.com` queries, or the `gh` CLI for repository operations.

---

## Firecrawl

**Purpose:** Converts web pages into clean, LLM-ready markdown. Handles JavaScript rendering, bypasses common anti-bot protections, and extracts structured data.

**Repo:** [github.com/firecrawl/firecrawl-mcp-server](https://github.com/firecrawl/firecrawl-mcp-server)

### Tools

| Tool | Purpose | When to Use |
|------|---------|-------------|
| `firecrawl_scrape` | Extract content from a single URL as clean markdown. | Reading a specific article, docs page, or blog post. **This is the primary tool.** |
| `firecrawl_search` | Search the web and optionally scrape top results. | When you don't know which URL has the information. |
| `firecrawl_map` | Discover URLs on a site before scraping. | Exploring a site's structure to decide what to scrape. |
| `firecrawl_crawl` | Follow links and extract content from multiple pages. | Getting content from an entire section. **Use sparingly.** |
| `firecrawl_batch_scrape` | Scrape multiple known URLs in parallel. | Processing a list of URLs from search results. |
| `firecrawl_extract` | Extract structured data using a JSON schema. | When you need specific fields (price, title, date) in structured format. |

### Usage Rules

1. **Use `firecrawl_scrape` for single pages, never `firecrawl_crawl`.** Crawling follows links and can return massive data that exceeds context limits.
2. **Use `firecrawl_map` before `firecrawl_crawl`** to discover URLs first, then selectively batch-scrape only the ones you need.
3. **Set depth limits on crawls.** Without limits, responses can blow past context windows.
4. **Prefer `firecrawl_scrape` over `firecrawl_extract`** for simple content extraction. `extract` is more expensive and should be reserved for structured data extraction.
5. **Be aware of context window cost.** Every token of scraped content counts against your context limit. For large pages, consider reading selectively.

### When to Use

- Scraping JavaScript-rendered or dynamic web pages
- Converting documentation pages to clean markdown for analysis
- Getting full page content after finding URLs via Serper search
- Extracting structured data (prices, specs, tables) from web pages

### When NOT to Use

- You need to interact with a page (click, fill forms) — use Chrome DevTools
- You only need search snippets — use Serper
- You need library documentation — use Context7 (purpose-built for this)
- Static pages where `WebFetch` is sufficient

### Fallback

If Firecrawl is unavailable, use the built-in `WebFetch` tool. `WebFetch` works for static pages but cannot render JavaScript or bypass anti-bot protections.

---

## Chrome DevTools

**Purpose:** Controls and inspects a live Chrome browser. Gives agents the ability to see runtime errors, debug console output, take screenshots, analyze performance, and interact with web pages.

**Repo:** [github.com/anthropics/anthropic-quickstarts/tree/main/mcp-server-chrome-devtools](https://github.com/anthropics/anthropic-quickstarts/tree/main/mcp-server-chrome-devtools) or [github.com/nicobailon/chrome-devtools-mcp](https://github.com/nicobailon/chrome-devtools-mcp)

### Tools by Category

**Debugging (most relevant to workflows)**

| Tool | Purpose |
|------|---------|
| `evaluate_script` | Run JavaScript in the page context |
| `list_console_messages` | Read console errors, warnings, and logs |
| `take_screenshot` | Capture current page state as an image |
| `take_snapshot` | Capture DOM snapshot |

**Navigation**

| Tool | Purpose |
|------|---------|
| `navigate_page` | Go to a URL |
| `list_pages` | List open tabs |
| `select_page` | Switch to a tab |
| `wait_for` | Wait for an element, navigation, or network idle |

**Input Automation**

| Tool | Purpose |
|------|---------|
| `click` | Click an element |
| `fill` | Fill an input field |
| `fill_form` | Fill multiple form fields at once |
| `hover` | Hover over an element |

**Network**

| Tool | Purpose |
|------|---------|
| `list_network_requests` | Analyze HTTP requests/responses |
| `get_network_request` | Inspect a specific request (headers, body, timing) |

**Performance**

| Tool | Purpose |
|------|---------|
| `performance_start_trace` | Begin recording a performance trace |
| `performance_stop_trace` | Stop recording |
| `performance_analyze_insight` | Analyze trace for Core Web Vitals (LCP, FID, CLS) |

**Emulation**

| Tool | Purpose |
|------|---------|
| `emulate_cpu` | Simulate slow CPU |
| `emulate_network` | Simulate slow network (3G, offline) |
| `resize_page` | Test different viewport sizes |

### Usage Rules

1. **Security: Do not use with browser sessions containing sensitive data** (banking, email, credentials). This MCP exposes browser content to the agent.
2. **Use `list_console_messages` first** when debugging runtime errors — console output often contains the exact error and stack trace.
3. **Use `take_screenshot` for visual verification** after making UI changes, rather than assuming the change looks correct.
4. **Use `list_network_requests` to diagnose API issues** — inspect failed requests, CORS errors, missing resources, and slow responses.
5. **Combine debugging + file editing** for a closed-loop workflow: see error in browser → edit source → verify fix in browser.
6. **Use performance tools judiciously.** Performance traces generate large amounts of data. Only trace when investigating specific performance issues.

### When to Use

- Debugging runtime errors, console warnings, or visual regressions in web applications
- Investigating performance issues (slow LCP, layout shifts, render-blocking resources)
- Visually verifying UI changes via screenshots
- Testing responsive design across viewport sizes
- Diagnosing network issues (failed API calls, CORS, slow responses)
- Automating browser interaction for testing

### When NOT to Use

- Not working on web/frontend development
- Need to scrape page content (use Firecrawl — it's faster and cheaper)
- Need headless browser automation at scale (use Puppeteer/Playwright directly)
- Browser contains sensitive personal data

### Fallback

If Chrome DevTools MCP is unavailable, use `evaluate_script` and console log analysis through manual browser inspection. For screenshots, there is no direct fallback — describe expected visual state in verification instead.

---

## MCP Availability Detection

At the start of any skill that uses MCPs, check availability:

```
1. Check if the required MCP tool exists (e.g., can you call it?)
2. If available → use it
3. If unavailable → use fallback (WebSearch, WebFetch, gh CLI)
4. Record which tools are available in state/context for consistency
```

The research skill demonstrates this pattern: it checks for `firecrawl-mcp:firecrawl_scrape` in INIT phase and records the choice as `"scraper": "firecrawl"` or `"scraper": "webfetch"` in `state.json`.

## MCP Combination Patterns

### Research Pattern (planning, research skills)
```
Context7 (library docs) + Serper (web search) + GitHub (code search)
→ Three complementary perspectives on implementation approaches
```

### Deep Scraping Pattern (research skill)
```
Serper (find URLs) → Firecrawl (scrape full content)
→ Structured search followed by deep content extraction
```

### Web Debugging Pattern (systematic-debugging skill)
```
Chrome DevTools (identify error) → Edit source → Chrome DevTools (verify fix)
→ Closed-loop debugging without leaving the agent session
```

### Documentation Research Pattern
```
Context7 (official docs) → Serper (community guides) → Firecrawl (scrape detailed articles)
→ Official docs supplemented with real-world usage guides
```
