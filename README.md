# protein_variants

A Rails application for deterministic interpretation of protein missense variants.

## Primary Goal

This project is a controlled experiment in LLM-assisted scientific software development:

**Can an LLM-built deterministic system produce scientifically valid results when compared to peer-reviewed experimental data?**

The system is built using a two-stage human-AI workflow: Claude (Anthropic) acts as architect, scientist, and prompt author; Codex CLI acts as code implementer. Documented failure modes and operating rules are maintained in `CLAUDE_ERRORS.md`. The workflow itself is part of the research.

## Scientific Test Vehicle

The experiment uses TP53 missense variant interpretation as the test domain. TP53 is well-characterized, with large-scale experimental functional data (MaveDB) and curated clinical classifications (ClinVar) available for validation.

Core scientific question:
Given a missense variant, what is its likely structural/functional impact based on curated sequence, feature, and structure context -- and does the system's output agree with peer-reviewed experimental evidence?

## What the System Calculates

Current calculations:
- Variant residue-position lookup against canonical UniProt sequence
- Domain-hit detection from curated protein feature intervals (DomainMapper KS)
- Structure-hit detection from curated PDB structure intervals (StructureMapper KS)
- Preliminary deterministic classification from rule combinations (Interpretation KS)
- Quantitative confidence scoring: structural axis (0–60) + evidence axis (0–40) → :high/:moderate/:low
- External evidence lookup: MaveDB functional scores (Giacomelli 2018, Kotler 2018), ClinVar classifications
- EvidenceValidator KS: formal agreement measurement, 100% agreement rate across all 5 benchmark variants

## Blackboard / Knowledge Source Architecture

This project follows a blackboard-style orchestration model with separate knowledge sources over multiple SQLite files.

- DomainMapper KS: maps variant residue position against curated protein feature intervals.
- StructureMapper KS: maps variant residue position against curated PDB structure intervals.
- Interpretation KS: combines deterministic rule outputs into preliminary mechanism and quantitative confidence score (structural axis, 0–60).
- EvidenceValidator KS: compares interpretation against MaveDB and ClinVar; computes evidence confidence score (0–40) and combined confidence level (:high/:moderate/:low).

SQLite databases as scientific artifacts:
- `db/development.sqlite3` — main app: proteins, variants, features, structure entries
- `db/uniprot.sqlite3` — UniProt canonical accession and name
- `db/pdb.sqlite3` — PDB structures with residue coverage (5 curated structures for P04637)
- `db/mavedb.sqlite3` — MaveDB functional scores (Giacomelli 2018, 5 benchmark variants)
- `db/clinvar.sqlite3` — ClinVar germline classifications (5 benchmark variants)

## Benchmark Variant Set

All five benchmark variants are loaded with full external evidence:

| Variant | MaveDB Score | ClinVar | Review Status |
|---|---|---|---|
| p.Arg175His | 1.025 | Pathogenic | Expert panel |
| p.Gly245Ser | 0.772 | Pathogenic | No assertion criteria |
| p.Arg248Gln | 0.812 | Pathogenic | No assertion criteria |
| p.Arg273His | 1.221 | Pathogenic | Expert panel |
| p.Tyr220Cys | 1.102 | Likely pathogenic | Expert panel |

## Status

Phase 1 and Phase 2 complete. Phase 3 (scoring) complete.

Current capabilities:
- Multi-SQLite architecture: 5 separate scientific data sources
- TP53 (P04637): full 393-residue canonical sequence
- 5 benchmark variants with domain/structure context and full external evidence
- `VariantInterpretationService`: deterministic rule engine, quantitative structural confidence scoring (0–60)
- `EvidenceValidatorService`: agree/disagree/no_data vs MaveDB (Giacomelli 2018, Kotler 2018) and ClinVar; evidence confidence scoring (0–40); combined confidence level (:high/:moderate/:low)
- 100% agreement rate across all 5 benchmark variants and all 3 evidence sources
- `Protein#uniprot_entry`: cross-database lookup into UniProt DB
- `Protein#pdb_structures`: cross-database lookup into PDB DB (with residue coverage)
- `Variant#mavedb_score`: cross-database lookup into MaveDB DB
- `Variant#clinvar_classification`: cross-database lookup into ClinVar DB
- `Mavedb::Score` and `Clinvar::Classification` models with populated data
- Standalone fetch scripts for RCSB, MaveDB, and ClinVar APIs
- Dark card-based inspection UI: home, proteins index/show, variant show with full evidence and confidence cards
- 67 RSpec examples, 0 failures

Next:
- Extend benchmark set to variants with intermediate or uncertain functional classification
- Consider formal submission of PAPER.md as a short methods/research note

## Design

See `DESIGN.md` for architecture and scope.
See `PAPER.md` for the emerging scientific narrative.
See `REFERENCES.md` for data sources and peer-reviewed benchmarks.
See `CLAUDE_ERRORS.md` for documented LLM failure modes and operating rules.

## Requirements

- Ruby (version from `.ruby-version`)
- Rails (version from `Gemfile`)
- SQLite3

## Setup

```bash
git clone git@github.com:unixneo/protein_variants.git
cd protein_variants
bundle install
bin/rails db:create db:migrate
bin/rails db:rebuild_uniprot db:rebuild_pdb db:rebuild_mavedb db:rebuild_clinvar
bundle exec rails protein_variants:import_tp53_fixture
ruby script/fetch_pdb_structures.rb
ruby script/fetch_mavedb_scores.rb
ruby script/fetch_clinvar_classifications.rb
bundle exec rspec
```

## Data Strategy

Each external data source is stored in its own SQLite file, preserving provenance and keeping the main application database small. SQLite files are treated as versioned scientific artifacts, not just storage backends.

## Environment

Development-only. Not designed for production deployment.
