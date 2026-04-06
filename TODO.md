# TODO

## Primary Goal

This project is a controlled experiment in LLM-assisted scientific software development.

**Central question:** Can a rule-based lookup system built primarily using LLMs produce
outputs that are consistent with peer-reviewed experimental evidence?

**What this system is:** A deterministic structural evidence lookup engine. Given a
missense variant residue position, it checks two things: (1) does the position fall in
a curated functional domain annotation, and (2) does it fall in an experimentally
resolved PDB structure? It then compares that binary output against MaveDB functional
scores and ClinVar classifications to measure agreement.

**What this system is not:** A classifier. An ML model. A variant effect predictor.
A clinical tool. A replacement for experimental data.

The LLM experiment is the primary research contribution.
TP53 missense interpretation is the test vehicle.

## Data Sources (SQLite Databases)
- 🟢 Main DB (`db/development.sqlite3`): proteins, variants, protein_features, structure_entries
- 🟢 UniProt DB (`db/uniprot.sqlite3`): canonical accession, name
- 🟢 PDB DB (`db/pdb.sqlite3`): structures with pdb_id, method, resolution, chain_id, start_pos, end_pos
- 🟢 MaveDB DB (`db/mavedb.sqlite3`): Giacomelli2018 + Kotler2018 scores (20 total, 10 variants x 2 sources)
- 🟢 ClinVar DB (`db/clinvar.sqlite3`): germline classifications, review status (7 benchmark classifications)

## Benchmark Variant Set (TP53 / P04637)
- 🟢 p.Arg175His — Giacomelli: 1.025 | Kotler: 1.791 | ClinVar: Pathogenic (expert panel)
- 🟢 p.Gly245Ser — Giacomelli: 0.772 | Kotler: 1.146 | ClinVar: Pathogenic (no assertion criteria)
- 🟢 p.Arg248Gln — Giacomelli: 0.812 | Kotler: 1.233 | ClinVar: Pathogenic (no assertion criteria)
- 🟢 p.Arg273His — Giacomelli: 1.221 | Kotler: 1.146 | ClinVar: Pathogenic (expert panel)
- 🟢 p.Tyr220Cys — Giacomelli: 1.102 | Kotler: 1.526 | ClinVar: Likely pathogenic (expert panel)
- 🟢 p.Val143Leu — Giacomelli: 0.328 | Kotler: 0.589 | ClinVar: Uncertain significance (no assertion criteria)
- 🟢 p.Arg181Asn — Giacomelli: 0.581 | Kotler: 0.395 | ClinVar: not found
- 🟢 p.Arg290Pro — Giacomelli: 0.249 | Kotler: 0.348 | ClinVar: Uncertain significance (single submitter)
- 🟢 p.Leu299Ser — Giacomelli: 0.357 | Kotler: 0.333 | ClinVar: not found
- 🟢 p.Met1Asn   — Giacomelli: 0.309 | Kotler: 0.248 | ClinVar: not found

## Blackboard Knowledge Sources
- 🟢 KS: DomainMapper — residue-position mapping to ProteinFeature intervals
- 🟢 KS: StructureMapper — residue-position mapping to StructureEntry intervals
- 🟢 KS: Interpretation — deterministic rule engine (VariantInterpretationService)
- 🟢 KS: EvidenceValidator — EvidenceValidatorService, agree/disagree/no_data vs MaveDB and ClinVar

## Core Architecture
- 🟢 Multi-SQLite architecture with model-layer database selection
- 🟢 ApplicationRecord, UniprotRecord, PdbRecord, MavedbRecord, ClinvarRecord base classes
- 🟢 Migration isolation: external DBs use dead migration paths (no bleed)
- 🟢 Rebuild rake tasks for all external databases

## Domain Models (Main DB)
- 🟢 Protein, Variant, ProteinFeature, StructureEntry — implemented with validations and indexes

## External Data Sources
- 🟢 Uniprot::Entry (db/uniprot.sqlite3)
- 🟢 Pdb::Structure (db/pdb.sqlite3) — 5 structures with full residue coverage
- 🟢 Mavedb::Score (db/mavedb.sqlite3) — 10 scores (Giacomelli2018 + Kotler2018)
- 🟢 Clinvar::Classification (db/clinvar.sqlite3) — 5 benchmark classifications

## Cross-Database Lookups
- 🟢 Protein#uniprot_entry — lookup into Uniprot::Entry by accession
- 🟢 Protein#pdb_structures — lookup into Pdb::Structure by uniprot_accession
- 🟢 Variant#mavedb_score — lookup into Mavedb::Score by hgvs_protein
- 🟢 Variant#clinvar_classification — lookup into Clinvar::Classification by hgvs_protein

