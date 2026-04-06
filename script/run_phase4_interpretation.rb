require_relative '../config/environment'

%w[P10636 P05067].each do |accession|
  protein = Protein.find_by!(uniprot_accession: accession)
  puts "\n=== #{protein.gene_symbol} (#{accession}) ==="
  puts "%-20s %-12s %-14s %-30s %-8s %-10s" % [
    "variant", "domain_hit", "structure_hit", "mechanism",
    "str_score", "confidence"
  ]
  protein.variants.order(:residue_position).each do |variant|
    i = VariantInterpretationService.call(variant)
    e = EvidenceValidatorService.call(variant, i)
    puts "%-20s %-12s %-14s %-30s %-8s %-10s" % [
      i[:hgvs_protein],
      i[:domain_hit].to_s,
      i[:structure_hit].to_s,
      i[:preliminary_mechanism],
      i[:structural_confidence_score].to_s,
      e[:confidence_level].to_s
    ]
  end
end
