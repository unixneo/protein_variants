# TODO

## Scientific Objective and Blackboard KS Plan
- 🟢 Scientific objective is defined as deterministic missense interpretation for TP53 with structural/functional context.
- 🟢 Current system is deterministic and inspectable, not an AI prediction system.
- 🟢 DomainMapper KS behavior is implemented through residue-position mapping to `ProteinFeature` intervals.
- 🟢 StructureMapper KS behavior is implemented through residue-position mapping to `StructureEntry` intervals.
- 🟢 Interpretation KS behavior is implemented through `VariantInterpretationService` deterministic rules.
- 🟡 Add Protein → PDB lookup path as the next blackboard input channel.
- 🟡 Add EvidenceValidator KS against ClinVar / MaveDB for evidence comparison workflows.
- 🟡 Formalize identifier/position mapping strategies across main, Uniprot, PDB, and future evidence sources.

## Core Architecture
- 🟢 Multi-SQLite architecture is in place with model-layer database selection.
- 🟢 `ApplicationRecord` is the base class for main app models.
- 🟢 `UniprotRecord` is the abstract base class for Uniprot models.
- 🟢 `PdbRecord` is the abstract base class for PDB models.
- 🟢 Active SQLite files are `db/development.sqlite3`, `db/uniprot.sqlite3`, and `db/pdb.sqlite3`.

## Domain Models (Main DB)
- 🟢 `Protein` model implemented.
- 🟢 `Variant` model implemented.
- 🟢 `ProteinFeature` model implemented.
- 🟢 `StructureEntry` model implemented.
- 🟢 Main-model validations and indexes are present.

## External Data Sources
- 🟢 `Uniprot::Entry` model implemented on the Uniprot database.
- 🟢 `Pdb::Structure` model implemented on the PDB database.
- 🟢 External data source models use dedicated abstract base classes.
- 🟡 Add additional external source databases (ClinVar, MaveDB) using the same pattern.

## Cross-Database Lookups
- 🟢 `Protein#uniprot_entry` performs `Uniprot::Entry.find_by(accession: protein.uniprot_accession)`.
- 🟡 Add `Protein` → `Pdb::Structure` lookup path.
- 🟡 Define explicit mapping strategies between data sources (accession, identifiers, positional mappings).

## Data Ingestion / Bootstrapping
- 🟢 `Tp53FixtureImporter` imports local fixture data from `db/fixtures/tp53.json`.
- 🟢 Import flow supports protein upsert, feature replacement, structure replacement, and variant upsert.
- 🟢 Rake task `protein_variants:import_tp53_fixture` is available.

## Variant Interpretation
- 🟢 `VariantInterpretationService` implemented with deterministic rules.
- 🟢 Outputs include domain/structure hits, matching features/structures, preliminary mechanism, and confidence.

## UI (Inspection Interface)
- 🟢 Dark, card-based inspection UI is implemented with ERB + CSS.
- 🟢 Home page, proteins index/show, and variant show pages are implemented.
- 🟢 Utility control exists to trigger TP53 fixture import from the web UI.
- 🟡 Expose external lookup results (Uniprot/PDB) directly in inspection views.

## Diagnostics
- 🟢 `dbdiag:inspect` reports model DB paths, visible tables, file metadata, and sharing checks.
- 🟢 `dbdiag:touch_watch` watches whether main DB metadata changes during connection touch.
- 🟢 `dbdiag:watch_command` watches main DB metadata around a supplied command (`CMD`).
- 🟢 `dbdiag:watch_tasks` runs a built-in suspect list and reports per-command DB change status.
- 🟢 `dbdiag:watch_full_suite` watches main DB metadata around full RSpec.
- 🟢 `dbdiag:watch_sequence` runs ordered commands and stops on first detected writer.

## Testing
- 🟢 Model specs exist for main domain models.
- 🟢 Service specs exist for fixture import and variant interpretation.
- 🟢 Request specs exist for home/protein/variant pages and TP53 import action.
- 🟢 External DB specs exist for Uniprot and PDB models.
- 🟢 Connection-selection coverage exists for model-to-database routing.

## Data Strategy
- 🟢 Main app and external source data are isolated in separate SQLite files.
- 🟢 Cross-database access is performed through explicit lookups, not associations.
- 🟡 Formalize mapping rules for integrating external records into app-level inspection workflows.

## Next Steps (Immediate)
- 🟡 Implement `Protein` → `Pdb::Structure` lookup method following existing lookup style.
- 🟡 Add UI display blocks for external lookup results on protein and/or variant pages.
- 🟡 Define and document concrete identifier/position mapping strategy across main, Uniprot, and PDB datasets.
- 🟡 Prepare additional external source scaffolding for ClinVar and MaveDB with dedicated abstract base records.
