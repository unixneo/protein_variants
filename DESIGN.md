# protein_variants — Design

## 1. Purpose

This project builds a small, deterministic, rule-based lookup engine for interpreting
protein missense variants using curated biological data.

The primary research goal is to evaluate a controlled experiment in LLM-assisted
scientific software development: can a system built primarily using LLMs produce outputs
that are consistent with peer-reviewed experimental evidence?

**What the system does:**
Given a missense variant residue position, it applies two lookups and one rule:
- Does the position fall inside a curated UniProt functional domain annotation?
- Does the position fall inside a curated PDB experimental structure coverage interval?
- If yes to one or both, the variant is flagged as residing in a structurally or
  functionally characterized region.

That binary output is then compared against MaveDB functional scores and ClinVar
clinical classifications to measure agreement.

**What the system is not:**
This is not a classifier, not a variant effect predictor, and not a probabilistic
inference system. It makes no novel biological claims. It does not outperform existing
tools and does not attempt to. Every output is a deterministic consequence of curated
input data and explicit rules.

The goal is not to "predict biology" broadly. The goal is to demonstrate that an
LLM-assisted development workflow, when properly disciplined, can produce a correct,
inspectable, scientifically auditable system.

---

## 2. Scope (Initial)

Strictly limited to:

- Protein: human proteins
- Variant type: missense only
- First target: TP53
- Numbering: canonical UniProt sequence

Out of scope:

- indels, splice variants, structural variants
- multi-protein interaction modeling
- drug discovery workflows
- AI-based prediction systems
- large-scale ingestion pipelines

---

## 3. Core Entities

- Protein
- Variant
- ProteinFeature (domains, regions)
- StructureEntry (PDB mappings)
- EvidenceItem (external validation)

The system is centered on:

Protein → Variant → Context → Interpretation → Evidence

---

## 4. System Model (Blackboard Style)

The system follows a simplified blackboard architecture:

### L1 — Normalization
- unify identifiers (UniProt accession)
- validate residue positions
- ensure sequence consistency

### L2 — Context Mapping
- map variant position to:
  - annotated domains (ProteinFeature)
  - structural regions (StructureEntry)
- identify overlap and context

### L2 — Interpretation
- apply simple deterministic rules:
  - domain hit
  - structure hit
  - neither

- generate preliminary mechanism classification:
  - structured functional region
  - annotated region
  - structured region
  - unannotated region

### L3 — Verification (Phase 2, in progress)
- compare results to:
  - ClinVar (germline classification, review status)
  - MaveDB (Giacomelli 2018, Kotler 2018 functional scores)
  - peer-reviewed literature

No probabilistic or ML inference is used. The system is deterministic and inspectable.

---

## 5. Design Principles

- Deterministic first, not predictive
- Minimal scope
- No premature abstraction
- No external dependencies unless required
- Data > speculation
- Validation against published results is mandatory

---

## 6. Validation Strategy

Each variant interpretation must be testable against:

- curated databases (ClinVar)
- experimental datasets (MaveDB)
- published literature

The system is considered correct only if:

- mappings are accurate
- interpretation logic is consistent
- outputs align with known evidence (where available)

---

## 7. Non-Goals

This system does NOT aim to:

- outperform existing biological prediction tools
- replace domain experts
- generate novel biological hypotheses
- act as a production clinical system

---

## 8. Milestones

### Phase 1 — Complete
- Rails app with multi-SQLite architecture
- Protein and Variant domain models
- TP53 fixture: full 393-residue sequence, 5 benchmark variants
- VariantInterpretationService: deterministic rule engine
- Cross-database lookups: UniProt, PDB
- PDB structures with residue coverage from RCSB API
- UI: inspection interface for proteins and variants
- 44 RSpec examples, 0 failures

### Phase 2 — Complete
- MaveDB and ClinVar databases scaffolded and populated
- 5 benchmark variants with Giacomelli 2018 + Kotler 2018 scores and ClinVar classifications
- EvidenceValidatorService: formal agreement measurement (agree/disagree/no_data)
- 100% agreement rate across all 5 benchmark variants and all 3 evidence sources
- Formal validation results documented in PAPER.md

