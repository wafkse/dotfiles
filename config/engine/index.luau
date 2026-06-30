local module_list = {
    "theme"
}

local export_table = {}

local function table_merge(target_table, source_table)
    if type(source_table) ~= "table" then return end

    for target_index, target_value in pairs(source_table) do
        if type(target_value) == "table" then
            if type(target_table[target_index]) ~= "table" then
                target_table[target_index] = {}
            end

            table_merge(target_table[target_index], target_value)
        else
            target_table[target_index] = target_value
        end
    end
end

for _, module_name in ipairs(module_list) do
    local require_success, target_module = pcall(require, module_name)

    if require_success and type(target_module) == "table" then
        table_merge(export_table, target_module)
    else
        warn("failed to load or invalid module structure for: " ..
            tostring(module_name))
    end
end

return export_table
