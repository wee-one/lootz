-- Based on the treasure pool addon.

addon.name = 'lootz'
addon.author = 'weeone'
addon.version = '0.1'

require 'common'
local imgui = require("imgui");
local settings = require('settings');
local tools = require('tools');
local chat = require('chat');
--local player = AshitaCore:GetMemoryManager():GetPlayer();

local defaultConfig = T{
		scale = 1,
		showSummary = false,
		showPool = true,
		showPri = false
	};

local config = settings.load(defaultConfig);

--local tsTable = {}
-- library of colors
local red = {1.0, 0.0, 0.0, 1.0};
local yellow = {1.0, 1.0, 0.4, 1.0};
local green = {0.5, 1.0, 0.5, 1.0};

-- /colors

--  formatting vars
local longestItem = 'lootz: ';
local longestSummary = '';
local iLen = 0;
local checkILen = 0;
local longestName = '';
local nLen = 0;
local checkNLen = 0;
--local str = row;
local winner = '';
local lotSep = '';
local priSep = '';
local lotMask = '';
local dev_pri = false;
-- /formatting

--local minDropTime = 0;


ashita.events.register('load', 'load_cb', function()

end);

ashita.events.register('d3d_present', 'present_cb', function ()
	
	local player = GetPlayerEntity();
	-- hide window
	if (player == nil) then -- when zoning
		return;
	end
	if string.match(tools.GetMenuName(), 'map') or string.match(tools.GetMenuName(), 'fulllog') then -- looking at map or log
		return; 
	end
	local pool = tools.getTreasurePool()
		
	-- determine formatting for loot table
	for k, v in pairs(pool) do
		--identify max item length
		checkILen = string.len(v.Name);
		if checkILen > iLen then
			iLen = checkILen;
			longestItem = v.Name;
		end;
		
		--identify max player name length with role result
		if v.item.WinningLot > 0 then
			lotSep = ' | ';
			lotMask = ' (999)';
			winner = ' | ' .. v.item.WinningEntityName .. " (" .. v.item.WinningLot ..") :";
			checkNLen = string.len(winner);
			if checkNLen > nLen then
				nLen = checkNLen;
				longestName = v.item.WinningEntityName;
			end
		end;
		-- if there is dynamis gear in the pool show ronin priority
		if (tools.prios[v.Name] ~= nill or dev_pri) and config.showPri then
			priSep = ' | ';
		end;
	end;
	-- treasure pool window
	-- to do: remove this from showsummary logic
	if (table.getn(pool) > 0 and config.showPool) then
		imgui.SetNextWindowBgAlpha(0.75);
		imgui.SetNextWindowSize({ windowSize, -1, }, ImGuiCond_Always);
		
		if (imgui.Begin('poolWindow', true, bit.bor(ImGuiWindowFlags_NoDecoration))) then
			-- resize text
			
			-- testing
			--imgui.Text(tostring(table.getn(pool)) .. ' ' .. tostring(config.showSummary) .. ' ' .. tostring(config.showPool))
			-- pool
			
			imgui.SetWindowFontScale(config.scale)
			-- table header
			if table.getn(pool) > 0 then
				imgui.Text('Loots: ')
				if lotSep ~= '' then -- someone rolled
					imgui.SameLine();
					imgui.SetCursorPosX(imgui.CalcTextSize('10:  ' .. longestItem));
					imgui.Text(' | Winner:');
				end;

				imgui.SameLine();
				imgui.SetCursorPosX(imgui.CalcTextSize('10:  ' .. longestItem .. lotSep .. longestName .. lotMask));
				imgui.Text(' | Time:');
				if priSep ~= '' then -- there is gear in the pool
					imgui.SameLine();
					imgui.SetCursorPosX(imgui.CalcTextSize('10:  ' .. longestItem .. lotSep .. longestName .. lotMask .. ' | 9:99 '));
					imgui.Text(' | Pri:');
				end;
				longestSummary = string.len(longestItem) > string.len(longestSummary) and longestItem or longestSummary; 
			end;
			for k, v in pairs(pool) do
				
				local timeRemaining = math.floor(tools.getTimeRemaining(v))
				local mins = math.floor(timeRemaining / 60);
				local secs = timeRemaining % 60;
				local strSecs = (secs < 10) and '0'..tostring(secs) or tostring(secs);
				local color = {}
				imgui.Text(k .. ':');
				imgui.SameLine();
				imgui.SetCursorPosX(imgui.CalcTextSize('10:  '));
				
				imgui.TextColored(tools.getColor(v.Name),v.Name)

				if lotSep ~= '' then
					imgui.SameLine();
					imgui.SetCursorPosX(imgui.CalcTextSize('10:  ' .. longestItem));
					imgui.Text(lotSep);
				end;
				if v.item.WinningLot > 0 then
					
					imgui.SameLine();
					imgui.SetCursorPosX(imgui.CalcTextSize('10:  ' .. longestItem .. lotSep));
					winner =  v.item.WinningEntityName .. " (" .. v.item.WinningLot ..") ";
					imgui.Text(winner);
					
				end;
				
				if timeRemaining < 30 then
					color = red
				elseif timeRemaining < 120 then
					color = yellow
				else
					color = green
				end
				imgui.SameLine();
				imgui.SetCursorPosX(imgui.CalcTextSize('10:  ' .. longestItem .. lotSep .. longestName .. lotMask));
				imgui.Text(' |');
				imgui.SameLine();
				imgui.TextColored(color,tostring(mins) .. ':' .. strSecs)
				
				if priSep ~= '' then
					imgui.SameLine();
					imgui.Text('| ');
				end;
				if tools.prios[v.Name] ~= nil or dev_pri then
					if priSep ~= '' then
					imgui.SameLine();
						if dev_pri then tools.prios[v.Name] = 0 end;
					
						if tonumber(tools.prios[v.Name]) > 2 then
							imgui.Text('FL');
						else
							imgui.Text(tostring(tools.prios[v.Name]));
						end;
					end;
					if v.item.WinningLot == 0 and math.abs(mins-5) > tools.prios[v.Name] then
						tools.prios[v.Name] = math.abs(mins-5)
					end;
				end;
			
			end;
		end;
	end;	
	if config.showSummary and table.getn(tools.dropList) > 0 then
		imgui.SetNextWindowBgAlpha(0.75);
		imgui.SetNextWindowSize({ windowSize, -1, }, ImGuiCond_Always);
		if (imgui.Begin('poolHistoryWindow', true, bit.bor(ImGuiWindowFlags_NoDecoration))) then
			imgui.SetWindowFontScale(config.scale)
			-- summary
			longestSummary = string.len(longestItem) > string.len(longestSummary) and longestItem or longestSummary; 
			imgui.Separator();
			imgui.Text('Loot Pool History:');
			imgui.Separator();
			table.sort(tools.dropList);
			for i, v in pairs(tools.dropList) do
				imgui.TextColored(tools.getColor(v),v)
				--imgui.Text(v)
				imgui.SameLine();
				imgui.SetCursorPosX(imgui.CalcTextSize(longestSummary .. ': '));
				imgui.Text(' : ' ..tostring(tools.dropHistory[v]));
			end;
		end
	end
	-- reset variables for next check.
	longestItem = 'lootz: ';
	longestName = '';
	lotSep = '';
	priSep = '';
	lotMask = '';
	iLen = 0;
	nLen = 0;

end);

