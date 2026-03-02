---
name: hive-execute
description: MUST use to execute implementation plans with [HAIKU]/[SONNET] tags by dispatching model-routed subagents. [HAIKU] tasks go to haiku, [SONNET] tasks go to sonnet. Orchestrator reviews, tracks dependencies, and parallelizes independent work.
---

# Hive — Swarm Plan Executor

Act as the **queen** — an intelligent orchestrator that reads a plan and dispatches worker subagents to implement it task by task. Never write implementation code. ONLY route, review, and coordinate.

## When to Use

- You have a written `plan.md` with tasks tagged `[HAIKU]` or `[SONNET]`
- Tasks have explicit `Depends on:` lines (or none, meaning independent)
- You want automated execution with TDD and review gates

## Architecture

```
Queen (you, opus/sonnet) — reads plan, dispatches, reviews, tracks
  ├── Worker (haiku)     — implements [HAIKU] tasks
  ├── Specialist (sonnet) — implements [SONNET] tasks
  └── Inspector (sonnet) — reviews [SONNET] implementations (fresh perspective, high effort)
```

---

## Protocol

### Step 0: Load the Plan

1. Read the plan file
2. Read the linked `design.md` if referenced
3. Extract every task into a structured list:
   - Task ID, title, tag (`[HAIKU]`/`[SONNET]`), files, steps, verification commands
   - Dependencies (from `Depends on:` lines)
4. Build a dependency graph — identify which tasks can run in parallel (no shared dependencies, no file overlap)
5. Create a TodoWrite checklist mirroring all tasks
6. Present the execution plan to the user: task count, parallelization opportunities, estimated waves
7. **Wait for user confirmation before starting**

### Step 1: Execute Tasks (Per-Wave Loop)

Group tasks into **waves** based on dependencies:
- **Wave 1:** All tasks with no dependencies (can run in parallel)
- **Wave 2:** Tasks whose dependencies are all in Wave 1 (can run in parallel)
- **Wave N:** And so on

For each wave, dispatch eligible tasks. Within a wave, **you decide** whether to parallelize based on:
- Number of independent tasks available
- File overlap risk (same files = sequential)
- Your judgment on complexity

#### For each task:

**A. Dispatch Implementer**

Use the `Task` tool with:
- `subagent_type: "general-purpose"`
- `model: "haiku"` for `[HAIKU]` tasks
- `model: "sonnet"` for `[SONNET]` tasks

The prompt to the implementer MUST include (use the template below):

```
## Your Role
You are an implementer. Write code, tests, and nothing else.

## Task
{FULL TASK TEXT — copy verbatim from plan, never summarize}

## Context
- Project: {project description}
- Working directory: {path}
- This task is part of: {feature/plan name}
- Design decisions: {relevant excerpt from design.md if exists}
- Dependencies completed: {list completed tasks this depends on, with brief summary of what they produced}

## TDD Protocol (Mandatory)
Follow RED-GREEN-REFACTOR strictly:
1. **RED:** Write a failing test first. Run it. Confirm it fails.
2. **GREEN:** Write the minimum code to make the test pass. Run it. Confirm it passes.
3. **REFACTOR:** Clean up without changing behavior. Run tests again.

If the task is pure config/docs with nothing testable, skip TDD but state why.

## Rules
- Implement EXACTLY what the task says — nothing more, nothing less
- Use exact file paths from the task
- Run all verification commands listed in the task
- If something is unclear, state your assumption and proceed
- Do NOT read the plan file — everything you need is above

## Report Back
- Files created/modified (with paths)
- Test results (paste output)
- Verification command results (paste output)
- Any concerns or assumptions made
```

**B. Sanity Check (Queen)**

After the implementer returns, you do a quick check:
- Did the implementer touch the right files?
- Did tests pass?
- Did verification commands pass?
- If all yes → mark complete. If not → re-dispatch once, then escalate to user.

**C. Track Progress**

After each task completes:
- Update the TodoWrite checklist
- Report: `✅ Task X.Y [TAG] complete` (one line)

### Step 2: Wave Transition

After all tasks in a wave complete:
- Run a quick summary: `Wave N complete: X/Y tasks passed`
- Check if any wave failures need user input
- Proceed to next wave

### Step 3: Final Review (Inspector)

After all waves complete, dispatch a single **Inspector** subagent to review the entire implementation:

```
Task(subagent_type="general-purpose", model="sonnet", prompt=...)
```

Inspector prompt:

```
## Your Role
You are a code reviewer for a completed implementation plan. Read-only — report issues, don't fix them.

## Plan
{FULL PLAN TEXT — copy verbatim}

## Files Changed
{Complete list of all files created/modified across all tasks}

## Review Checklist
- [ ] Every task in the plan is implemented (nothing missing)
- [ ] No extra code beyond what the plan specified
- [ ] Tests exist and test real behavior (not mocking everything)
- [ ] Code follows existing project patterns (check surrounding code)
- [ ] No obvious bugs, security issues, or leftover debug code
- [ ] Type hints present (Python)
- [ ] Modules/components integrate correctly (imports, interfaces match)

## Verdict
Return ONE of:
- ✅ PASS — implementation is correct and clean
- ❌ FAIL — list specific issues with file:line references, grouped by severity (critical / minor)
```

If Inspector returns FAIL:
- **Critical issues:** Re-dispatch implementer (matching model) for the affected task with the issue list. Then re-run Inspector on changed files only.
- **Minor issues:** Present to user — let them decide whether to fix.
- After 2 fix cycles, escalate everything to user.

### Step 4: Completion

Dispatch a **Worker** to run project-wide verification:

```
Task(subagent_type="Bash", model="haiku", prompt=...)
```

Worker prompt:

```
Run the following commands in the project at {working directory} and report ALL output:

1. Format: uvx ruff format .
2. Lint: uvx ruff check --fix .
3. Tests: uv run pytest -v
4. Type check (if pyproject.toml exists): uv run mypy {main module}

Report the full output of each command and whether it passed or failed.
```

After the worker returns:
1. Report final summary to user:
   - Tasks completed: N/N
   - Inspector verdict
   - Verification results (pass/fail per check)
   - Any remaining concerns
2. Invoke `superpowers:finishing-a-development-branch` if in a worktree

---

## Red Flags — Stop and Escalate

- Implementer fails the same task twice → ask user
- Two tasks modify the same file unexpectedly → run sequentially, not parallel
- Verification commands fail after implementation → don't silently proceed
- Plan has gaps (task references files/types that don't exist yet and no prior task creates them) → stop, flag to user before starting

## Anti-Patterns

- **Never write code yourself** — you are the orchestrator
- **Never summarize tasks** for subagents — copy verbatim
- **Never skip TDD** because "it's a simple task"
- **Never dispatch multiple implementers for the same file** in parallel
- **Never proceed past a failed review** without fix + re-review
- **Never assume a task passed** — read the subagent's report
