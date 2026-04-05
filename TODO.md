# TODO

## Primary Goal
This project is a controlled experiment in LLM-assisted scientific software development:
**Can a deterministic system built primarily using LLMs produce scientifically valid results when compared to peer-reviewed experimental data?**
The LLM experiment is the primary goal. TP53 missense interpretation is the test vehicle.

## Data Sources (SQLite Databases)
- 🟢 Main DB (`db/development.sqlite3`): proteins, variants, protein_features, structure_entries
- 🟢 UniProt DB (`db/uniprot.sqlite3`): canonical accession, name
- 🟢 PDB DB (`db/pdb.sqlite3`): structures with pdb_id, method, resolution, chain_id, start_pos, end_pos
- 🟢 MaveDB DB (`db/mavedb.sqlite3`): Giacomelli2018 + Kotler2018 scores (10 total, 5 variants x 2 sources)
- 🟢 ClinVar DB (`db/clinvar.sqlite3`): germline classifications, review status (5 variants)

## Benchmark Variant Set
- 🟢 p.Arg175His — Giacomelli: 1.025 | Kotler: 1.791 | ClinVar: Pathogenic (expert panel)
- 🟢 p.Gly245Ser — Giacomelli: 0.772 | Kotler: 1.146 | ClinVar: Pathogenic (no assertion criteria)
- 🟢 p.Arg248Gln — Giacomelli: 0.812 | Kotler: 1.233 | ClinVar: Pathogenic (no assertion criteria)
- 🟢 p.Arg273His — Giacomelli: 1.221 | Kotler: 1.146 | ClinVar: Pathogenic (expert panel)
- 🟢 p.Tyr220Cys — Giacomelli: 1.102 | Kotler: 1.526 | ClinVar: Likely pathogenic (expert panel)

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
- 🟡 Expand scoring to explicit low/moderate/high classification
- 🟡 Integrate MaveDB score and ClinVar classification into interpretation output

## UI (Inspection Interface)
- 🟢 Home page, proteins index/show, variant show — all implemented
- 🟢 Protein show: UniProt entry and PDB structures cards
- 🟢 Variant show: MaveDB score and ClinVar classification cards
- 🟢 Variant show: Evidence Agreement card (system mechanism, MaveDB agreement, ClinVar agreement, overall)

## Testing
- 🟢 49 examples, 0 failures, 2 pending (development-only DB path specs)
- 🟢 Specs for Variant#mavedb_score and Variant#clinvar_classification lookups
- 🟢 Specs for EvidenceValidatorService (agree, disagree, no_data cases)
- 🟡 Add specs for Mavedb::Score and Clinvar::Classification models

## Validation Results (Phase 2 Complete)
- 🟢 EvidenceValidatorService wired into VariantsController#show
- 🟢 All 5 benchmark variants: agree across Giacomelli2018, Kotler2018, and ClinVar
- 🟢 Overall agreement rate: 100% (5/5 variants)
- 🟢 Formal results documented in PAPER.md

## LLM Development Process Findings
- 🟢 23 failure modes documented in CLAUDE_ERRORS.md
- 🟢 Goal substitution identified as critical failure mode (Error 22)
- 🟢 Context window cost identified as structural economic constraint (Error 23)
- 🟢 All findings documented in PAPER.md sections 6.2, 6.3, 6.4

## Next Steps
- 🟡 Start new conversation for any further work (context window hygiene)
- 🟡 Expand scoring to explicit low/moderate/high classification
- 🟡 Add specs for Mavedb::Score and Clinvar::Classification models
- 🟡 Extend benchmark set to variants with intermediate or uncertain functional classification
- 🟡 Consider formal submission of PAPER.md as a short methods/research note

## Next Steps (Start Fresh Session)
- 🟡 Start new conversation for any further work (context window hygiene -- Error 23)
- 🟡 Expand scoring to explicit low/moderate/high classification
- 🟡 Add specs for Mavedb::Score and Clinvar::Classification models
- 🟡 Extend benchmark set to variants with intermediate or uncertain functional classification
- 🟡 Consider formal submission of PAPER.md as a short methods/research note

## Future Extensions (Beyond TP53)
- 🟡 Extend to tau (UniProt P10636): map microtubule-binding region as ProteinFeature, load PDB structures of tau bound to tubulin
- 🟡 Extend to APP/amyloid-beta (UniProt P05067): annotate amyloid-beta peptide region and structural context
- 🟡 Compare tau microtubule-binding sequence region against amyloid-beta sequence for overlap
  -- basis of Julian et al. 2026 competitive binding hypothesis (doi:10.1093/pnasnexus/pgag034)
- 🟡 Would not simulate molecular dynamics -- provides deterministic structural context
  for reasoning about binding competition at sequence/domain level
