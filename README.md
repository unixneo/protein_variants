# protein_variants

A Rails application for deterministic interpretation of protein missense variants.

## Project Goal

Build an inspectable, engineering-focused system for deterministic interpretation of missense variants, starting with TP53.

## Scientific Objective

Initial target: TP53.

Core scientific question:
Given a missense variant, what is its likely structural/functional impact based on curated sequence, feature, and structure context?

## What the System Calculates

Current calculations:
- Variant residue-position lookup
- Domain-hit detection from curated feature intervals
- Structure-hit detection from curated structure intervals
- Preliminary deterministic classification from rule combinations

Planned calculations:
- Protein → PDB lookup expansion
- Evidence comparison against ClinVar / MaveDB
- Expanded rule-based impact scoring

## Blackboard / Knowledge Source Architecture

This project follows a blackboard-style orchestration model with separate knowledge sources over multiple SQLite files.

- DomainMapper KS: maps variant residue position against curated protein feature intervals.
- StructureMapper KS: maps variant residue position against curated structure intervals.
- Interpretation KS: combines deterministic rule outputs into preliminary mechanism and confidence.
- EvidenceValidator KS (planned): compares current interpretation with external evidence sources.

The system uses multiple SQLite database files as separate scientific data sources (`db/development.sqlite3`, `db/uniprot.sqlite3`, `db/pdb.sqlite3`).
The app orchestrates across those sources without merging them into one large database.
Current interpretation is deterministic and inspectable, not an AI prediction system.

## Initial Validation Plan

- Confirm model-to-database routing for main, Uniprot, and PDB sources.
- Validate deterministic interpretation branch coverage with reproducible fixture-driven tests.
- Validate cross-database lookup behavior and inspectability in request/service specs.

## Status

Early-stage prototype.

Current capabilities:
- Protein and Variant domain models
- Multi-SQLite data source setup
- RSpec test suite

## Design

See `DESIGN.md` for architecture and scope.

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
bundle exec rspec
```

## Data Strategy

This project treats the primary SQLite database as the canonical application-state artifact.

External or large reference datasets are intended to be stored in separate SQLite database files rather than merged into one monolithic database. This preserves provenance, keeps the main app database small, and supports reproducible scientific workflows.

Current local import utilities are development/bootstrap tools, not the long-term canonical data model

## Environment

This project is development-only.

It is not currently designed around separate production infrastructure. The primary application database and sidecar source databases are treated as development-time scientific artifacts.
