# PAPER.md — Working Draft

## Deterministic Interpretation of TP53 Missense Variants Using a Blackboard Knowledge Source Architecture

**Status:** Working draft. Not yet submitted. Updated as system develops.

---

## Abstract

This paper describes a controlled experiment in LLM-assisted scientific software development. The central question is: can a deterministic system built primarily using large language models produce scientifically valid results when evaluated against peer-reviewed experimental data?

The experimental vehicle is a small, deterministic software system for interpreting missense variants in the TP53 tumor suppressor protein. The system follows a blackboard architecture in which independent Knowledge Sources (KSs) contribute structural and functional annotations from curated external databases. Variant interpretation is rule-based and fully inspectable, with no probabilistic or machine learning inference. We evaluate the system against five benchmark TP53 missense variants using functional scores from two MaveDB score sets (Giacomelli et al. 2018, Kotler et al. 2018) and clinical classifications from ClinVar. All five variants are correctly classified as residing in a structured functional region, with 100% agreement across both MaveDB score sets and ClinVar.

The system was built using a two-stage workflow: Claude (Anthropic) served as architect, scientist, and prompt author; Codex CLI served as code implementer. Documented failure modes and corrective operating rules are maintained as a project artifact (CLAUDE_ERRORS.md). The development process itself is part of the research record.

---

## 1. Introduction

### 1.1 The Experiment

This project addresses a direct question about LLM-assisted scientific software development: can a system built primarily using LLMs produce outputs that are scientifically valid when measured against peer-reviewed experimental data?

The answer is not obvious. LLMs are known to drift from stated objectives, hallucinate solutions, and lose constraint tracking across iterative sessions. If these failure modes are allowed to propagate unchecked into a scientific software system, the outputs may appear technically correct while being scientifically wrong. The discipline required to prevent this -- validation-first development, explicit knowledge source decomposition, data-before-code engineering order -- is difficult to maintain under LLM-assisted development pressure.

This paper documents both the system and the process used to build it.

### 1.2 Scientific Test Domain

TP53 is the most frequently mutated gene in human cancer. Missense variants in TP53 vary widely in their functional consequences: some abolish DNA-binding activity, others have intermediate effects, and some are functionally neutral. Large-scale experimental datasets (MaveDB) and curated clinical classifications (ClinVar) provide ground truth against which a computational system's outputs can be evaluated.

This makes TP53 an ideal test domain: the science is well-characterized, the validation data is publicly available, and the correct answers for canonical hotspot variants are unambiguous.

### 1.3 System Approach

We build the smallest deterministic system that can:

1. Map a variant to its structural and functional context using curated data
2. Apply explicit rules to generate an interpretation
3. Compare that interpretation against peer-reviewed experimental evidence

The system uses no probabilistic or ML-based variant effect prediction. Every step is inspectable and traceable to its data source.

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

### 6.1 The Experiment Result

The central question was: can an LLM-built deterministic system produce scientifically valid results when evaluated against peer-reviewed experimental data?

For this test case -- five canonical TP53 hotspot variants evaluated against two MaveDB score sets and ClinVar -- the answer is yes. The system produces 100% agreement across all comparators. The result is not surprising for these well-characterized variants, but it is meaningful: the LLM-assisted development process, when properly disciplined, did not introduce scientific errors into the pipeline.

### 6.2 Development Process Observations

The system was built using a two-stage workflow: Claude as architect and prompt author, Codex as implementer. Twenty-one documented failure modes were identified and recorded during development (CLAUDE_ERRORS.md). Key patterns:

- LLMs drift from stated architecture when not explicitly constrained at each step
- API attribute names and field paths must be verified with real data before any code is written -- LLMs will confidently specify wrong paths
- Network environment assumptions do not transfer between the LLM's execution context and the user's local environment
- Incremental edits to corrupted files compound the corruption -- full rewrites are safer
- The "stop on error" instruction pattern is counterproductive with agentic coding tools

The discipline that prevented scientific errors was the same discipline documented in CLAUDE_ERRORS.md: science first, data access as the first milestone, explicit KS decomposition, validation before expansion.

### 6.3 Scope and Limitations

- The benchmark variant set is limited to five well-characterized hotspots. Extension to variants with intermediate or uncertain functional classification will provide a more rigorous test.
- Confidence scoring is currently binary (medium/low). Quantitative evidence-weighted scoring is a planned next step.
- ClinVar review status varies across variants (expert panel vs. no assertion criteria), which is not yet used to weight agreement confidence.
- The system uses a small curated set of protein features and structures. Expansion to the full UniProt annotation set and all available PDB structures is planned.

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
