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
