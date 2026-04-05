# PAPER.md — Working Draft

## Deterministic Interpretation of TP53 Missense Variants Using a Blackboard Knowledge Source Architecture

**Status:** Working draft. Not yet submitted. Updated as system develops.

---

## Abstract

We describe a small, deterministic software system for interpreting missense variants in the TP53 tumor suppressor protein. The system follows a blackboard architecture in which independent Knowledge Sources (KSs) contribute structural and functional annotations from curated external databases. Variant interpretation is rule-based and fully inspectable, with no probabilistic or machine learning inference. We evaluate the system against five benchmark TP53 missense variants using functional scores from MaveDB (Giacomelli et al. 2018) and clinical classifications from ClinVar. The goal is not to outperform existing prediction tools, but to demonstrate that a minimal, transparent, engineering-first system can produce scientifically grounded outputs that agree with peer-reviewed experimental evidence.

---

## 1. Introduction

TP53 is the most frequently mutated gene in human cancer. Missense variants in TP53 vary widely in their functional consequences: some abolish DNA-binding activity, others have intermediate effects, and some are functionally neutral. Existing computational tools for variant effect prediction (e.g., SIFT, PolyPhen, AlphaMissense) use probabilistic and ML-based approaches that are opaque and difficult to validate step-by-step.

This work takes a different approach. We build the smallest deterministic system that can:

1. Map a variant to its structural and functional context using curated data
2. Apply explicit rules to generate an interpretation
3. Compare that interpretation against experimental evidence

The system is implemented as a Rails application with multiple SQLite databases, each representing a distinct scientific knowledge source. The architecture follows the blackboard model, in which a central workspace is updated by independent KSs that each contribute one layer of annotation.

---

## 2. System Architecture

### 2.1 Blackboard Design

The system uses a simplified blackboard architecture with four KSs:

**DomainMapper KS** — maps variant residue position against curated protein feature intervals from UniProt. Detects hits in annotated functional domains and regions.

**StructureMapper KS** — maps variant residue position against PDB structure coverage intervals. Detects hits in experimentally resolved structural regions.

**Interpretation KS** — applies deterministic rules to domain and structure hit combinations. Produces a preliminary mechanism classification and confidence level.

**EvidenceValidator KS** (in progress) — compares interpretation output against MaveDB functional scores and ClinVar clinical classifications.

### 2.2 Data Sources

Each knowledge source is stored in a separate SQLite database file, preserving provenance:

| Database | Source | Content |
|---|---|---|
| db/development.sqlite3 | Application | Proteins, variants, features, structure entries |
| db/uniprot.sqlite3 | UniProt | Canonical accession, sequence, name |
| db/pdb.sqlite3 | RCSB PDB | Structures, residue coverage, chain, resolution |
| db/mavedb.sqlite3 | MaveDB | Functional assay scores (Giacomelli 2018) |
| db/clinvar.sqlite3 | ClinVar | Germline classifications, review status |

### 2.3 Interpretation Rules

The Interpretation KS applies the following deterministic rules:

| Domain Hit | Structure Hit | Mechanism | Confidence |
|---|---|---|---|
| Yes | Yes | Structured functional region | Medium |
| Yes | No | Annotated functional region | Low |
| No | Yes | Structured region | Low |
| No | No | Unannotated region | Low |

---

## 3. Target Protein and Variant Set

**Protein:** TP53 (UniProt P04637), human tumor suppressor, 393 residues.

**Benchmark variants** (five canonical hotspot missense variants):

| Variant | Position | Ref | Alt |
|---|---|---|---|
| p.Arg175His | 175 | R | H |
| p.Gly245Ser | 245 | G | S |
| p.Arg248Gln | 248 | R | Q |
| p.Arg273His | 273 | R | H |
| p.Tyr220Cys | 220 | Y | C |

All five variants fall within the DNA-binding domain (residues 95-289, UniProt annotation).

---

## 4. External Evidence

### 4.1 MaveDB Functional Scores

Two score sets from MaveDB are integrated:

**Giacomelli et al. 2018** (urn:mavedb:00000068-0-1) — nutlin-3 paired with etoposide screen:

| Variant | Score |
|---|---|
| p.Arg175His | 1.025 |
| p.Gly245Ser | 0.772 |
| p.Arg248Gln | 0.812 |
| p.Arg273His | 1.221 |
| p.Tyr220Cys | 1.102 |

**Kotler et al. 2018** (urn:mavedb:00000068-a-1) — nutlin-3 paired with wildtype screen:

| Variant | Score |
|---|---|
| p.Arg175His | 1.791 |
| p.Gly245Ser | 1.146 |
| p.Arg248Gln | 1.233 |
| p.Arg273His | 1.146 |
| p.Tyr220Cys | 1.526 |