local function print_help(isError)
    -- Print the help header..
    if (isError) then
        print(chat.header(addon.name):append(chat.error('Invalid command syntax for command: ')):append(chat.success('/' .. addon.name)));
    else
        print(chat.header(addon.name):append(chat.message('Available commands:')));
    end

    local cmds = T{
        { '/lootz help','Displays the addons help information.' },
		{ '/lootz scale xx','Sets the scale of the text 0 - 1.' },
		{ '/lootz showhistory or showsummary','Toggles visibility of treasure pool history. Off by default.' },
		{ '/lootz shopool','Toggles visibility of loot pool window. On by default.' },
		{ '/lootz usepri','Shows a priority column in the treasure pool for dynamis gear. Helps with loot rules. 1 > 2 > FL' },
		{ '/lootz reset','Clears the treasure pool history.' },
    };

    -- Print the command list..
    cmds:ieach(function (v)
        print(chat.header(addon.name):append(chat.error('Usage: ')):append(chat.message(v[1]):append(' - ')):append(chat.color1(6, v[2])));
    end);
end

ashita.events.register('command','command_cb', function (e)


     local args = e.command:args();
     if (#args == 0 or args[1] ~= '/lootz') then
        return;
    end
	
	if (#args == 2 and (args[2]:any('help'))) then
		print_help(false);
        return;
    end
	
	if (#args == 2 and args[2]:any('reset')) then
		tools.dropHistory = {};
		tools.dropList = {};
        return;
    end
	if (#args == 3 and args[2]:any('scale')) then
        config.scale = args[3]:number();

		settings.save();
        return;
    end
	if (#args == 2 and args[2]:any('showpool')) then
       config.showPool = not config.showPool;

		settings.save();
        return;
    end
	if (#args == 2 and (args[2]:any('showsummary') or args[2]:any('showhistory'))) then
       config.showSummary = not config.showSummary

		settings.save();
        return;
    end
	if (#args == 2 and (args[2]:any('usepri'))) then
       config.showPri = not config.showPri
		settings.save();
        return;
    end
 end);
 
 settings.register('settings', 'settings_update', function(s)
    -- Update the settings table..
    if (s ~= nil) then
        config = s;
    end

    -- Save the current settings..
    settings.save();
end);