## Data Ingestion Scripts (Standalone Ruby, not rake)
- 🟢 script/fetch_pdb_structures.rb — RCSB Data API + Sequence Coordinates API
- 🟢 script/fetch_mavedb_scores.rb — MaveDB CSV API (Giacomelli2018 + Kotler2018)
- 🟢 script/fetch_clinvar_classifications.rb — NCBI eutils esearch + esummary

## Variant Interpretation
- 🟢 VariantInterpretationService: deterministic rules, all four branch outcomes
- 🟢 Structural confidence scoring: domain axis (0–30), structure axis (0–20), resolution bonus (0–10)
- 🟢 Evidence confidence scoring: MaveDB axis (0–20), ClinVar axis (0–15/5)
- 🟢 Combined confidence level: :high (≥70) / :moderate (≥40) / :low (<40)

## UI (Inspection Interface)
- 🟢 Home page: research goal, benchmark results table, architecture summary
- 🟢 Persistent nav bar: mission statement on every page
- 🟢 Framing context on proteins index, protein show, variant show pages
- 🟢 Variant show: Evidence Agreement card promoted to top (primary finding first)
- 🟢 Variant show: plain-language finding statement (consistent/disagrees/insufficient)
- 🟢 Variant show: confidence badge with color coding (:high/:moderate/:low)
- 🟢 Variant show: agreement color coding (agree/disagree/no_data)
- 🟢 Protein show: UniProt entry and PDB structures cards
- 🟢 Variant show: MaveDB score and ClinVar classification cards

## Testing
- 🟢 90 examples, 0 failures, 2 pending (development-only DB path specs)
- 🟢 Specs for Variant#mavedb_score and Variant#clinvar_classification lookups
- 🟢 Specs for EvidenceValidatorService (agree, disagree, no_data cases)
- 🟢 Specs for quantitative confidence scoring (structural + evidence axes, combined_confidence_level)
- 🟢 Specs for Mavedb::Score and Clinvar::Classification models
- 🟢 Specs for 5 intermediate/uncertain classification variants (Phase 5), all four interpretation branches covered

## Validation Results
- 🟢 All 5 benchmark variants: agree across Giacomelli2018, Kotler2018, and ClinVar
- 🟢 Overall agreement rate: 100% (5/5 variants)
- 🟢 Formal results documented in PAPER.md
- 🟢 Phase 5: 5 intermediate/uncertain variants loaded; all four interpretation branches exercised for the first time
- 🟢 Intermediate variants produce no_data or disagree with ClinVar VUS -- expected and scientifically correct

## LLM Development Process Findings
- 🟢 23 failure modes documented in CLAUDE_ERRORS.md
- 🟢 Goal substitution identified as critical failure mode (Error 22)
- 🟢 Context window cost identified as structural economic constraint (Error 23)
- 🟢 System correctly framed as rule-based lookup engine, not classifier (clarified in docs and UI)
- 🟢 Error 25: before(:all) in RSpec commits data outside transactional fixtures -- test DB isolation failure documented
- 🟢 All findings documented in PAPER.md sections 6.2, 6.3, 6.4

## Next Steps
- 🟢 Extended benchmark set to variants with intermediate or uncertain functional classification -- Phase 5 complete
  -- this is the real test: hotspot variants are expected to agree, edge cases are not
- 🟡 Consider formal submission of PAPER.md as a short methods/research note

## Phase 4: Alzheimer's Protein Extension (Next Session)

Scientific question: Julian et al. 2026 (PNAS Nexus, doi:10.1093/pnasnexus/pgag034)
proposes amyloid-beta competes with tau for the same microtubule binding sites.
Can the same blackboard lookup engine provide deterministic structural context
for this competitive binding hypothesis?

**Planned work:**
- 🟢 Tau (UniProt P10636): add as second Protein, map microtubule-binding repeat region
  as ProteinFeature intervals, load PDB structures of tau bound to tubulin
- 🟢 APP/Amyloid-beta (UniProt P05067): add as third Protein, annotate amyloid-beta
  peptide region (APP residues ~672-713), map structural coverage
- 🟢 Compare tau microtubule-binding sequence region against amyloid-beta sequence
  for interval overlap — deterministic basis for competitive displacement reasoning
- 🟢 Identify appropriate experimental evidence sources for validation
  (different from MaveDB/ClinVar — need tau/amyloid binding assay data)
- 🟢 Extend EvidenceValidator KS for new evidence source type if needed

**Session entry point:**
Open project, read README.md, TODO.md, PAPER.md Appendix C, and Julian et al. 2026.
First task: fetch UniProt P10636 and P05067 feature annotations before any code.

**Scope constraint:**
No molecular dynamics. No binding simulation. Same deterministic lookup engine,
new proteins, new domain/structure intervals, new validation question.

## Future Extensions (Post-Phase 4)
- 🟡 Empirical calibration of confidence score thresholds against held-out validation set
- 🟡 Expanded protein feature coverage from full UniProt annotation set
- 🟡 Expanded PDB structure coverage beyond 5 curated structures
