require_relative '../config/environment'

variant = Protein.find_by!(uniprot_accession: "P10636")
          .variants.find_by!(hgvs_protein: "p.Pro619Leu")

puts "=== VariantInterpretationService ==="
puts VariantInterpretationService.call(variant).inspect

puts "\n=== EvidenceValidatorService ==="
puts EvidenceValidatorService.call(variant, VariantInterpretationService.call(variant)).inspect
