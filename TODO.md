# TODO

## Scientific Objective
- This project is a controlled experiment:
  Can a deterministic, LLM-assisted system produce scientifically valid results when compared to peer-reviewed experimental data?
- Initial focus: TP53 missense variants (UniProt: P04637).

## Data Sources (SQLite Databases)
- 🟢 Main DB (`db/development.sqlite3`): proteins, variants, protein_features, structure_entries
- 🟢 UniProt DB (`db/uniprot.sqlite3`): canonical accession, name
- 🟢 PDB DB (`db/pdb.sqlite3`): structures with pdb_id, method, resolution, chain_id, start_pos, end_pos
- 🟢 MaveDB DB (`db/mavedb.sqlite3`): functional scores, Giacomelli 2018 (5 variants)
- 🟢 ClinVar DB (`db/clinvar.sqlite3`): germline classifications, review status (5 variants)

## Benchmark Variant Set
- 🟢 p.Arg175His — MaveDB: 1.025 | ClinVar: Pathogenic (expert panel)
- 🟢 p.Gly245Ser — MaveDB: 0.772 | ClinVar: Pathogenic (no assertion criteria)
- 🟢 p.Arg248Gln — MaveDB: 0.812 | ClinVar: Pathogenic (no assertion criteria)
- 🟢 p.Arg273His — MaveDB: 1.221 | ClinVar: Pathogenic (expert panel)
- 🟢 p.Tyr220Cys — MaveDB: 1.102 | ClinVar: Likely pathogenic (expert panel)

## Blackboard Knowledge Sources
- 🟢 KS: DomainMapper — residue-position mapping to ProteinFeature intervals
- 🟢 KS: StructureMapper — residue-position mapping to StructureEntry intervals
- 🟢 KS: Interpretation — deterministic rule engine (VariantInterpretationService)
- 🟡 KS: EvidenceValidator — compare interpretation against MaveDB and ClinVar

## Core Architecture
- 🟢 Multi-SQLite architecture with model-layer database selection
- 🟢 ApplicationRecord, UniprotRecord, PdbRecord, MavedbRecord, ClinvarRecord base classes
- 🟢 Migration isolation: external DBs use dead migration paths (no bleed)
- 🟢 Rebuild rake tasks for all external databases

## Domain Models (Main DB)
- 🟢 Protein, Variant, ProteinFeature, StructureEntry — all implemented with validations and indexes

## External Data Sources
- 🟢 Uniprot::Entry (db/uniprot.sqlite3)
- 🟢 Pdb::Structure (db/pdb.sqlite3) — 5 structures with full residue coverage
- 🟢 Mavedb::Score (db/mavedb.sqlite3) — 5 benchmark variant scores
- 🟢 Clinvar::Classification (db/clinvar.sqlite3) — 5 benchmark classifications

## Cross-Database Lookups
- 🟢 Protein#uniprot_entry — lookup into Uniprot::Entry by accession
- 🟢 Protein#pdb_structures — lookup into Pdb::Structure by uniprot_accession
- 🟡 Variant#mavedb_score — lookup into Mavedb::Score by hgvs_protein
- 🟡 Variant#clinvar_classification — lookup into Clinvar::Classification by hgvs_protein

## Data Ingestion Scripts (Standalone Ruby, not rake)
- 🟢 script/fetch_pdb_structures.rb — RCSB Data API + Sequence Coordinates API
- 🟢 script/fetch_mavedb_scores.rb — MaveDB CSV API (Giacomelli 2018)
- 🟢 script/fetch_clinvar_classifications.rb — NCBI eutils esearch + esummary
- 🟡 script/fetch_kotler2018_scores.rb — MaveDB Kotler 2018 score set (second benchmark)

## Variant Interpretation
- 🟢 VariantInterpretationService: deterministic rules, all four branch outcomes
- 🟡 Expand scoring to explicit low/moderate/high classification
- 🟡 Integrate MaveDB score and ClinVar classification into interpretation output

## UI (Inspection Interface)
- 🟢 Home page, proteins index/show, variant show — all implemented
- 🟢 Protein show: UniProt entry and PDB structures cards displayed
- 🟡 Variant show: MaveDB score and ClinVar classification cards
- 🟡 Variant show: agreement/disagreement indicator between system output and evidence

## Testing
- 🟢 44 examples, 0 failures, 2 pending (development-only DB path specs)
- 🟡 Add specs for Mavedb::Score and Clinvar::Classification models
- 🟡 Add specs for Variant#mavedb_score and Variant#clinvar_classification lookups

## Validation Plan (Critical — Phase 2)
- 🟡 Implement EvidenceValidator KS
- 🟡 For each benchmark variant: compare system mechanism output to MaveDB score
- 🟡 For each benchmark variant: compare system output to ClinVar classification
- 🟡 Add Kotler 2018 score set as second MaveDB comparator
- 🟡 Document agreement/disagreement results in PAPER.md

## Next Steps (Immediate)
- 🟡 Add Variant#mavedb_score and Variant#clinvar_classification lookup methods
- 🟡 Expose MaveDB and ClinVar data on variant show page
- 🟡 Implement EvidenceValidator KS as a new service class
- 🟡 Fetch Kotler 2018 score set from MaveDB
- 🟡 Run and document formal validation results
