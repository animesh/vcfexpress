function set_id(variant)
    local alt = variant.ALT[1]
    variant.id = string.format("%s-%d-%s-%s", variant.chrom, variant.pos, variant.REF, alt)
    return true
end
