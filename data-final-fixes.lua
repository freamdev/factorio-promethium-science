local threshold_level = settings.startup["promethium-infinite-research-threshold"].value
local continuation_suffix = "-promethium-continuation"

local function has_ingredient(unit, science_pack_name)
    for _, ingredient in pairs(unit.ingredients or {}) do
        local name = ingredient[1] or ingredient.name

        if name == science_pack_name then
            return true
        end
    end

    return false
end

local function get_ingredient_amount(unit, science_pack_name)
    for _, ingredient in pairs(unit.ingredients or {}) do
        local name = ingredient[1] or ingredient.name
        local amount = ingredient[2] or ingredient.amount

        if name == science_pack_name then
            return amount
        end
    end

    return nil
end

local function get_fallback_science_amount(unit)
    local highest_amount = 1

    for _, ingredient in pairs(unit.ingredients or {}) do
        local amount = ingredient[2] or ingredient.amount or 1

        if amount > highest_amount then
            highest_amount = amount
        end
    end

    return highest_amount
end

local function add_ingredient(unit, science_pack_name, amount)
    if has_ingredient(unit, science_pack_name) then
        return
    end

    table.insert(unit.ingredients, { science_pack_name, amount })
end

local function shift_count_formula(formula, offset)
    if not formula then
        return nil
    end

    return "(" .. string.gsub(formula, "%f[%a]L%f[%A]", "(L+" .. offset .. ")") .. ")"
end

for tech_name, tech in pairs(data.raw.technology) do
    if tech.max_level == "infinite"
        and tech.unit
        and tech.unit.ingredients
        and not string.find(tech_name, continuation_suffix, 1, true)
    then
        local promethium_amount =
            get_ingredient_amount(tech.unit, "space-science-pack")
            or get_fallback_science_amount(tech.unit)

        local continuation = table.deepcopy(tech)

        continuation.name = tech_name .. continuation_suffix
	continuation.localised_name = {
	    "",
	    tech.localised_name or {"technology-name." .. tech_name},
	    " (Promethium)"
	}
        continuation.localised_description = tech.localised_description or { "technology-description." .. tech_name }

        continuation.prerequisites = { tech_name }
        continuation.max_level = "infinite"
        continuation.upgrade = true
        continuation.hidden = false

        continuation.unit = table.deepcopy(tech.unit)

        add_ingredient(
            continuation.unit,
            "promethium-science-pack",
            promethium_amount
        )

        if tech.unit.count_formula then
            continuation.unit.count_formula = shift_count_formula(
                tech.unit.count_formula,
                threshold_level
            )
        end

        data:extend({ continuation })

        tech.max_level = threshold_level
        tech.upgrade = true

        log(
            "Promethium continuation generated for infinite technology: "
            .. tech_name
            .. " with promethium amount "
            .. promethium_amount
        )
    end
end