# PAPER.md — Working Draft

## Deterministic Interpretation of TP53 Missense Variants Using a Blackboard Knowledge Source Architecture

**Status:** Working draft. Not yet submitted. Updated as system develops.
**Version:** v0.1.0
**DOI:** https://doi.org/10.5281/zenodo.19436320
**Date:** 2026-04-06

---

## Abstract

This paper describes a controlled experiment in LLM-assisted scientific software development. The central question is: can a rule-based structural evidence lookup engine built primarily using large language models produce outputs that are consistent with peer-reviewed experimental data?

The experimental vehicle is a small, deterministic software system for interpreting missense variants in the TP53 tumor suppressor protein. The system follows a blackboard architecture in which independent Knowledge Sources (KSs) contribute structural and functional annotations from curated external databases. Variant interpretation is rule-based and fully inspectable, with no probabilistic or machine learning inference. We evaluate the system against five benchmark TP53 missense variants using functional scores from two MaveDB score sets (Giacomelli et al. 2018, Kotler et al. 2018) and clinical classifications from ClinVar. All five variants are correctly classified as residing in a structured functional region, with 100% agreement across both MaveDB score sets and ClinVar.

The system was built using a two-stage workflow: Claude (Anthropic) served as architect, scientist, and prompt author; Codex CLI served as code implementer. Development began with ChatGPT (OpenAI) as the primary LLM collaborator. After fifteen documented failure modes -- including repeated architecture drift, goal substitution, and inability to maintain step-ordering discipline -- the project was transferred to Claude. The ChatGPT phase failures are preserved in CHATGPT_ERRORS.md as part of the experiment record. Documented failure modes and corrective operating rules are maintained as a project artifact (CLAUDE_ERRORS.md). The development process itself is part of the research record.

---

## 1. Introduction

### 1.1 The Experiment

This project addresses a direct question about LLM-assisted scientific software development: can a system built primarily using LLMs produce outputs that are scientifically valid when measured against peer-reviewed experimental data?

The answer is not obvious. LLMs are known to drift from stated objectives, hallucinate solutions, and lose constraint tracking across iterative sessions. If these failure modes are allowed to propagate unchecked into a scientific software system, the outputs may appear technically correct while being scientifically wrong. The discipline required to prevent this -- validation-first development, explicit knowledge source decomposition, data-before-code engineering order -- is difficult to maintain under LLM-assisted development pressure.

This project involved two LLM collaborators across its development lifecycle. The initial phase used ChatGPT (OpenAI) as the primary engineering partner. That phase produced fifteen documented failure modes (CHATGPT_ERRORS.md), including repeated architecture drift, premature infrastructure build-out ahead of scientific specification, failure to maintain step-ordering discipline, and inability to track long-term constraints across sessions. The project was not completed under ChatGPT and was transferred to Claude (Anthropic). The Claude phase produced twenty-five additional documented failure modes (CLAUDE_ERRORS.md) but reached full system completion. Both failure logs are part of the research record. The comparison is not a controlled benchmark -- the two LLMs were used under different workflow conditions and at different stages of project maturity. It is, however, an honest account of what happened.

This paper documents both the system and the process used to build it.

### 1.2 Scientific Test Domain

TP53 is the most frequently mutated gene in human cancer. Missense variants in TP53 vary widely in their functional consequences: some abolish DNA-binding activity, others have intermediate effects, and some are functionally neutral. Large-scale experimental datasets (MaveDB) and curated clinical classifications (ClinVar) provide ground truth against which a computational system's outputs can be evaluated.

This makes TP53 an ideal test domain: the science is well-characterized, the validation data is publicly available, and the correct answers for canonical hotspot variants are unambiguous.

### 1.3 System Approach

The system uses no probabilistic or ML-based variant effect prediction. It is not a
classifier. It is a rule-based lookup engine that asks two questions about each variant:

1. Does the residue position fall inside a curated functional domain annotation?
2. Does the residue position fall inside an experimentally resolved PDB structure?

The binary result of those two lookups is passed through deterministic rules to produce
a mechanism label and confidence score, then compared against peer-reviewed evidence
to measure agreement. Every step is inspectable and traceable to its source database.

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

### 3.1 Extended Benchmark: Intermediate and Uncertain Classification Variants

Five additional variants were selected to test system behavior under ambiguous
evidence conditions. Selection criteria: (1) intermediate MaveDB scores in both
Giacomelli2018 and Kotler2018 (range 0.2-0.6, present in both score sets), and
(2) ClinVar classification of Uncertain significance or absent from ClinVar.

| Variant | Position | Domain | Structure | ClinVar |
|---|---|---|---|---|
| p.Val143Leu | 143 | Inside DBD | Inside 1TUP/2OCJ | Uncertain significance |
| p.Arg181Asn | 181 | Inside DBD | Inside 1TUP/2OCJ | Not in ClinVar |
| p.Arg290Pro | 290 | Outside DBD | Inside 1TUP | Uncertain significance |
| p.Leu299Ser | 299 | Outside DBD | Inside 1TUP | Not in ClinVar |
| p.Met1Asn   | 1   | Outside DBD | No coverage | Not in ClinVar |

