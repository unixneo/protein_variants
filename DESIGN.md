# protein_variants — Design

## 1. Purpose

This project builds a small, deterministic system for interpreting protein missense variants using curated biological data and simple structural/annotation rules.

The goal is not to "predict biology" broadly, but to:

- normalize protein and variant data
- map variants into structural and functional context
- generate interpretable, testable outputs
- validate those outputs against peer-reviewed and curated sources

This follows the same validation-first approach used in StellarPop.

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

### L3 — Verification (future)
- compare results to:
  - ClinVar
  - MaveDB
  - peer-reviewed literature

No probabilistic or ML inference is used in the initial system.

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

## 8. Initial Milestone

Phase 1:

- Rails app with SQLite
- Protein and Variant models
- Local fixture data (TP53)
- Deterministic interpretation service
- Basic UI for inspection

Success criteria:

- system runs end-to-end locally
- variant → interpretation is reproducible
- outputs are explainable

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
