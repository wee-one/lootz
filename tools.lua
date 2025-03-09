require('common');

local tools = {};
local pGameMenu = ashita.memory.find('FFXiMain.dll', 0, "8B480C85C974??8B510885D274??3B05", 16, 0);
local lastDropTime = 0;
local minDropTime = 0;
local tsTable = {}
local red = {1.0, 0.0, 0.0, 1.0};
local yellow = {1.0, 1.0, 0.4, 1.0};
local orange = {1.0, 0.6, 0.0, 1.0};
local white = {1.0, 1.0, 1.0, 1.0};
local green = {0.5, 1.0, 0.5, 1.0};
local darkRed = {1.0, 0.3, 0.0, 1.0};
local darkOrange ={1.0, 0.4, 0.0, 1.0};
local briteYellow = {1.0, 1.0, 0.0, 1.0};
local blue = {0.4,0.7,0.9,1.0};
local gray = {1.0, 1.0, 1.0, 0.6};
local purple = {0.7,0.5,1.0,1.0};
local gold = {0.8,0.6,0.2,1.0};

tools.prios = {};
tools.dropHistory = {}; -- dropHistory[item.name] = dropCount
tools.dropList = {}; -- [index] = 'item.name' (used for sorting drop history by index)
tools.chosenColor = {};

tools.getColor = function(i)
	
	tools.chosenColor = gray;
	-- beast seals
	if (string.match(string.lower(i), "beastmen\'s seal") or 
	string.match(string.lower(i), "kindred\'s seal"))  

	then
		tools.chosenColor = green;
	end;
	-- hundred currency (dynamis)
	if (string.match(string.lower(i), "100 byne bill") or
		string.match(string.lower(i), "m. silverpiece") or
		string.match(string.lower(i), "l. jadeshell") 
	) then
		tools.chosenColor = gold;
	end;
	-- dynamis armor
	if (string.match(string.lower(i), "warrior\'s") or
		string.match(string.lower(i), "melee") or
		string.match(string.lower(i), "cleric\'s") or
		string.match(string.lower(i), "sorcerer\'s") or
		string.match(string.lower(i), "duelist\'s") or
		string.match(string.lower(i), "assassin\'s") or
		string.match(string.lower(i), "valor") or
		string.match(string.lower(i), "abyss") or
		string.match(string.lower(i), "monster") or
		string.match(string.lower(i), "bard\'s") or
		string.match(string.lower(i), "scout\'s") or
		string.match(string.lower(i), "sao.") or
		string.match(string.lower(i), "saotome") or
		string.match(string.lower(i), "koga") or
		string.match(string.lower(i), "wyrm") or
		string.match(string.lower(i), "summoner\'s") or
		string.match(string.lower(i), "mirage") or
		string.match(string.lower(i), "commodore") or
		string.match(string.lower(i), "comm.") or
		string.match(string.lower(i), "etoile") or
		string.match(string.lower(i), "argute") or
		string.match(string.lower(i), "bagua") or
		string.match(string.lower(i), "fathark") or
		string.match(string.lower(i), " %-1")
	) then
		tools.chosenColor = blue;
		if tools.prios[i] == nil then
			tools.prios[i] = 1;
		end;
	end;
	return tools.chosenColor;
end;

tools.dump = function(o)
	if type(o) == 'userdata' then
		return dump(getmetatable(o))
	end
	if type(o) == 'table' then
		local s = '{ '
		for k, v in pairs(o) do
			if type(k) ~= 'number' then
				k = '"' .. k .. '"'
			end
			s = s .. '[' .. k .. '] = ' .. dump(v) .. ','
		end
		return s .. '} '
	else
		return tostring(o)
	end
end

tools.compare = function(a, b)
	if a.item.DropTime == b.item.DropTime then
		return a.item.ItemId < b.item.ItemId
	else
		return a.item.DropTime < b.item.DropTime
	end
end

tools.getLen = function(table)
	local cnt = 0
	for _ in pairs(table) do
		cnt = cnt + 1
	end
	return cnt
end

tools.getTimeRemaining = function(item)
	if item ~= nil and item.item.DropTime ~= nil then
		local x = nil
		for k, v in pairs(tsTable) do
			if k == item.item.DropTime then
				x = v
			end
		end
		if x == nil then
			x = os.clock() + 299
			tsTable[item.item.DropTime] = x
		end
		return x - os.clock()
	else
		return -1
	end
end
tools.getTreasurePool = function()
	local pool = {};
	local resources = AshitaCore:GetResourceManager();
	local inventory = AshitaCore:GetMemoryManager():GetInventory()
	for i = 0, 9 do
		local titem = inventory:GetTreasurePoolItem(i);
		if titem ~= nil and titem.ItemId ~= nil then
			local rItem = resources:GetItemById(titem.ItemId)
			if (rItem ~= nil) then
				table.insert(pool, {
					Name = rItem.Name[1],
					item = titem,
				})
				-- count it for summary
				if minDropTime <= titem.DropTime then
					if tools.dropHistory[rItem.Name[1]] ~= nil then 
						tools.dropHistory[rItem.Name[1]] = tools.dropHistory[rItem.Name[1]] + 1;
					else
						tools.dropHistory[rItem.Name[1]] = 1;
						table.insert(tools.dropList, rItem.Name[1])
					end
						lastDropTime = lastDropTime < titem.DropTime and titem.DropTime or lastDropTime
				end
			end
			
			
		end
	end
	minDropTime = lastDropTime+1
	table.sort(pool, tools.compare)
	return pool
end
tools.GetMenuName = function()
    local subPointer = ashita.memory.read_uint32(pGameMenu);
    local subValue = ashita.memory.read_uint32(subPointer);
    if (subValue == 0) then
        return '';
    end
    local menuHeader = ashita.memory.read_uint32(subValue + 4);
    local menuName = ashita.memory.read_string(menuHeader + 0x46, 16);
    return string.gsub(menuName, '\x00', '');
end

return tools;