# PAPER.md — Working Draft

## Deterministic Interpretation of TP53 Missense Variants Using a Blackboard Knowledge Source Architecture

**Status:** Working draft. Not yet submitted. Updated as system develops.

---

## Abstract

We describe a small, deterministic software system for interpreting missense variants in the TP53 tumor suppressor protein. The system follows a blackboard architecture in which independent Knowledge Sources (KSs) contribute structural and functional annotations from curated external databases. Variant interpretation is rule-based and fully inspectable, with no probabilistic or machine learning inference. We evaluate the system against five benchmark TP53 missense variants using functional scores from two MaveDB score sets (Giacomelli et al. 2018, Kotler et al. 2018) and clinical classifications from ClinVar. All five variants are correctly classified as residing in a structured functional region, with 100% agreement across both MaveDB score sets and ClinVar. The goal is not to outperform existing prediction tools, but to demonstrate that a minimal, transparent, engineering-first system can produce scientifically grounded, fully inspectable outputs that agree with peer-reviewed experimental evidence.

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

**EvidenceValidator KS** — compares interpretation output against MaveDB functional scores (Giacomelli 2018, Kotler 2018) and ClinVar clinical classifications. Implemented and wired into the inspection UI.

### 2.2 Data Sources

Each knowledge source is stored in a separate SQLite database file, preserving provenance:

| Database | Source | Content |
|---|---|---|
| db/development.sqlite3 | Application | Proteins, variants, features, structure entries |
| db/uniprot.sqlite3 | UniProt | Canonical accession, sequence, name |
| db/pdb.sqlite3 | RCSB PDB | Structures, residue coverage, chain, resolution |
| db/mavedb.sqlite3 | MaveDB | Functional assay scores (Giacomelli 2018, Kotler 2018) |
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

## 5. Results

### 5.1 System Output

All five benchmark variants fall within the TP53 DNA-binding domain (residues 95-289, UniProt annotation) and within the residue coverage of experimental structures 1TUP, 2OCJ, 3KZ8, and 2AC0 (coverage 94-312 and 94-293). The system produces a domain hit and a structure hit for all five variants, yielding the following output from the Interpretation KS:

| Variant | Domain Hit | Structure Hit | Mechanism | Confidence |
|---|---|---|---|---|
| p.Arg175His | Yes | Yes | Structured functional region | Medium |
| p.Gly245Ser | Yes | Yes | Structured functional region | Medium |
| p.Arg248Gln | Yes | Yes | Structured functional region | Medium |
| p.Arg273His | Yes | Yes | Structured functional region | Medium |
| p.Tyr220Cys | Yes | Yes | Structured functional region | Medium |

### 5.2 Agreement with External Evidence

The EvidenceValidator KS compares system output against MaveDB and ClinVar using two rules:

- MaveDB: agree if system flagged (domain or structure hit) and score >= 0.5
- ClinVar: agree if system flagged and classification is Pathogenic or Likely pathogenic

**Agreement results across both MaveDB score sets and ClinVar:**

| Variant | Giacomelli 2018 | Kotler 2018 | ClinVar | Overall |
|---|---|---|---|---|
| p.Arg175His | agree (1.025) | agree (1.791) | agree (Pathogenic) | agree |
| p.Gly245Ser | agree (0.772) | agree (1.146) | agree (Pathogenic) | agree |
| p.Arg248Gln | agree (0.812) | agree (1.233) | agree (Pathogenic) | agree |
| p.Arg273His | agree (1.221) | agree (1.146) | agree (Pathogenic) | agree |
| p.Tyr220Cys | agree (1.102) | agree (1.526) | agree (Likely pathogenic) | agree |

**5/5 variants agree across both MaveDB score sets and ClinVar. Overall agreement rate: 100%.**

### 5.3 Interpretation

The system correctly identifies all five canonical TP53 hotspot variants as residing in a structured functional region, consistent with their known biology. This validates that the deterministic pipeline is correctly wired end-to-end: sequence position lookup, domain annotation, structural coverage mapping, rule application, and evidence comparison all produce consistent and scientifically correct outputs.

Agreement is expected for these well-characterized hotspot variants. The value of the system is not the result itself but the full inspectability of every step that produced it.

---

## 6. Discussion

### 6.1 Scope

This system is intentionally minimal. It does not attempt to predict variant pathogenicity from sequence alone, model protein folding, or replicate the full functionality of existing tools such as AlphaMissense or SIFT. Its purpose is to demonstrate that a transparent, step-by-step deterministic pipeline can produce outputs that are grounded in curated experimental data and verifiable at every stage.

### 6.2 Limitations

- The system uses a small curated set of protein features and structures. Expansion to the full UniProt feature set and all available PDB structures is planned.
- Confidence scoring is currently binary (medium/low). Quantitative evidence-weighted scoring is a planned next step.
- ClinVar review status varies across variants (expert panel vs. no assertion criteria), which is not yet used to weight agreement confidence.
- The benchmark variant set is deliberately limited to five well-characterized hotspots. Extension to variants with intermediate or uncertain functional effects will provide a more rigorous test of the system.

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

## Appendix B: Remaining Work

- Quantitative evidence-weighted confidence scoring (low/medium/high)
- Expanded protein feature coverage from full UniProt annotation set
- Extension to variants with uncertain or intermediate functional classification
- Formal submission as a short methods paper or research note
