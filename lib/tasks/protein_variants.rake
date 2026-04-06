namespace :protein_variants do
  desc "Import local TP53 fixture data"
  task import_tp53_fixture: :environment do
    summary = Tp53FixtureImporter.call
    puts summary
  end

  desc "Import local Tau fixture data"
  task import_tau: :environment do
    summary = ProteinFixtureImporter.call(Rails.root.join("db/fixtures/tau.json"))
    puts summary
  end

  desc "Import local APP fixture data"
  task import_app: :environment do
    summary = ProteinFixtureImporter.call(Rails.root.join("db/fixtures/app.json"))
    puts summary
  end

  desc "Import all Phase 4 fixture data (tau + app)"
  task import_all_phase4: :environment do
    tau_summary = ProteinFixtureImporter.call(Rails.root.join("db/fixtures/tau.json"))
    app_summary = ProteinFixtureImporter.call(Rails.root.join("db/fixtures/app.json"))

    puts({ tau: tau_summary, app: app_summary })
  end
end
