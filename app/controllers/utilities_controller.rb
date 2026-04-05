class UtilitiesController < ApplicationController
  def import_tp53_fixture
    summary = Tp53FixtureImporter.call
    redirect_to root_path, notice: success_message(summary)
  rescue StandardError => e
    redirect_to root_path, alert: "TP53 fixture import failed: #{e.message}"
  end

  private

  def success_message(summary)
    "TP53 fixture imported. protein_created_or_updated=#{summary[:protein_created_or_updated]}, " \
      "protein_features_loaded=#{summary[:protein_features_loaded]}, " \
      "structure_entries_loaded=#{summary[:structure_entries_loaded]}, " \
      "variants_loaded=#{summary[:variants_loaded]}"
  end
end
