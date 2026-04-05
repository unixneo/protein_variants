namespace :protein_variants do
  desc "Import local TP53 fixture data"
  task import_tp53_fixture: :environment do
    summary = Tp53FixtureImporter.call
    puts summary
  end
end
