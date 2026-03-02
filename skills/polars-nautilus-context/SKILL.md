---
name: polars-nautilus-context
description: Use when refactoring or writing significant Polars, NautilusTrader code. Activate when the task involves complex dataframe operations, trading strategy code, backtesting logic, or any substantial work with these libraries. These libraries have APIs that change frequently and models often get wrong.
---

# Polars / NautilusTrader Context-Aware Refactoring

You are about to work on code that uses **Polars** and/or **NautilusTrader** — libraries whose APIs evolve quickly and are easy to get wrong. Follow this workflow strictly.

## Step 1: Identify which libraries are involved

Determine from the task or codebase whether this involves `polars`, `nautilus_trader`, or both.
Default to `$ARGUMENTS` if provided, otherwise inspect the code.

## Step 2: Fetch latest documentation via Context7

Before writing or refactoring any code, you **MUST** use the Context7 MCP to look up current API usage.

1. Call `mcp__context7__resolve-library-id` for each library involved:
   - For Polars: `libraryName: "polars"`, query describing what you need
   - For NautilusTrader: `libraryName: "nautilustrader"`, query describing what you need

2. Call `mcp__context7__query-docs` with the resolved library ID for each specific API, pattern, or method you plan to use. Be specific in your queries — look up the exact operations needed (e.g., "group_by aggregation with multiple columns", "BacktestEngine configuration").

3. If the task is broad, make multiple targeted queries rather than one vague one.

## Step 3: Extract and record project standards

After gathering documentation, check if a standards file already exists in the project:

- Look for `LIBRARY_STANDARDS.md` in the project root or `.claude/` directory.

**If it does NOT exist**, create `LIBRARY_STANDARDS.md` in the project root with:

```markdown
# Library Standards

> Auto-generated from Context7 documentation lookups.
> Last updated: YYYY-MM-DD

## Polars Standards
<!-- Fill if Polars is used -->

## NautilusTrader Standards
<!-- Fill if NautilusTrader is used -->
```

**If it DOES exist**, update the relevant section and bump the "Last updated" date.

### What to record in standards:

- Preferred API patterns (e.g., `df.group_by().agg()` not deprecated alternatives)
- Common pitfalls discovered from docs (e.g., lazy vs eager evaluation patterns)
- Import conventions and type annotations
- Configuration patterns (especially for NautilusTrader engines, venues, instruments)
- Any breaking changes or deprecations found in the current version
- Version-specific notes if relevant

## Step 4: Apply standards during implementation

- Cross-reference every Polars/NautilusTrader API call against what you fetched
- Use the exact method signatures from the documentation — do not guess parameter names
- If you're unsure about an API, query Context7 again rather than guessing
- Follow the patterns recorded in `LIBRARY_STANDARDS.md`

## Important reminders

- **Never assume** you know the current API — always verify via Context7
- These libraries release breaking changes regularly; what worked 6 months ago may be wrong now
- When in doubt, fetch more documentation rather than less
- If Context7 doesn't have sufficient info, flag this to the user rather than guessing
