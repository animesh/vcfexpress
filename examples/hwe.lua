function erfc(x)
    -- Coefficients for the approximation
    local a1 = 0.254829592
    local a2 = -0.284496736
    local a3 = 1.421413741
    local a4 = -1.453152027
    local a5 = 1.061405429
    local p  = 0.3275911

    -- Sign of x
    local sign = 1
    if x < 0 then
        sign = -1
    end
    x = math.abs(x)

    -- Compute the approximation
    local t = 1 / (1 + p * x)
    local exp_term = math.exp(-x * x)
    local poly = (((((a5 * t + a4) * t) + a3) * t + a2) * t + a1) * t

    local erf_approx = 1 - poly * exp_term
    return 1 - sign * erf_approx  -- Compute erfc(x) = 1 - erf(x)
end

function chi_square_p_value(chi2)
    -- Compute p-value from chi-square statistic with 1 degree of freedom
    return erfc(math.sqrt(chi2 / 2)) / 2
end

function hwe(variant)
    -- Bail if more than 1 alt allele
    if #variant.ALT > 1 then return nil end

    local gts = variant.genotypes
    return hwe_alts(gts)
end

function hwe_alts(gts)
    -- Count genotype classes
    local obs_hom_ref, obs_het, obs_hom_alt = 0, 0, 0
    for i = 1, #gts do
        local alts = gts[i].alts
        if alts == 0 then obs_hom_ref = obs_hom_ref + 1
        elseif alts == 1 then obs_het = obs_het + 1 
        elseif alts == 2 then obs_hom_alt = obs_hom_alt + 1 end
    end

    local n = obs_hom_ref + obs_het + obs_hom_alt
    if n == 0 then return nil end

    -- Calculate allele frequencies
    local aaf = (obs_het + 2 * obs_hom_alt) / (2 * n)
    local raf = 1.0 - aaf

    -- Expected counts under HWE
    local exp_hom_ref = (raf * raf) * n
    local exp_het = 2 * raf * aaf * n
    local exp_hom_alt = (aaf * aaf) * n

    -- Calculate chi-square components
    local x2 = 0
    if exp_hom_ref > 0 then x2 = x2 + ((obs_hom_ref - exp_hom_ref)^2) / exp_hom_ref end
    if exp_het > 0 then x2 = x2 + ((obs_het - exp_het)^2) / exp_het end
    if exp_hom_alt > 0 then x2 = x2 + ((obs_hom_alt - exp_hom_alt)^2) / exp_hom_alt end

    -- Calculate p-value
    return chi_square_p_value(x2)
end

function test_hwe_alts()
    -- Test case 1: Perfect HWE
    local gts1 = {
        {alts = 0}, {alts = 0}, {alts = 0}, {alts = 0}, -- 4 ref/ref
        {alts = 1}, {alts = 1}, {alts = 1}, {alts = 1}, -- 4 ref/alt
        {alts = 2}, {alts = 2}                          -- 2 alt/alt
    }
    local p1 = hwe_alts(gts1)
    assert(p1 > 0.05, "Expected HWE p-value > 0.05 for balanced case, got " .. p1)

    -- Test case 2: Strong deviation from HWE
    local gts2 = {
        {alts = 0}, {alts = 0},  -- 2 ref/ref
        {alts = 2}, {alts = 2},  -- 2 alt/alt
        {alts = 2}, {alts = 2}   -- No heterozygotes
    }
    local p2 = hwe_alts(gts2)
    assert(p2 < 0.05, "Expected HWE p-value < 0.05 for unbalanced case, got " .. p2)

    -- Test case 3: Empty input
    local gts3 = {}
    local p3 = hwe_alts(gts3)
    assert(p3 == nil, "Expected nil for empty genotypes")

    print("All HWE tests passed!")
end