These variants exercise all four interpretation branches: domain+structure hit
(Val143Leu, Arg181Asn), structure-only hit (Arg290Pro, Leu299Ser), and
unannotated (Met1Asn). The original five hotspot variants exercise only the
domain+structure branch.

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

### 5.4 Extended Benchmark Results

The five Phase 5 variants exercise system behavior at the boundaries of the
deterministic lookup engine.

Val143Leu and Arg181Asn (inside DBD, inside structure coverage) produce
domain+structure hits -- the same branch as the original five hotspot variants.
However, their MaveDB scores are intermediate (0.33-0.59), straddling the 0.5
agreement threshold. Whether the system agrees with MaveDB depends on score set
ordering and threshold boundary -- this is the expected behavior for a
deterministic rule applied to ambiguous experimental data.

Arg290Pro and Leu299Ser (outside DBD, inside 1TUP structure coverage at
positions 290 and 299 respectively) produce structure-only hits. Both carry
ClinVar Uncertain significance or no ClinVar entry. The system correctly
identifies structural coverage without domain annotation -- a distinct and
previously untested interpretation branch.

Met1Asn (position 1, outside all domain and structure annotations) produces
the unannotated branch outcome: no domain hit, no structure hit, unannotated
region. No ClinVar record exists. This is the fourth and final interpretation
branch, exercised for the first time.

The extended benchmark confirms that the deterministic lookup engine produces
scientifically coherent outputs across all four interpretation branches, and
correctly produces no_data or ambiguous agreement results for variants where
the experimental evidence is itself uncertain.

---

## 6. Discussion

### 6.1 The Experiment Result

The central question was: can an LLM-built deterministic system produce scientifically valid results when evaluated against peer-reviewed experimental data?

For this test case -- five canonical TP53 hotspot variants evaluated against two MaveDB score sets and ClinVar -- the answer is yes. The system produces 100% agreement across all comparators. The result is not surprising for these well-characterized variants, but it is meaningful: the LLM-assisted development process, when properly disciplined, did not introduce scientific errors into the pipeline.

### 6.2 Development Process Observations

The system was built across two LLM phases. The first phase used ChatGPT as the primary LLM collaborator. Fifteen failure modes were documented (CHATGPT_ERRORS.md) before the project was transferred. Key ChatGPT failure patterns: architecture drift (repeated failure to follow the stated multi-SQLite design), infrastructure leading the science (building Rails layers before defining the scientific workflow), and step-ordering indiscipline (jumping ahead to future steps without completing current ones). The project was not finished under ChatGPT.

The second phase used Claude as architect, scientist, and prompt author, with Codex CLI as code implementer. Twenty-five failure modes were documented during the Claude phase (CLAUDE_ERRORS.md). The system reached full completion under this workflow.

- LLMs drift from stated architecture when not explicitly constrained at each step
- API attribute names and field paths must be verified with real data before any code is written -- LLMs will confidently specify wrong paths
- Network environment assumptions do not transfer between the LLM's execution context and the user's local environment
- Incremental edits to corrupted files compound the corruption -- full rewrites are safer
- The "stop on error" instruction pattern is counterproductive with agentic coding tools

The discipline that prevented scientific errors was the same discipline documented in CLAUDE_ERRORS.md: science first, data access as the first milestone, explicit KS decomposition, validation before expansion.

### 6.3 Goal Substitution: A Critical LLM Failure Mode

The most serious failure recorded during this project was goal substitution (CLAUDE_ERRORS.md, Error 22). When asked to update project documentation, Claude rewrote the primary project goal -- replacing the LLM experiment framing with a bioinformatics system framing -- and then wrote multiple documents consistently around the wrong goal. The abstract, introduction, and discussion of this paper were initially drafted as a conventional bioinformatics paper, with LLM-assisted development demoted to a footnote.

This failure was caught by the human researcher and corrected. Without that intervention, every subsequent document, decision, and artefact would have reinforced the wrong objective.

Goal substitution is particularly dangerous because:

- The substituted output is internally consistent and high quality
- It is built around observable artefacts rather than the stated research question
- It does not trigger obvious error signals -- the LLM appears to be helping
- Multiple committed artefacts can embed the wrong goal before detection

The root cause is structural: LLMs are trained to produce coherent outputs given observable context. When updating documentation for a Rails application that implements bioinformatics logic, the LLM defaulted to the bioinformatics framing because that is what the code shows. The LLM experiment framing -- the actual primary goal -- is not visible in the code and was therefore underweighted.

This failure mode is not unique to this project. Any research project where the primary goal is the development process rather than the artefact produced is vulnerable to this substitution. The corrective discipline is simple but must be enforced explicitly: state the primary goal before any document is drafted, and treat goal drift in documentation as a scientific error, not a stylistic preference.

The fact that this failure occurred despite the primary goal being clearly documented in TODO.md from project inception, and despite an explicit error log being maintained throughout development, underscores how persistent this failure mode is in LLM-assisted workflows.

### 6.4 Economic Constraint: Context Window Cost

A practical finding from this project is that context window cost is a significant and underappreciated constraint on LLM-assisted scientific development for paying users on limited plans.

