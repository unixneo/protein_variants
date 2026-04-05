# protein_variants — TODO

## 1. Core Architecture

- 🟢 Multi-SQLite architecture (model-based DB selection)
- 🟢 ApplicationRecord → main DB
- 🟢 UniprotRecord → db/uniprot.sqlite3
- 🟢 PdbRecord → db/pdb.sqlite3
- 🟢 No cross-database ActiveRecord associations
- 🟢 SQLite files tracked in git

---

## 2. Domain Models (Main DB)

- 🟢 Protein
- 🟢 Variant
- 🟢 ProteinFeature
- 🟢 StructureEntry

- 🟡 Additional domain entities (future, only if required)

---

## 3. External Data Sources

### UniProt

- 🟢 db/uniprot.sqlite3 created
- 🟢 UniprotRecord base class
- 🟢 Uniprot::Entry model
- 🟢 Read/write verified via tests

### PDB

- 🟢 db/pdb.sqlite3 created
- 🟢 PdbRecord base class
- 🟢 Pdb::Structure model
- 🟢 Read/write verified via tests

### Future Sources

- 🟡 ClinVar database
- 🟡 MaveDB database
- 🟡 Additional domain-specific datasets

---

## 4. Cross-Database Lookups

- 🟢 Protein → UniProt lookup (`Protein#uniprot_entry`)
- 🟡 Protein → PDB lookup (`Protein#pdb_structures`)
- 🟡 Additional lookup patterns (ClinVar, etc.)

---

## 5. Data Ingestion / Bootstrapping

- 🟢 TP53 fixture importer (development bootstrap only)
- 🟡 Replace JSON bootstrap with direct DB workflows
- 🟡 Controlled import/update from external DBs

---

## 6. Variant Interpretation

- 🟢 VariantInterpretationService (deterministic rules)
- 🟢 Domain/structure hit logic
- 🟢 Basic classification output

- 🟡 Extend interpretation logic using:
  - external data sources
  - evidence layers
  - validation datasets

---

## 7. UI (Inspection Interface)

- 🟢 Dark-themed card-based UI
- 🟢 Proteins index
- 🟢 Protein show page
- 🟢 Variant show page
- 🟢 Interpretation display

- 🟡 Show UniProt lookup results in UI
- 🟡 Show PDB lookup results in UI
- 🟡 Add filtering/search

---

## 8. Diagnostics

- 🟢 dbdiag:inspect
- 🟢 dbdiag:touch_watch
- 🟢 dbdiag:watch_command
- 🟢 dbdiag:watch_sequence
- 🟢 dbdiag:watch_full_suite

- 🟡 Extend diagnostics if new DB sources added

---

## 9. Testing

- 🟢 Model tests (core domain)
- 🟢 Database selection tests
- 🟢 External DB isolation tests
- 🟢 Lookup tests (UniProt)

- 🟡 Expand tests for:
  - PDB lookup
  - interpretation accuracy vs known data
  - cross-database workflows

---

## 10. Data Strategy

- 🟢 Primary DB as canonical working state
- 🟢 External DBs as independent data sources
- 🟢 No monolithic database
- 🟢 Direct query across DBs

- 🟡 Define mapping strategies between data sources
- 🟡 Define provenance tracking per result

---

## 11. Next Steps (Immediate)

- 🟡 Implement Protein → PDB lookup
- 🟡 Surface external lookups in UI
- 🟡 Define mapping key strategy (UniProt ↔ PDB)
- 🟡 Expand interpretation using external data

---

## Guiding Principle

Keep the system:

- small
- deterministic
- inspectable
- testable

Avoid premature complexity.
