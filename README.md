# protein_variants

A minimal Rails application for deterministic interpretation of protein missense variants.

## Status

Early-stage prototype.

Current capabilities:
- Protein and Variant domain models
- SQLite3 database
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

## Data Strategy

This project treats the primary SQLite database as the canonical application-state artifact.

External or large reference datasets are intended to be stored in separate SQLite database files rather than merged into one monolithic database. This preserves provenance, keeps the main app database small, and supports reproducible scientific workflows.

Current local import utilities are development/bootstrap tools, not the long-term canonical data model

## Environment

This project is development-only.

It is not currently designed around separate production infrastructure. The primary application database and sidecar source databases are treated as development-time scientific artifacts.
