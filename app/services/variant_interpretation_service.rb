class VariantInterpretationService
  def self.call(variant)
    new(variant).call
  end

  def initialize(variant)
    @variant = variant
    @protein = variant.protein
    @position = variant.residue_position
  end

  def call
    feature_matches = matching_feature_records
    structure_matches = matching_structure_records
    domain_hit = feature_matches.any?
    structure_hit = structure_matches.any?

    {
      variant_id: @variant.id,
      protein_accession: @protein.uniprot_accession,
      hgvs_protein: @variant.hgvs_protein,
      residue_position: @position,
      domain_hit: domain_hit,
      structure_hit: structure_hit,
      matching_features: feature_matches.map do |feature|
        {
          feature_type: feature.feature_type,
          start_pos: feature.start_pos,
          end_pos: feature.end_pos,
          description: feature.description
        }
      end,
      matching_structures: structure_matches.map do |structure|
        {
          pdb_id: structure.pdb_id,
          chain_id: structure.chain_id,
          start_pos: structure.start_pos,
          end_pos: structure.end_pos,
          method: structure.method
        }
      end,
      preliminary_mechanism: preliminary_mechanism(domain_hit, structure_hit),
      confidence: domain_hit && structure_hit ? "medium" : "low"
    }
  end

  private

  def matching_feature_records
    @protein.protein_features.where("start_pos <= ? AND end_pos >= ?", @position, @position).order(:start_pos, :end_pos)
  end

  def matching_structure_records
    @protein.structure_entries.where("start_pos <= ? AND end_pos >= ?", @position, @position).order(:start_pos, :end_pos)
  end

  def preliminary_mechanism(domain_hit, structure_hit)
    return "structured functional region" if domain_hit && structure_hit
    return "annotated functional region" if domain_hit
    return "structured region" if structure_hit

    "unannotated region"
  end
end
