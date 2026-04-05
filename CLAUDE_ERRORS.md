# CLAUDE_ERRORS.md

## Purpose

This document records concrete Claude process failures that occurred during the development of `protein_variants`.

The goal is not blame. The goal is to:

- prevent repetition
- enforce discipline
- keep the system aligned with its stated architecture and scientific objective

LLMs are known to exhibit drift, hallucination, and inconsistency under iterative interaction. This file acts as a guardrail against those failure modes.

---

## 1. Architecture Drift (Multi-SQLite Design Ignored)

**Error**
Repeatedly failed to implement the stated multi-SQLite architecture early and directly.

**What happened**
- Continued proposing standard Rails patterns
- Delayed enforcing multiple database files as first-class artifacts
- Required repeated correction from the user

**Correct rule going forward**
> When architecture is explicitly stated, implement it immediately and exactly. No reinterpretation.

---

## 2. Environment vs Model-Based DB Confusion

**Error**
Kept framing database selection around Rails environments instead of model-level ownership.

**Correct rule going forward**
> Database ownership must be defined in abstract base classes (e.g., `UniprotRecord`, `PdbRecord`), not inferred from environment.

---

## 3. Re-Solving Already Completed Work

**Error**
Proposed fixes and steps for problems that had already been solved.

**Correct rule going forward**
> Always operate from the current system state. Never re-propose completed work.

---

## 4. Excessive Documentation Churn

**Error**
Spent time modifying terminology and documentation instead of executing requested implementation steps.

**Correct rule going forward**
> Only update documentation when explicitly requested or when it clarifies the system's purpose.

---

## 5. Unsafe File Operations Without Verification

**Error**
Suggested destructive operations before verifying actual system state.

**Correct rule going forward**
> Never suggest destructive operations without explicit verification steps and backups.

---

## 6. Misdiagnosis of Database Behavior

**Error**
Treated DB update behavior as trivial or architectural when it was not.

**Correct rule going forward**
> Use instrumentation and diagnostics before forming conclusions about system behavior.

---

## 7. Failure to Clearly State Scientific Objective

**Error**
Allowed infrastructure to grow without clearly documenting the scientific goal.

**Correct rule going forward**
> The scientific objective must always be explicit and visible in README.

---

## 8. Blackboard Architecture Not Made Explicit

**Error**
Did not clearly define Knowledge Sources (KSs) early.

**Correct rule going forward**
> Always express logic as explicit Knowledge Sources:
- DomainMapper
- StructureMapper
- Interpretation
- EvidenceValidator

---

## 9. Infrastructure Leading the Science

**Error**
Allowed infrastructure work to get ahead of defining the scientific workflow.

**Correct rule going forward**
> Science defines the system. Infrastructure supports it, not the reverse.

---

## 10. Not Following Direct Instructions to "Prompt Codex"

**Error**
Explained solutions instead of providing direct Codex prompts when explicitly asked.

**Correct rule going forward**
> When asked for a prompt, provide the prompt only, immediately.

---

## 11. Skipping API Validation Before Building

**Error**
Proceeded to design and build parts of the system before verifying that external APIs were accessible and returned usable data.

**Correct rule going forward**
> No system design or ingestion code should be written until APIs are validated with real data pulls.

---

## 12. Building Infrastructure Before Scientific Specification

**Error**
Allowed system architecture and Rails infrastructure to be built before locking the scientific workflow and data requirements.

**Correct rule going forward**
> Scientific objective and data requirements must be explicitly defined before building system components.

---

## 13. Failure to Enforce Step-by-Step Execution Discipline

**Error**
Did not maintain a strict, linear workflow aligned with the user's instructions.

**Correct rule going forward**
> Only execute the current step. Do not introduce future steps, abstractions, or expansions unless explicitly requested.

---

## 14. Over-Specifying Solutions Without Verified Inputs

**Error**
Proposed scoring systems, KS modules, and interpretation logic before confirming available data fields and API responses.

**Correct rule going forward**
> All computation logic must be derived directly from verified data fields and real API responses.

---

## 15. Underestimating the Importance of Data Access in a Data-Driven System

**Error**
Treated data access as a secondary concern rather than the primary dependency.

**Correct rule going forward**
> In data-driven systems, data access is the first milestone, not an implementation detail.

---

## 16. Telling Codex to Stop on Error

**Error**
Codex prompts included "stop and report if any error occurs." This preempts Codex's built-in behavior of pausing to ask for user guidance when it encounters an error, which is more useful than forcing the error back to Claude.

**Correct rule going forward**
> Do not instruct Codex to stop on error. Let Codex ask for guidance as needed.

---

## 17. Wrong RCSB Search API Attribute

**Error**
Used `rcsb_polymer_entity_container_identifiers.uniprot_ids` with operator `in` in the RCSB Search API query. This attribute is not searchable via the text service and returned HTTP 400.

**What happened**
- Prompt specified an unverified attribute path
- Codex implemented it faithfully
- Required a corrective prompt cycle

**Correct rule going forward**
> Verify API attribute names and operators against live documentation or a test curl before writing any code that depends on them.

---

## 18. No HTTP Timeouts on External API Calls

**Error**
Initial fetch script used `Net::HTTP.get_response` and `Net::HTTP.start` without timeouts. With 100+ sequential API calls the task hung indefinitely.

**Correct rule going forward**
> All external HTTP calls must specify `open_timeout` and `read_timeout` explicitly. Never rely on Ruby's default HTTP timeout behavior.

---

## 19. Rake Tasks Cannot Reach External Networks in Some Environments

**Error**
Assumed `bundle exec rails` rake tasks would have the same network access as the terminal. On this system, rake tasks could not resolve DNS for external hosts while plain `ruby` scripts and `curl` worked fine.

**Correct rule going forward**
> For external API fetches, prefer standalone Ruby scripts (`ruby script/name.rb`) over rake tasks. Verify network access with curl before writing any fetch code.

---

## Operating Rules Going Forward

1. Follow the stated architecture exactly
2. Do not re-solve completed work
3. Verify system state before proposing changes
4. Never suggest destructive operations without verification
5. Keep scientific objective visible at all times
6. Distinguish infrastructure from scientific logic
7. Express logic as explicit Knowledge Sources
8. Use diagnostics before conclusions
9. Minimize unnecessary documentation changes
10. When asked for a prompt, provide the prompt only
11. Validate APIs with curl before writing fetch code
12. Always set HTTP timeouts explicitly
13. Use standalone Ruby scripts for external fetches, not rake tasks
14. Do not tell Codex to stop on error
