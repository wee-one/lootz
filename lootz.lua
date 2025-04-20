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
		showSummary = true,
		showPool = true,
		showPri = false,
		hideCommon = false,
		pri1Label = '1',
		pri2Label = '2',
		pri3Label = 'FL',
		pri4Label = 'FL',
		pri5Label = 'FL'
	};

local config = settings.load(defaultConfig);

--local tsTable = {}
-- library of colors
local red = {1.0, 0.0, 0.0, 1.0};
local yellow = {1.0, 1.0, 0.4, 1.0};
local green = {0.5, 1.0, 0.5, 1.0};
local purple = {0.7,0.5,1.0,1.0};
local gray = {1.0, 1.0, 1.0, 0.6};

-- /colors

--  formatting vars
local longestItem = 'lootz: ';
local longestSummary = '';
local iLen = 0;
local checkILen = 0;
local longestName = '';
local nLen = 0;
local checkNLen = 0;
local winner = '';
local lotSep = '';
local priSep = '';
local lotMask = '';
local dev_pri = false;
local commonCount = 0;
-- /formatting



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
	if (table.getn(pool) > 0 and config.showPool) then
		imgui.SetNextWindowBgAlpha(0.75);
		imgui.SetNextWindowSize({ windowSize, -1, }, ImGuiCond_Always);
		
		if (imgui.Begin('poolWindow', true, bit.bor(ImGuiWindowFlags_NoDecoration))) then

			-- testing
			--imgui.Text(tostring(table.getn(pool)) .. ' ' .. tostring(config.showSummary) .. ' ' .. tostring(config.showPool))

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
						if dev_pri and tools.prios[v.Name] == nil then tools.prios[v.Name] = 0 end;
						--imgui.Text(tostring(tools.prios[v.Name]) .. ' ' .. tostring(math.abs(mins-5)));
						if tonumber(tools.prios[v.Name]) == 1 then imgui.Text(config.pri1Label) end;
						if tonumber(tools.prios[v.Name]) == 2 then imgui.Text(config.pri2Label) end;
						if tonumber(tools.prios[v.Name]) == 3 then imgui.Text(config.pri3Label) end;
						if tonumber(tools.prios[v.Name]) == 4 then imgui.Text(config.pri4Label) end;
						if tonumber(tools.prios[v.Name]) >= 5 then imgui.Text(config.pri5Label) end;
					end;
					if v.item.WinningLot == 0 and math.abs(mins-5) > tools.prios[v.Name] then
						tools.prios[v.Name] = math.abs(mins-5)
					end;
				end;
			
			end;
		end;
	end;	
	-- history window
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
				-- print(table.concat(tools.getColor(v)))
				-- print(table.concat(gray))
				lootColor = tools.getColor(v);
				if  not config.hideCommon or (config.hideCommon and table.concat(lootColor) ~= table.concat(gray)) then

					imgui.TextColored(tools.getColor(v),v)
					imgui.SameLine();
					imgui.SetCursorPosX(imgui.CalcTextSize(longestSummary .. ': '));
					imgui.Text(' : ' ..tostring(tools.dropHistory[v]));
				end;
				-- count common
				if table.concat(lootColor) == table.concat(gray) then
					commonCount = commonCount+1;
				end;
			end;
			if config.hideCommon then
				imgui.Separator();
				imgui.TextColored(gray,'Hidden')
				imgui.SameLine();
				imgui.SetCursorPosX(imgui.CalcTextSize(longestSummary .. ': '));
				imgui.Text(' : '  .. tostring(commonCount))
				commonCount = 0;
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
		{ '/lootz showpool','Toggles visibility of loot pool window. On by default.' },
		{ '/lootz hidecommon','Toggles visibility of non-colored items in the history.' },
		{ '/lootz usepri','Shows a priority column in the treasure pool for dynamis gear. Helps with loot rules. 1 > 2 > FL' },
		{ '/lootz pri1Label','Changes the label for priority 1' },
		{ '/lootz pri2Label','Changes the label for priority 2' },
		{ '/lootz pri3Label','Changes the label for priority 3' },
		{ '/lootz pri4Label','Changes the label for priority 4' },
		{ '/lootz pri5Label','Changes the label for priority 5' },
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
	if (#args == 2 and args[2]:any('hideCommon')) then
       config.hideCommon = not config.hideCommon;

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
	if (#args == 3 and (args[2]:any('pri1label'))) then
       config.pri1Label = args[3];
		settings.save();
        return;
    end
	if (#args == 3 and (args[2]:any('pri2label'))) then
       config.pri2Label = args[3];
		settings.save();
        return;
    end
	if (#args == 3 and (args[2]:any('pri3label'))) then
       config.pri3Label = args[3];
		settings.save();
        return;
    end
	if (#args == 3 and (args[2]:any('pri4label'))) then
       config.pri4Label = args[3];
		settings.save();
        return;
    end
	if (#args == 3 and (args[2]:any('pri5label'))) then
       config.pri5Label = args[3];
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
