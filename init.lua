local function get_tile(tiles, n)
	local tile = tiles[n]
	if type(tile) == 'table' then
		return tile.name or tile.image
	end
	return tile
end

local function pairs_s(dict)
	local keys = {}
	for k in pairs(dict) do
		keys[#keys+1] = k
	end
	table.sort(keys)
	return ipairs(keys)
end

minetest.register_chatcommand("dumpnodes", {
	description = "Dump node and texture list for use with litematica",
	func = function()
		local ntbl = {}
		for _, nn in pairs_s(minetest.registered_nodes) do
			local prefix, name = nn:match('(.*):(.*)')
			if prefix == nil or name == nil then
				print("ignored(1): " .. nn)
			else
				if ntbl[prefix] == nil then
					ntbl[prefix] = {}
				end
				ntbl[prefix][name] = true
			end
		end
		local nodef, err = io.open(minetest.get_worldpath() .. "/nodes.lua", 'wb')
		if not nodef then
			return true, err
		end
		local texf, err = io.open(minetest.get_worldpath() .. "/textures.lua", 'wb')
		if not texf then
			return true, err
		end
        nodef:write("return {")
        texf:write("return {")
		local n = 0
		for _, prefix in pairs_s(ntbl) do
			for _, name in pairs_s(ntbl[prefix]) do
				local nn = prefix .. ":" .. name
				local nd = minetest.registered_nodes[nn]
				local tiles = nd.tiles or nd.tile_images
				if tiles == nil or nd.drawtype == 'airlike' then
					print("ignored(2): " .. nn)
				else
					local tex = get_tile(tiles, 1)
                    if tex == nil then
						minetest.log("error", dump(nd))
					end
					tex = (tex .. '^'):match('%(*(.-)%)*^') -- strip modifiers
					if tex:find("[combine", 1, true) then
						tex = tex:match('.-=([^:]-)') -- extract first texture
					end
					nodef:write('"' .. nn .. '",')
                    texf:write('"' .. tex .. '",')
					n = n + 1
				end
			end
		end
        texf:write("}\n")
        nodef:write("}\n")
		nodef:close()
        texf:close()
		return true, n .. " nodes dumped."
	end,
})
