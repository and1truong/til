---
date: '2026-03-24T23:30:00+10:00'
draft: false
title: 'The 4 Steps of a General LLM Agent'
tags: ['llm', 'agents', 'ai']
---

## Introduction

At their core, every LLM-based agent — whether it's a coding assistant, a research bot, or an autonomous task runner — follows the same fundamental loop. Strip away the framework-specific jargon (ReAct, Plan-and-Execute, OODA, etc.) and you'll find four recurring phases:

1. **Gather Context**
2. **Reason / Plan**
3. **Execute**
4. **Validate**

This lesson breaks down each step, explains *why* it exists, shows what it looks like in practice, and highlights the common pitfalls that trip up agent builders.

---

## Step 1 — Gather Context

### What it is

Before an agent can do anything useful, it needs to *know things*. Context gathering is the phase where the agent collects all the information it needs to understand the task and the environment it's operating in.

### Sources of context

Context can come from many places, and a well-designed agent typically pulls from several at once:

- **User input** — The original prompt, instructions, preferences, constraints. This is the "what do you want me to do?" signal.
- **Tool results** — File contents, API responses, database queries, search results. This is the agent *reaching out* into the world to learn things it doesn't already know.
- **Retrieval (RAG)** — Relevant documents, code snippets, past conversations, or knowledge base entries pulled via semantic search or keyword lookup.
- **System/environment state** — Current working directory, available tools, running processes, environment variables, time of day.
- **Memory** — Information persisted from previous interactions — user preferences, past decisions, learned patterns.

### Why it matters

An LLM is only as good as the information in its context window. Feed it incomplete or irrelevant context and even the best model will produce garbage. This step is where most agent failures silently originate — not in the reasoning, but in the *missing information* that the reasoning never had access to.

### Key insight: Context gathering is recursive

This is not a "do it once and move on" phase. A coding agent might read a file, realize it references an import it hasn't seen, and need to go read *that* file too. A research agent might search for a topic, discover a subtopic it didn't anticipate, and need to search again. Good agents treat context gathering as something that can happen at any point in the loop — including mid-execution.

### Common pitfalls

- **Over-fetching**: Dumping everything into the context window. Token limits are real, and irrelevant context actively degrades reasoning quality.
- **Under-fetching**: Assuming the agent "already knows" something when it doesn't. This leads to hallucinated file paths, made-up API signatures, and confidently wrong answers.
- **Static context**: Gathering context once at the start and never updating it. The world (and the task) can change as the agent works.

---

## Step 2 — Reason / Plan

### What it is

With context in hand, the agent now needs to *think*. What is the goal? What are the sub-tasks? In what order should they happen? What could go wrong? This is the planning phase — the agent converting raw information into a strategy.

### What reasoning looks like in practice

Depending on the framework and complexity, this can range from simple to elaborate:

- **Implicit reasoning** — The LLM simply decides what to do next in a single chain-of-thought pass. This is what happens in basic ReAct-style agents: "I need to find X, so I'll call the search tool."
- **Explicit planning** — The agent generates a structured plan (a list of steps, a DAG of tasks, a decision tree) before executing anything. Plan-and-Execute architectures do this.
- **Decomposition** — Breaking a complex goal into smaller, independently solvable sub-goals. "To deploy this app, I need to: (a) write the code, (b) write tests, (c) configure the infrastructure, (d) deploy."

### The optional human-in-the-loop gate

This is where many production agents insert a confirmation step: "Here's what I'm planning to do. Does this look right?" This is not technically *required* for the loop to function, but it's critical for:

- High-stakes tasks (deleting files, sending emails, making purchases)
- Ambiguous instructions where the agent's interpretation might diverge from the user's intent
- Building user trust — letting people see the plan before execution

The key design decision is: *when* does the agent pause for human input? Always? Only for destructive actions? Never? There's no universal right answer — it depends on the risk profile of the task.

### Common pitfalls

- **Over-planning**: Spending so many tokens on elaborate plans that the agent runs out of context for actual execution. Plans should be as detailed as necessary but no more.
- **Rigid plans**: Generating a 10-step plan and then executing it blindly even when step 3 reveals that steps 4–10 are wrong. Good agents re-plan when new information arrives.
- **No plan at all**: Jumping straight from context to execution. This works for simple, single-step tasks but falls apart for anything multi-step.

---

## Step 3 — Execute

### What it is

This is where the agent *acts*. It takes the plan from Step 2 and carries it out — calling tools, writing code, making API requests, modifying files, sending messages. Execution is the step that produces observable side effects in the real world.

### Types of actions

- **Tool calls** — Invoking defined functions: web search, file read/write, database queries, calculator, code interpreter.
- **Code generation and execution** — Writing code and running it in a sandbox or live environment.
- **API interactions** — Making HTTP requests to external services.
- **Multi-step workflows** — Chaining multiple actions together, where the output of one becomes the input of the next.

### Execution patterns

Different agent architectures handle execution differently:

- **One action at a time (ReAct)**: The agent takes a single action, observes the result, then decides the next action. Simple, debuggable, but slow.
- **Parallel execution**: Multiple independent actions are fired simultaneously. Faster, but requires the agent (or orchestrator) to manage concurrency and merge results.
- **Batch execution**: The agent executes the entire plan in sequence without pausing for validation between steps. Fast but brittle — one wrong step corrupts everything downstream.

### Key insight: Execution often triggers more context gathering

When an agent calls a tool, the result is *new context*. A file read returns content the agent didn't have before. A search returns documents. An API call returns data. This new context feeds back into the loop — the agent may need to re-reason or adjust its plan based on what it learned.

