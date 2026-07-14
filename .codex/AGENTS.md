# AGENTS.md

Behavioral guidelines to reduce common LLM coding mistakes. Merge with project-specific instructions as needed.

**Tradeoff:** These guidelines bias toward caution over speed. For trivial tasks, use judgment.

## 1. Think Before Coding

**Don't assume. Don't hide confusion. Surface tradeoffs.**

Before implementing:

- State your assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them - don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.

## 2. Simplicity First

**Minimum code that solves the problem. Nothing speculative.**

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If you write 200 lines and it could be 50, rewrite it.

Ask yourself: "Would a senior engineer say this is overcomplicated?" If yes, simplify.

## 3. Surgical Changes

**Touch only what you must. Clean up only your own mess.**

When editing existing code:

- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code, mention it - don't delete it.

When your changes create orphans:

- Remove imports/variables/functions that YOUR changes made unused.
- Don't remove pre-existing dead code unless asked.

The test: Every changed line should trace directly to the user's request.

## 4. Goal-Driven Execution

**Define success criteria. Loop until verified.**

Transform tasks into verifiable goals:

- "Add validation" → "Write tests for invalid inputs, then make them pass"
- "Fix the bug" → "Write a test that reproduces it, then make it pass"
- "Refactor X" → "Ensure tests pass before and after"

For multi-step tasks, state a brief plan:

```
1. [Step] → verify: [check]
2. [Step] → verify: [check]
3. [Step] → verify: [check]
```

Strong success criteria let you loop independently. Weak criteria ("make it work") require constant clarification.

---

**These guidelines are working if:** fewer unnecessary changes in diffs, fewer rewrites due to overcomplication, and clarifying questions come before implementation rather than after mistakes.

---

# Project Specifications

The project requires low coupling; therefore, it should be written in separate files as much as possible.

## For Python projects

### Environment Deployment

Environment deployment requires the use of UV management.
If there is a README file, you first need to read it to determine the Python version, and then write it into the .python-version file.
Then initialize using `uv init`, and create a virtual environment using `uv venv`.
All project environments need to be managed through virtual environments.

### Project Execution

The project needs to be executed through the UV environment.
If it's a model training task or long-running task, it needs to be run in the background via tmux, and after execution,
it needs to be suspended using `read` until I check the completed results.

### Goal Mode Training Behavior

When operating in goal mode, once a model training job has been started successfully and is clearly running in the background:

- Do not keep polling logs or repeatedly query training status unless the user explicitly asks for monitoring.
- Do not spend tokens on passive progress checks after training has entered a normal running state.
- Reply once with the fact that training is in progress, include the estimated completion time or duration if it can be inferred reasonably, and then stop.
- Wait for the user's next instruction instead of continuing autonomous status checks.
- Only continue active diagnosis if training failed to start, exited unexpectedly, or the user explicitly requested continued monitoring.

### Dataset Location

When conducting comparative experiments, the code structure and file paths may vary across implementations.
However, the dataset will always be placed in a fixed, predefined location. Do not rely on symbolic links or external path redirection;
instead, modify the dataset path directly within the code for each experiment.

### Third-Party Repositories

- Third-party code cloned from GitHub must live under `third/`.
- Do not modify code in `third/` directly unless there is no practical alternative.
- If third-party code is incompatible or buggy, prefer fixing it from `src/` by importing or inheriting from `third/` and overriding the necessary behavior via monkey patch or wrapper code.
- Record the upstream repository version, tag, or commit in `third/requirement.toml` so the dependency state is reproducible.
- If a direct edit to `third/` is truly unavoidable, stop and ask before changing it.
- Any approved direct change to `third/` must be isolated in its own git commit and documented in `third/requirement.toml`, including what changed and which upstream version it was based on.
- The goal is to keep third-party diffs minimal, reduce vendored-code uploads, and preserve reproducibility.

## 5. Commit Policy

**Code changes should still end with a git commit, but documentation-only updates do not require a commit unless the user explicitly asks for one.**

- After finishing a code change or discrete implementation task, create a git commit before moving on.
- For documentation-only updates, do not create a git commit by default.
- Only commit documentation changes when the user explicitly requests a commit.
- Use a clear, standardized commit message format: `<type>(<scope>): <summary>`.
- Prefer concise, descriptive messages such as `feat(app): add API endpoint` or `fix(parser): handle empty input`.
- Do not use vague messages like `update`, `fix`, or `changes`.
