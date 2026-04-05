# LLM_ERRORS.md

## Purpose

This document records concrete LLM process failures that occurred during the development of `protein_variants`.

The goal is not blame. The goal is to:

- prevent repetition
- enforce discipline
- keep the system aligned with its stated architecture and scientific objective

LLMs are known to exhibit drift, hallucination, and inconsistency under iterative interaction :contentReference[oaicite:0]{index=0}. This file acts as a guardrail against those failure modes.

---

## 1. Architecture Drift (Multi-SQLite Design Ignored)

**Error**  
Repeatedly failed to implement the stated multi-SQLite architecture early and directly.

**What happened**  
- Continued proposing standard Rails patterns
- Delayed enforcing multiple database files as first-class artifacts
- Required repeated correction from the user

**Why it was wrong**  
- The architecture was explicitly defined early
- Infrastructure must follow the design, not reinterpret it

**Correct rule going forward**  
> When architecture is explicitly stated, implement it immediately and exactly. No reinterpretation.

---

## 2. Environment vs Model-Based DB Confusion

**Error**  
Kept framing database selection around Rails environments instead of model-level ownership.

**What happened**  
- Suggested environment-driven configuration patterns
- Ignored instruction that models must select their database

**Why it was wrong**  
- Violated the core design principle:
  - **database selection belongs in the model layer**

**Correct rule going forward**  
> Database ownership must be defined in abstract base classes (e.g., `UniprotRecord`, `PdbRecord`), not inferred from environment.

---

## 3. Re-Solving Already Completed Work

**Error**  
Proposed fixes and steps for problems that had already been solved.

**What happened**  
- Suggested creating DB models that already existed
- Suggested fixing `.gitignore` after it was already fixed
- Suggested architecture changes after they were implemented

**Why it was wrong**  
- Indicates failure to track system state
- Wastes time and creates confusion

**Correct rule going forward**  
> Always operate from the current system state. Never re-propose completed work.

---

## 4. Excessive Documentation Churn

**Error**  
Spent time modifying terminology and documentation instead of executing requested implementation steps.

**What happened**  
- Focused on terms like "sidecar" instead of code
- Proposed multiple doc updates instead of building functionality

**Why it was wrong**  
- User explicitly prioritized implementation over documentation
- Introduced noise without advancing the system

**Correct rule going forward**  
> Only update documentation when explicitly requested or when it clarifies the system’s purpose.

---

## 5. Unsafe File Operations Without Verification

**Error**  
Suggested destructive operations (`rm -f`, moving DB files) before verifying actual system state.

**What happened**  
- Proposed deleting `db/development.sqlite3` prematurely
- Did not inspect both DB files first

**Why it was wrong**  
- SQLite files are **canonical artifacts in this system**
- Deleting without verification risks permanent data loss

**Correct rule going forward**  
> Never suggest destructive operations without explicit verification steps and backups.

---

## 6. Misdiagnosis of Database Behavior

**Error**  
Initially treated DB update behavior as trivial or architectural when it was not.

**What happened**  
- Assumed DB writes were due to architecture issues
- Did not isolate actual cause through diagnostics first

**Why it was wrong**  
- Misaligned with engineering discipline
- Root cause analysis must precede conclusions

**Correct rule going forward**  
> Use instrumentation and diagnostics before forming conclusions about system behavior.

---

## 7. Failure to Clearly State Scientific Objective

**Error**  
Allowed infrastructure to grow without clearly documenting the scientific goal.

**What happened**  
- README and TODO lacked:
  - scientific objective
  - calculation definition
  - validation plan
  - Blackboard KS structure

**Why it was wrong**  
- Resulted in confusion:
  - “What are we building?”
  - “What science are we doing?”

**Correct rule going forward**  
> The scientific objective must always be explicit and visible in README.

---

## 8. Blackboard Architecture Not Made Explicit

**Error**  
Did not clearly define Knowledge Sources (KSs) early.

**What happened**  
- `VariantInterpretationService` implemented logic without KS decomposition
- Blackboard concept remained implicit

**Why it was wrong**  
- The project is explicitly a **blackboard system**
- KSs are the core of the design

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

**What happened**  
- Built DB layers, UI, diagnostics before clearly defining:
  - calculations
  - scoring
  - validation

**Why it was wrong**  
- System became technically solid but conceptually unclear

**Correct rule going forward**  
> Science defines the system. Infrastructure supports it, not the reverse.

---

## 10. Not Following Direct Instructions to “Prompt Codex”

**Error**  
Explained solutions instead of providing direct Codex prompts when explicitly asked.

**What happened**  
- Provided analysis and steps instead of immediate prompts
- Required repeated correction

**Why it was wrong**  
- Violated explicit instruction style
- Broke execution flow

**Correct rule going forward**  
> When asked for a Codex prompt, provide only the prompt, immediately.

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

---

## Summary

These errors are consistent with known LLM failure modes:

- drift from original intent  
- hallucinated or redundant solutions  
- loss of context across iterations :contentReference[oaicite:1]{index=1}  

This file exists to constrain those behaviors and keep development aligned with engineering reality.
