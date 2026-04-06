# protein_variants

A Rails application for deterministic interpretation of protein missense variants.

## Primary Goal

This project is a controlled experiment in LLM-assisted scientific software development:

**Can a rule-based lookup system built primarily using LLMs produce outputs that
are consistent with peer-reviewed experimental evidence?**

This is not a classifier. It is not a machine learning system. It does not predict
variant pathogenicity. It is a deterministic, rule-based structural evidence lookup
engine that asks a narrow question: does this variant's residue position fall inside
a known functional domain and an experimentally resolved protein structure?

The answer to that question — yes or no — is then compared against two independent
peer-reviewed evidence sources (MaveDB functional scores, ClinVar clinical
classifications) to measure agreement. The research contribution is the development
workflow and the validation methodology, not the variant calls themselves.

The experimental vehicle is TP53 missense variant interpretation because TP53 is
well-characterized, the validation data is publicly available, and the correct answers
for canonical hotspot variants are unambiguous.

## Scientific Test Vehicle

The experiment uses TP53 missense variant interpretation as the test domain. TP53 is well-characterized, with large-scale experimental functional data (MaveDB) and curated clinical classifications (ClinVar) available for validation.

Core scientific question:
Given a missense variant, what is its likely structural/functional impact based on curated sequence, feature, and structure context -- and does the system's output agree with peer-reviewed experimental evidence?

## What the System Does

Given a missense variant (e.g. p.Arg175His), the system:

1. Looks up whether the variant's residue position falls inside a curated UniProt
   functional domain annotation (DomainMapper KS).
2. Looks up whether the residue position falls inside a curated PDB structure
   coverage interval (StructureMapper KS).
3. Applies explicit deterministic rules to those two boolean results to produce a
   mechanism label and a structural confidence score (Interpretation KS).
4. Compares that output against MaveDB functional scores and ClinVar clinical
   classifications to measure agreement (EvidenceValidator KS).

Every step is inspectable and traceable to its source database. There is no
probabilistic inference, no model training, no learned weights.

The confidence score (structural axis 0–60, evidence axis 0–40, combined total
→ :high/:moderate/:low) is a rule-based point accumulation, not a calibrated
probabilistic estimate.

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
