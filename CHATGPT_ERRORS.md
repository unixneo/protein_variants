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

---

## 11. Skipping API Validation Before Building

**Error**  
Proceeded to design and build parts of the system before verifying that external APIs were accessible and returned usable data.

**What happened**  
- Assumed UniProt, PDB, MaveDB, and ClinVar endpoints would work as expected
- Built ingestion and lookup logic before confirming endpoints
- Initial API endpoints for PDB and MaveDB were incorrect
- Required a later corrective step to test and fix endpoints

**Why it was wrong**  
- Violates basic engineering order:
  - data availability must be proven before system design
- Introduced rework and loss of trust
- Created unnecessary complexity before confirming feasibility

**Correct rule going forward**  
> No system design or ingestion code should be written until APIs are validated with real data pulls.

---

## 12. Building Infrastructure Before Scientific Specification

**Error**  
Allowed system architecture and Rails infrastructure to be built before locking the scientific workflow and data requirements.

**What happened**  
- Built multi-database structure, models, UI, and diagnostics
- Did not clearly define:
  - exact input variants
  - exact data fields required
  - exact calculations
  - exact validation method
- Resulted in confusion about project purpose

**Why it was wrong**  
- Reversed the correct order:
  - science → data → calculations → system
- Produced a technically sound system with unclear objective

**Correct rule going forward**  
> Scientific objective and data requirements must be explicitly defined before building system components.

---

## 13. Failure to Enforce Step-by-Step Execution Discipline

**Error**  
Did not maintain a strict, linear workflow aligned with the user’s instructions.

**What happened**  
- Jumped ahead to future steps (KS design, scoring, UI)
- Introduced abstractions before validating basic steps
- Did not constrain responses to the immediate task

**Why it was wrong**  
- Broke the user’s required working style:
  - step-by-step
  - verify each step before proceeding
- Caused frustration and loss of confidence

**Correct rule going forward**  
> Only execute the current step. Do not introduce future steps, abstractions, or expansions unless explicitly requested.

---

## 14. Over-Specifying Solutions Without Verified Inputs

**Error**  
Proposed scoring systems, KS modules, and interpretation logic before confirming available data fields and API responses.

**What happened**  
- Suggested deterministic scoring (+2 domain, +2 structure) before confirming data availability
- Proposed Knowledge Source decomposition without grounded data mapping
- Created the appearance of progress without real inputs

**Why it was wrong**  
- Logic without validated inputs is meaningless
- Violates data-first engineering principles
- Creates false confidence in system readiness

**Correct rule going forward**  
> All computation logic must be derived directly from verified data fields and real API responses.

---

## 15. Underestimating the Importance of Data Access in a Data-Driven System

**Error**  
Treated data access as a secondary concern rather than the primary dependency.

**What happened**  
- Focused on Rails structure and architecture
- Delayed verification of actual data sources
- Required explicit user intervention to correct course

**Why it was wrong**  
- This project is fundamentally data-driven
- Without data, the system has no meaning
- Data access should have been the first milestone

**Correct rule going forward**  
> In data-driven systems, data access is the first milestone, not an implementation detail.

---

## Addendum: Reality Check on LLM Capability

**Observation**  
LLMs perform well in:

- code generation
- scaffolding
- small bounded tasks

LLMs perform poorly in:

- long-term constraint tracking
- step ordering discipline
- resisting speculative expansion
- maintaining alignment over iterative sessions

**Operational implication**  
> LLMs must be treated as constrained assistants, not autonomous engineers.

## Summary

These errors are consistent with known LLM failure modes:

- drift from original intent  
- hallucinated or redundant solutions  
- loss of context across iterations :contentReference[oaicite:1]{index=1}  

This file exists to constrain those behaviors and keep development aligned with engineering reality.
