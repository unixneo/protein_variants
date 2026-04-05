class ProteinsController < ApplicationController
  def index
    @proteins = Protein.includes(:variants, :protein_features, :structure_entries).order(:uniprot_accession)
  end

  def show
    @protein = Protein.includes(:variants, :protein_features, :structure_entries).find(params[:id])
  end
end