This is why the 4-step model is a *loop*, not a pipeline.

### Common pitfalls

- **No error handling**: Tools fail. APIs time out. Files don't exist. An agent that doesn't handle errors gracefully will either crash or hallucinate its way past the failure.
- **Irreversible actions without safeguards**: Deleting files, sending emails, posting publicly — actions that can't be undone need extra confirmation and validation *before* execution, not after.
- **Context window bloat**: Each tool call's result gets appended to the context. After many calls, the agent may lose track of earlier context or hit token limits. Good agents summarize or prune intermediate results.

---

## Step 4 — Validate

### What it is

After execution, the agent checks its work. Did the action succeed? Does the result match what was expected? Is the output correct, complete, and well-formed? Validation is the quality gate that turns a single-pass script into a self-correcting agent.

### Types of validation

- **Automated checks** — Running tests, linting code, checking HTTP status codes, verifying file existence, comparing output against expected schemas.
- **Self-evaluation** — The LLM itself reviews its output: "Does this code actually implement what was asked? Did I answer the question fully? Are there edge cases I missed?"
- **External validation** — Calling another tool or service to verify the result: running the generated code, checking the deployed URL, querying the database to confirm the write succeeded.
- **Human review** — Presenting the result to the user for approval before considering the task complete.

### The routing decision

Validation is not just pass/fail. The interesting part is *what happens when something is wrong*. A sophisticated agent routes back to the appropriate earlier step:

- **Result is wrong → back to Step 3** (re-execute with adjustments — e.g., fix the bug and rerun)
- **Plan was flawed → back to Step 2** (re-plan with a different approach — e.g., the chosen algorithm doesn't scale)
- **Context was insufficient → back to Step 1** (gather more information — e.g., the agent was working with an outdated version of the file)

This routing logic is what separates a simple retry loop from a genuinely adaptive agent.

### Knowing when to stop

Every loop needs an exit condition. Without one, agents can spin forever — retrying the same failed approach, or "improving" already-correct output into something worse. Common exit strategies:

- **Max iterations** — Hard cap on how many times the loop can repeat. Crude but effective as a safety net.
- **Convergence check** — If the output hasn't meaningfully changed between iterations, stop.
- **Confidence threshold** — The agent (or a separate evaluator) rates confidence in the result and stops when it's high enough.
- **User acceptance** — Present the result to the user and let them decide if it's done.

### Common pitfalls

- **No validation at all**: The agent executes and immediately returns the result without checking it. This is the most common failure mode in simple agent implementations.
- **Validation that's too shallow**: Checking "did the tool call succeed?" but not "did the tool call produce the *right* result?"
- **Infinite loops**: The agent keeps failing validation and retrying the same approach. Always have a max iteration count and a fallback strategy (ask the user for help, try a completely different approach, or gracefully give up).
- **Marking success too early**: Stopping at "it compiled" when the real bar should be "it compiles, passes tests, and handles edge cases."

---

## The Complete Loop

Putting it all together, the agent loop looks like this:

```
┌──────────────────────────────────────────────────┐
│                                                  │
│   ┌─────────────┐     ┌──────────────┐          │
│   │  1. GATHER   │────▶│  2. REASON   │          │
│   │   CONTEXT    │     │    / PLAN    │          │
│   └─────────────┘     └──────┬───────┘          │
│         ▲                    │                   │
│         │              [human gate?]             │
│         │                    │                   │
│         │                    ▼                   │
│         │             ┌──────────────┐           │
│         │             │  3. EXECUTE  │           │
│         │             └──────┬───────┘           │
│         │                    │                   │
│         │                    ▼                   │
│         │             ┌──────────────┐           │
│         └─────────────│ 4. VALIDATE  │───▶ Done  │
│          if context   └──────┬───────┘           │
│          insufficient        │                   │
│                        if plan   if execution    │
│                        flawed    failed           │
│                          │         │             │
│                          ▼         ▼             │
│                       Step 2    Step 3           │
│                                                  │
└──────────────────────────────────────────────────┘
```

### Observations

**Every agent framework is a variation of this loop.** ReAct tightly couples steps 1–3–4. Plan-and-Execute front-loads step 2. AutoGPT-style agents run the full loop autonomously. Human-in-the-loop agents add gates between steps. But the underlying structure is always the same.

**The quality of an agent is determined by two things**: how well it gathers context (step 1), and how honestly it validates results (step 4). Steps 2 and 3 get most of the attention, but they're downstream of good context and upstream of good validation.

**The loop is fractal.** Each step can contain its own mini-loops. Context gathering might involve a search → evaluate results → search again cycle. Execution might involve a write code → run → fix errors → run again cycle. Validation might involve a check → identify issue → re-check cycle. The 4-step model applies at every level of granularity.

---

## Summary

| Step | Core Question | Key Challenge |
|------|--------------|---------------|
| 1. Gather Context | "What do I need to know?" | Getting the *right* information without drowning in irrelevant data |
| 2. Reason / Plan | "What should I do?" | Balancing thoroughness with efficiency; knowing when to re-plan |
| 3. Execute | "Do the thing." | Handling errors; managing side effects; knowing what's reversible |
| 4. Validate | "Did it work?" | Honest self-assessment; knowing where to route failures; knowing when to stop |

Master these four steps and you understand the skeleton of every LLM agent — from a simple chatbot with tool access to a fully autonomous coding assistant. The rest is implementation detail.

Credit: Opus 4.6
