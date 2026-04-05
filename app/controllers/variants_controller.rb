class VariantsController < ApplicationController
  def show
    @variant = Variant.includes(protein: [ :protein_features, :structure_entries ]).find(params[:id])
    @interpretation = VariantInterpretationService.call(@variant)
  end
end