### Phase 3 — Complete
- Quantitative confidence scoring: structural axis (0–60), evidence axis (0–40)
- Combined confidence level: :high/:moderate/:low with explicit thresholds
- Confidence and score fields surfaced in UI variant show card
- Specs for Mavedb::Score and Clinvar::Classification models
- Scoring specs: 12 new examples covering all scoring methods
- Suite: 67 examples, 0 failures, 2 pending (development-only path specs)

---

## 9. Future Directions (Optional)

Only after Phase 1 is stable:

- add ProteinFeature ingestion (UniProt)
- add StructureEntry ingestion (PDB)
- introduce EvidenceItem linking
- expand beyond TP53

No expansion before validation is working.

---

## 10. Guiding Constraint

Build the smallest system that can be:

- correct
- testable
- explainable

Avoid ambition until correctness is demonstrated.

---

## 11. Lessons Applied from Prior Work (StellarPop)

This project explicitly incorporates lessons learned from prior LLM-assisted scientific software development.

### 11.1 Role Separation

- Architect (human/LLM design role) defines:
  - architecture
  - domain logic
  - validation rules

- Coding agent (Codex) implements only:
  - code changes
  - no domain decisions
  - no architectural changes

### 11.2 No Delegation of Scientific Validation

- Correctness is determined only by:
  - curated datasets
  - experimental data
  - peer-reviewed literature

- Passing tests does NOT imply correctness

### 11.3 Silent Error Risk

- Outputs may be:
  - numerically valid
  - structurally correct
  - but scientifically wrong

- All outputs must be externally validated

### 11.4 Non-Monotonic Progress

- Fixing bugs may degrade results
- Improvements must be evaluated against a fixed validation baseline
- No assumption that “newer is better”

### 11.5 Data Integrity First

- Input data correctness is critical
- Identity mismatches (IDs, numbering, mapping) will invalidate results
- Data validation is part of the core system, not a preprocessing step

### 11.6 Minimal Scope Enforcement

- Over-expansion leads to loss of correctness
- System must remain small and testable
- No expansion before validation is working

### 11.7 Persistent Artifacts

- Results must be reproducible
- Intermediate outputs should be inspectable
- System state must survive session resets

---

## 12. Database Artifact Strategy

This project does not treat Rails seed files or local fixture files as permanent canonical data sources.

### 12.1 Main Application Database

- The primary SQLite database file is the canonical application-state artifact.
- It may be committed to GitHub for reproducibility and persistence.
- Curated working data for the application lives here.

### 12.2 No Permanent Seed-File Dependency

- Seed files and JSON fixture files may be used temporarily during development,
  but they are not the preferred long-term mechanism for maintaining project state.
- The database file itself is the durable state.

### 12.3 External Data as Separate SQLite Databases

- Large or externally sourced datasets should be stored in separate SQLite database files.
- These external databases should not be merged blindly into the primary application database.
- Each external SQLite file should preserve provenance and represent a distinct knowledge source.

Examples:
- uniprot.sqlite3 — canonical sequence, accession, name
- pdb.sqlite3 — experimental structures, residue coverage, chain mappings
- clinvar.sqlite3 — germline classifications, review status
- mavedb.sqlite3 — functional assay scores (Giacomelli 2018, Kotler 2018)

### 12.4 Architectural Consequence

The system should prefer:
- a small primary application database
- multiple data-centricr SQLite databases for external sources
- explicit import, mapping, or query logic between them

This avoids:
- one large monolithic database
- provenance confusion
- unnecessary duplication of raw external data inside the main app database

### 12.5 Guiding Principle

SQLite files are not just storage backends in this project.
They are persistent, versioned scientific artifacts.

## 13. Environment Model

This project is designed as a development-only scientific application.

It does not target a separate production deployment architecture, and it does not treat production-style environment separation as a design goal.

The system is built around:

- a primary development SQLite database
- multiple development data-centric SQLite databases
- direct, explicit querying of those databases

The focus is reproducible scientific development, inspection, and validation, not multi-environment deployment.
