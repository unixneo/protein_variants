require "rails_helper"

RSpec.describe VariantInterpretationService do
  let(:protein) { Protein.create!(uniprot_accession: "P04637") }

  def create_variant(position, hgvs)
    Variant.create!(
      protein: protein,
      hgvs_protein: hgvs,
      residue_position: position,
      ref_aa: "R",
      alt_aa: "H"
    )
  end

  describe ".call" do
    context "when domain and structure both match" do
      it "returns structured functional region with high confidence and matching payloads" do
        protein.protein_features.create!(
          feature_type: "domain",
          start_pos: 100,
          end_pos: 200,
          description: "DNA-binding domain",
          source_db: "UniProt"
        )
        protein.protein_features.create!(
          feature_type: "region",
          start_pos: 1,
          end_pos: 50,
          description: "Non-matching region",
          source_db: "UniProt"
        )
        protein.structure_entries.create!(
          pdb_id: "1TUP",
          chain_id: "A",
          start_pos: 90,
          end_pos: 210,
          method: "X-ray diffraction",
          resolution: 1.8
        )
        protein.structure_entries.create!(
          pdb_id: "9XXX",
          chain_id: "Z",
          start_pos: 1,
          end_pos: 20,
          method: "NMR"
        )
        variant = create_variant(175, "p.Arg175His")

        result = described_class.call(variant)

        expect(result.slice(:variant_id, :protein_accession, :hgvs_protein, :residue_position)).to eq(
          variant_id: variant.id,
          protein_accession: "P04637",
          hgvs_protein: "p.Arg175His",
          residue_position: 175
        )
        expect(result[:domain_hit]).to be(true)
        expect(result[:structure_hit]).to be(true)
        expect(result[:preliminary_mechanism]).to eq("structured functional region")
        expect(result[:structural_confidence_score]).to eq(60)
        expect(result[:confidence]).to eq(:high)
        expect(result[:matching_features]).to eq(
          [
            {
              feature_type: "domain",
              start_pos: 100,
              end_pos: 200,
              description: "DNA-binding domain"
            }
          ]
        )
        expect(result[:matching_structures]).to eq(
          [
            {
              pdb_id: "1TUP",
              chain_id: "A",
              start_pos: 90,
              end_pos: 210,
              method: "X-ray diffraction"
            }
          ]
        )
      end
    end

    context "when only domain matches" do
      it "returns annotated functional region with moderate confidence" do
        protein.protein_features.create!(
          feature_type: "domain",
          start_pos: 100,
          end_pos: 200,
          description: "DNA-binding domain",
          source_db: "UniProt"
        )
        protein.structure_entries.create!(
          pdb_id: "1TUP",
          chain_id: "A",
          start_pos: 1,
          end_pos: 50,
          method: "X-ray diffraction"
        )
        variant = create_variant(175, "p.Arg175Leu")

        result = described_class.call(variant)

        expect(result[:domain_hit]).to be(true)
        expect(result[:structure_hit]).to be(false)
        expect(result[:preliminary_mechanism]).to eq("annotated functional region")
        expect(result[:structural_confidence_score]).to eq(30)
        expect(result[:confidence]).to eq(:moderate)
        expect(result[:matching_features]).to eq(
          [
            {
              feature_type: "domain",
              start_pos: 100,
              end_pos: 200,
              description: "DNA-binding domain"
            }
          ]
        )
        expect(result[:matching_structures]).to eq([])
      end
    end

    context "when only structure matches" do
      it "returns structured region with low confidence" do
        protein.protein_features.create!(
          feature_type: "domain",
          start_pos: 1,
          end_pos: 50,
          description: "Non-matching domain",
          source_db: "UniProt"
        )
        protein.structure_entries.create!(
          pdb_id: "2OCJ",
          chain_id: "B",
          start_pos: 150,
          end_pos: 250,
          method: "X-ray diffraction"
        )
        variant = create_variant(175, "p.Arg175Ser")

        result = described_class.call(variant)

        expect(result[:domain_hit]).to be(false)
        expect(result[:structure_hit]).to be(true)
        expect(result[:preliminary_mechanism]).to eq("structured region")
        expect(result[:structural_confidence_score]).to eq(20)
        expect(result[:confidence]).to eq(:low)
        expect(result[:matching_features]).to eq([])
        expect(result[:matching_structures]).to eq(
          [
            {
              pdb_id: "2OCJ",
              chain_id: "B",
              start_pos: 150,
              end_pos: 250,
              method: "X-ray diffraction"
            }
          ]
        )
      end
    end

    context "when neither domain nor structure matches" do
      it "returns unannotated region with low confidence" do
        protein.protein_features.create!(
          feature_type: "domain",
          start_pos: 1,
          end_pos: 50,
          description: "Non-matching domain",
          source_db: "UniProt"
        )
        protein.structure_entries.create!(
          pdb_id: "2OCJ",
          chain_id: "B",
          start_pos: 60,
          end_pos: 100,
          method: "X-ray diffraction"
        )
        variant = create_variant(175, "p.Arg175Cys")

        result = described_class.call(variant)

        expect(result[:domain_hit]).to be(false)
        expect(result[:structure_hit]).to be(false)
        expect(result[:preliminary_mechanism]).to eq("unannotated region")
        expect(result[:structural_confidence_score]).to eq(0)
        expect(result[:confidence]).to eq(:low)
        expect(result[:matching_features]).to eq([])
        expect(result[:matching_structures]).to eq([])
      end
    end
  end
end