All ten scores are above 0.7, consistent with significant functional impairment across both experimental conditions.

### 4.2 ClinVar Clinical Classifications

| Variant | ClinVar Classification | Review Status |
|---|---|---|
| p.Arg175His | Pathogenic | Reviewed by expert panel |
| p.Gly245Ser | Pathogenic | No assertion criteria provided |
| p.Arg248Gln | Pathogenic | No assertion criteria provided |
| p.Arg273His | Pathogenic | Reviewed by expert panel |
| p.Tyr220Cys | Likely pathogenic | Reviewed by expert panel |

### 4.3 PDB Structural Coverage

Five curated experimental structures cover the benchmark variant positions:

| PDB | Method | Resolution (Å) | Coverage |
|---|---|---|---|
| 1TUP | X-ray diffraction | 2.20 | 94..312 |
| 2OCJ | X-ray diffraction | 2.05 | 94..312 |
| 3KZ8 | X-ray diffraction | 1.91 | 94..293 |
| 2AC0 | X-ray diffraction | 1.80 | 94..293 |
| 1AIE | X-ray diffraction | 1.50 | 326..356 |

All five benchmark variants (positions 175, 220, 245, 248, 273) fall within the coverage range of structures 1TUP, 2OCJ, 3KZ8, and 2AC0.

---

## 5. Preliminary Results

### 5.1 System Output (Current)

All five benchmark variants are interpreted by the system as hits in both the DNA-binding domain (DomainMapper KS) and experimental structures (StructureMapper KS), producing the classification: **structured functional region**, confidence: **medium**.

This is consistent with their known biology: all five are hotspot variants in the core DNA-binding domain, extensively covered by experimental structures.

### 5.2 Agreement with External Evidence

The EvidenceValidatorService (EvidenceValidator KS) is implemented and compares system output against MaveDB and ClinVar per variant. Agreement logic:

- MaveDB: system is considered consistent if a domain or structure hit is detected and the MaveDB score >= 0.5 (functionally impaired threshold)
- ClinVar: system is considered consistent if a domain or structure hit is detected and ClinVar classification is Pathogenic or Likely pathogenic

All five benchmark variants produce domain hits (DNA-binding domain, residues 95-289) and structure hits (covered by 1TUP, 2OCJ, 3KZ8, 2AC0). All five have MaveDB scores >= 0.7 and ClinVar classifications of Pathogenic or Likely pathogenic.

Formal per-variant agreement results pending wiring of EvidenceValidatorService into the variant show page and controller. Expected result: agree across all five variants for both MaveDB and ClinVar comparators.

---

## 6. Discussion

### 6.1 Scope

This system is intentionally minimal. It does not attempt to predict variant pathogenicity from sequence alone, model protein folding, or replicate the full functionality of existing tools such as AlphaMissense or SIFT. Its purpose is to demonstrate that a transparent, step-by-step deterministic pipeline can produce outputs that are grounded in curated experimental data and verifiable at every stage.

### 6.2 Limitations

- The system currently uses a small curated set of protein features and structures. Expansion to the full UniProt feature set and all available PDB structures is planned.
- Confidence scoring is binary (medium/low) and does not yet reflect quantitative evidence strength.
- ClinVar review status varies across variants, limiting the weight that can be placed on some classifications.
- The Kotler 2018 score set has not yet been integrated as a second MaveDB comparator.

### 6.3 LLM-Assisted Development

This system was developed using a two-stage human-AI workflow: Claude (Anthropic) served as architect and prompt author; Codex CLI served as code implementer. Documented failure modes and corrective rules are maintained in CLAUDE_ERRORS.md. This workflow is itself part of the research: the system is a test case for disciplined, validation-first LLM-assisted scientific software development.

---

## 7. References

- Giacomelli AO, et al. (2018). MaveDB TP53 score set. urn:mavedb:00000068-0-1.
- Kotler E, et al. (2018). A systematic p53 mutation library links differential functional impact to cancer mutation pattern and evolutionary conservation. Molecular Cell. PMC6276857.
- Landrum MJ, et al. (2018). ClinVar: improving access to variant interpretations and supporting evidence. Nucleic Acids Research, 46(D1), D1062-D1067.
- UniProt. https://www.uniprot.org/ (P04637)
- RCSB PDB. https://www.rcsb.org/
- MaveDB. https://mavedb.org/

---

## Appendix A: System Setup

See README.md for full setup instructions.

Key data fetch commands:
```bash
ruby script/fetch_pdb_structures.rb
ruby script/fetch_mavedb_scores.rb
ruby script/fetch_clinvar_classifications.rb
```

## Appendix B: Open Items

- EvidenceValidator KS implementation
- Kotler 2018 score set integration
- Formal agreement metrics
- Expanded protein feature and structure coverage
