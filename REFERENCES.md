# REFERENCES.md

## Purpose

This file lists the confirmed external references for `protein_variants`.

It is limited to sources that are relevant to the current project design:

- protein sequence and feature annotation
- experimental structure data
- clinical variant interpretation
- multiplexed functional assay data
- peer-reviewed TP53 functional benchmarks

---

## 1. Core Data Sources

### UniProt

**Use in project**
- canonical protein accession
- protein sequence
- curated functional features and regions

**Reference**
- UniProt. *UniProt*.  
  https://www.uniprot.org/

**Notes**
- UniProt describes itself as a leading freely accessible resource of protein sequence and functional information.

---

### RCSB Protein Data Bank (PDB)

**Use in project**
- experimental structure metadata
- residue coverage
- chain mappings
- PDB identifiers

**References**
- RCSB PDB. *RCSB Protein Data Bank*.  
  https://www.rcsb.org/

- RCSB PDB. *Data API*.  
  https://data.rcsb.org/

**Notes**
- The RCSB PDB provides access to experimentally determined 3D structures and metadata needed for structure-based mapping.

---

### ClinVar

**Use in project**
- clinical significance comparison
- review status / evidence strength as a comparator layer

**References**
- NCBI. *ClinVar*.  
  https://www.ncbi.nlm.nih.gov/clinvar/

- NCBI. *Review status in ClinVar*.  
  https://www.ncbi.nlm.nih.gov/clinvar/docs/review_status/

- Landrum MJ, et al. (2018). *ClinVar: improving access to variant interpretations and supporting evidence*.  
  Nucleic Acids Research, 46(D1), D1062-D1067.  
  https://academic.oup.com/nar/article/46/D1/D1062/4641904

**Notes**
- ClinVar is a curated public archive of human variant interpretations.
- ClinVar review status is useful for weighting confidence, but ClinVar is not itself the same as peer-reviewed experimental ground truth.

---

### MaveDB

**Use in project**
- functional assay comparison
- structured repository of variant effect scores
- TP53 benchmark score sets

**References**
- MaveDB. *MaveDB*.  
  https://mavedb.org/

- Esposito D, et al. (2019). *MaveDB: an open-source platform to distribute and interpret data from multiplexed assays of variant effect*.  
  Genome Biology, 20, 223.  
  https://pmc.ncbi.nlm.nih.gov/articles/PMC6827219/

**Project-specific TP53 references**
- MaveDB TP53 score set page.  
  https://mavedb.org/score-sets/urn%3Amavedb%3A00001213-a-1

- MaveDB TP53 functional meta-analysis page.  
  https://mavedb.org/experiments/urn%3Amavedb%3A00001234-0

---

## 2. Peer-Reviewed TP53 Functional Benchmarks

These are the key papers to use when comparing computed results against experimental evidence.

### Kotler et al. (2018)

**Use in project**
- peer-reviewed TP53 functional benchmark
- large-scale experimental characterization of TP53 variants

**Reference**
- Kotler E, et al. (2018). *A systematic p53 mutation library links differential functional impact to cancer mutation pattern and evolutionary conservation*.  
  Molecular Cell.  
  https://pmc.ncbi.nlm.nih.gov/articles/PMC6276857/

---

### Giacomelli et al. (2018)

**Use in project**
- peer-reviewed TP53 functional benchmark
- large-scale TP53 variant functional landscape

**Reference**
- Giacomelli AO, et al. (2018). *Mutational processes shape the landscape of TP53 mutations in human cancer*.  
  Nature Genetics / related TP53 functional landscape work as represented in the TP53 MAVE resources.  
  MaveDB-linked TP53 score set:  
  https://www.mavedb.org/score-sets/urn%3Amavedb%3A00000068-0-1?calibration=urn%3Amavedb%3Acalibration-f44a1a0e-3f40-4ec7-b9ff-e1a08dd7121c

**Note**
- Use the exact published paper and the matching MaveDB score-set metadata together when finalizing the validation layer.

---

## 3. Project Data Mapping Strategy

### Main application database (`db/development.sqlite3`)
Stores:
- curated proteins
- curated variants
- curated protein features
- curated structure entries
- interpretation results
- validation results

### UniProt database (`db/uniprot.sqlite3`)
Stores:
- canonical accession
- sequence
- feature annotations

### PDB database (`db/pdb.sqlite3`)
Stores:
- structure metadata
- residue coverage
- chain information

### Planned databases
- `db/clinvar.sqlite3`
- `db/mavedb.sqlite3`

---

## 4. Validation Principle

The project should compare computed deterministic outputs against:

1. **Peer-reviewed TP53 functional papers**
   - Kotler et al. 2018
   - Giacomelli et al. 2018

2. **Structured functional score repositories**
   - MaveDB TP53 score sets

3. **Curated clinical interpretation**
   - ClinVar, weighted by review status

The order of scientific weight should be:

1. peer-reviewed experimental functional evidence  
2. structured assay repositories derived from that literature  
3. curated clinical interpretation

---

## 5. Current Initial Benchmark Variant Set

All five TP53 missense variants are confirmed present in MaveDB and ClinVar:

| Variant | Position | MaveDB Score (Giacomelli) | ClinVar | Review Status |
|---|---|---|---|---|
| p.Arg175His | 175 | 1.025 | Pathogenic | Expert panel |
| p.Gly245Ser | 245 | 0.772 | Pathogenic | No assertion criteria |
| p.Arg248Gln | 248 | 0.812 | Pathogenic | No assertion criteria |
| p.Arg273His | 273 | 1.221 | Pathogenic | Expert panel |
| p.Tyr220Cys | 220 | 1.102 | Likely pathogenic | Expert panel |

MaveDB score set: urn:mavedb:00000068-0-1 (Giacomelli 2018)
ClinVar variation IDs: 12374 (R175H), 12385 (G245S), 12386 (R248Q), 12392 (R273H), 12375 (Y220C)

---

## 6. Confirmed Reference Summary

### Authoritative data sources
- UniProt
- RCSB PDB / Data API
- ClinVar
- MaveDB

### Peer-reviewed validation references
- Kotler et al. 2018
- Giacomelli et al. 2018
- Landrum et al. 2018 (ClinVar infrastructure/reference)

---

## 7. Caution

Do not treat all sources as equivalent.

- **UniProt** = curated sequence/features
- **PDB** = experimental structure
- **MaveDB** = functional assay score repository
- **ClinVar** = curated clinical interpretation, not pure experimental truth
- **peer-reviewed TP53 papers** = primary scientific benchmark

