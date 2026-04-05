class EvidenceValidatorService
  # MaveDB score threshold above which a variant is considered functionally impaired.
  # Based on Giacomelli 2018 score set (urn:mavedb:00000068-0-1).
  MAVEDB_IMPAIRMENT_THRESHOLD = 0.5

  # ClinVar classifications considered pathogenic for agreement checking.
  CLINVAR_PATHOGENIC = ["Pathogenic", "Likely pathogenic"].freeze

  def self.call(variant, interpretation)
    new(variant, interpretation).call
  end

  def initialize(variant, interpretation)
    @variant = variant
    @interpretation = interpretation
  end

  def call
    mavedb = @variant.mavedb_score
    clinvar = @variant.clinvar_classification

    mavedb_agreement = assess_mavedb(mavedb)
    clinvar_agreement = assess_clinvar(clinvar)
    evidence_score = evidence_confidence_score(mavedb, clinvar)

    {
      variant_id: @variant.id,
      hgvs_protein: @variant.hgvs_protein,
      system_mechanism: @interpretation[:preliminary_mechanism],
      system_confidence: @interpretation[:confidence],
      structural_confidence_score: @interpretation[:structural_confidence_score],
      evidence_confidence_score: evidence_score,
      confidence_level: combined_confidence_level(evidence_score),
      mavedb: {
        score: mavedb&.score,
        source: mavedb&.source,
        score_set_urn: mavedb&.score_set_urn,
        functionally_impaired: mavedb_agreement[:functionally_impaired],
        agreement: mavedb_agreement[:agreement],
        note: mavedb_agreement[:note]
      },
      clinvar: {
        clinical_significance: clinvar&.clinical_significance,
        review_status: clinvar&.review_status,
        last_evaluated: clinvar&.last_evaluated,
        pathogenic: clinvar_agreement[:pathogenic],
        agreement: clinvar_agreement[:agreement],
        note: clinvar_agreement[:note]
      },
      overall_agreement: overall_agreement(mavedb_agreement, clinvar_agreement)
    }
  end

  private

  def assess_mavedb(mavedb)
    return { functionally_impaired: nil, agreement: :no_data, note: "No MaveDB score available" } unless mavedb

    impaired = mavedb.score >= MAVEDB_IMPAIRMENT_THRESHOLD
    system_flagged = @interpretation[:domain_hit] || @interpretation[:structure_hit]

    agreement = if impaired && system_flagged
      :agree
    elsif !impaired && !system_flagged
      :agree
    else
      :disagree
    end

    {
      functionally_impaired: impaired,
      agreement: agreement,
      note: "Score #{mavedb.score} #{impaired ? '>=' : '<'} threshold #{MAVEDB_IMPAIRMENT_THRESHOLD}"
    }
  end

  def assess_clinvar(clinvar)
    return { pathogenic: nil, agreement: :no_data, note: "No ClinVar classification available" } unless clinvar

    pathogenic = CLINVAR_PATHOGENIC.include?(clinvar.clinical_significance)
    system_flagged = @interpretation[:domain_hit] || @interpretation[:structure_hit]

    agreement = if pathogenic && system_flagged
      :agree
    elsif !pathogenic && !system_flagged
      :agree
    else
      :disagree
    end

    {
      pathogenic: pathogenic,
      agreement: agreement,
      note: "#{clinvar.clinical_significance} (#{clinvar.review_status})"
    }
  end

  def overall_agreement(mavedb_agreement, clinvar_agreement)
    statuses = [mavedb_agreement[:agreement], clinvar_agreement[:agreement]]
    return :no_data if statuses.all? { |s| s == :no_data }
    return :agree if statuses.reject { |s| s == :no_data }.all? { |s| s == :agree }

    :disagree
  end

  def evidence_confidence_score(mavedb, clinvar)
    mavedb_axis_score(mavedb) + clinvar_axis_score(clinvar)
  end

  def combined_confidence_level(evidence_score)
    total = @interpretation[:structural_confidence_score].to_i + evidence_score
    return :high if total >= 70
    return :moderate if total >= 40

    :low
  end

  def mavedb_axis_score(mavedb)
    return 0 unless mavedb
    return 20 if mavedb.score >= 0.7
    return 10 if mavedb.score >= 0.5

    0
  end

  def clinvar_axis_score(clinvar)
    return 0 unless clinvar

    expert_panel = clinvar.review_status.to_s.downcase.include?("expert panel")
    pathogenic = CLINVAR_PATHOGENIC.include?(clinvar.clinical_significance)

    score = expert_panel ? 15 : 0
    score += 5 if pathogenic && !expert_panel
    score
  end
end