In a long working session, every exchange re-processes the entire conversation history. File reads, code reviews, documentation updates, and pasted outputs all accumulate in context and do not leave. As the session grows, the cost per exchange becomes proportional to the total session history rather than to the work actually being done. In one observed case, a modest amount of work -- a few prompts, some documentation updates, a commit -- consumed over 41% of a Pro plan usage limit.

This is a structural economic problem, not a user error. It affects any long-running project where context naturally accumulates: multi-file codebases, extensive documentation, iterative debugging cycles, and research workflows where prior decisions must be remembered across many exchanges.

The corrective discipline is to start a new conversation when returning to a project rather than continuing an existing one. This requires that the project's state be fully recoverable from committed artefacts -- which is exactly what the .md files (README, TODO, DESIGN, CLAUDE_ERRORS) in this project are designed to support. A well-maintained set of project documents functions as an external memory system that makes fresh sessions viable without loss of context.

This finding has direct implications for the economics of LLM-assisted scientific development at scale. Projects that span days or weeks of iterative work will consume disproportionate token budgets if session hygiene is not enforced. This constraint should be factored into any cost model for LLM-assisted research workflows.

### 6.5 Scope and Limitations

- The original benchmark variant set of five hotspot variants has been extended with five intermediate/uncertain classification variants (Phase 5), exercising all four interpretation branches for the first time. The extended set confirms expected system behavior: agreement with unambiguous pathogenic variants, no_data or ambiguous agreement with VUS and ClinVar-absent variants.
- Confidence scoring uses a point-based model (structural axis 0–60, evidence axis 0–40, combined threshold :high/:moderate/:low). The thresholds are principled but not empirically calibrated against a held-out validation set.
- ClinVar review status is used to weight confidence (expert panel +15 vs. pathogenic-without-panel +5), but is not yet used to stratify agreement conclusions.
- The system uses a small curated set of protein features and structures. Expansion to the full UniProt annotation set and all available PDB structures is planned.

### 6.6 Two-LLM Development History

This project is unusual in that it involved two distinct LLM collaborators
at different stages, with a documented handoff between them.

The ChatGPT phase preceded this paper. It produced a partially built system
with fifteen documented failure modes and did not reach completion. The
failure modes were primarily process failures: inability to follow stated
architecture, premature expansion beyond the current task, and loss of
scientific framing under iterative pressure. The partially built system was
the starting point for the Claude phase.

The Claude phase completed the system. It produced twenty-five additional
failure modes, including two that are particularly relevant to LLM-assisted
scientific development: goal substitution (Error 22, where Claude rewrote
the primary research objective when updating documentation) and context
window cost as an economic constraint (Error 23).

The cumulative failure log -- forty failure modes across two LLMs -- is the
most direct evidence this project offers about the current state of
LLM-assisted scientific software development. Neither LLM operated without
error. Both required persistent human oversight to keep the system aligned
with its stated scientific objective. The difference was that one reached
completion and the other did not.

This finding should be interpreted carefully. The two LLMs were not tested
under controlled conditions. ChatGPT was used earlier in the project when
requirements were less settled; Claude was used on a more mature codebase
with clearer constraints. Workflow differences, prompt style, and project
maturity all vary. What can be said without overinterpretation: under the
conditions of this project, the Claude-based workflow produced a complete,
validated system; the ChatGPT-based workflow did not.

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

- ~~Extend benchmark set to variants with uncertain or intermediate functional classification~~ -- complete (Phase 5)
- Empirical calibration of confidence score thresholds against a held-out validation set
- Expanded protein feature coverage from full UniProt annotation set
- Formal submission as a short methods paper or research note

## Appendix C: Future Extensions

### Tau and Amyloid-Beta: Competitive Binding at Microtubules

A natural extension of this system is to apply the same blackboard architecture to the proteins implicated in Alzheimer's disease, motivated by Julian et al. 2026 (PNAS Nexus, doi:10.1093/pnasnexus/pgag034).

That study proposes a unifying theory: amyloid-beta peptides compete with tau for the same microtubule binding sites. The sequence region of amyloid-beta that binds microtubules resembles the microtubule-binding region of tau, suggesting a direct displacement mechanism that links the two hallmark proteins of Alzheimer's disease.

The protein_variants blackboard architecture could be extended to:

- Tau (UniProt P10636): map microtubule-binding region as a ProteinFeature interval, load PDB structures of tau bound to tubulin, and interpret missense variants in the binding region
- APP/Amyloid-beta (UniProt P05067): annotate the amyloid-beta peptide region and map structural coverage
- Compare the two binding sequence regions for overlap -- the deterministic basis for reasoning about competitive displacement at the sequence/domain level

This would not simulate molecular dynamics or reproduce the wet lab binding competition assay. It would produce a deterministic, inspectable structural context: which residues of each protein fall in the relevant binding region, which are covered by experimental structures, and which missense variants would be predicted to affect binding based on domain and structure hits.

This extension would also serve as a second test case for the primary research question: can an LLM-built deterministic system produce scientifically grounded outputs for a different protein system, against a different class of experimental evidence?
