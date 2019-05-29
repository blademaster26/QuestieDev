QuestieNameplate = {};

local activeGUIDs = {};
local npFrames = {};
local npUnusedFrames = {};
local npFramesCount = 0;

QuestieNameplate.TimerSet = 0.5;


-- Initializer
function QuestieNameplate:Initialize()
    QuestieNameplate.GlobalFrame = CreateFrame("Frame");
    QuestieNameplate.GlobalFrame:SetScript("OnUpdate", QuestieNameplate.UpdateNameplate);

end

-- Frame Management
function QuestieNameplate:getFrame(guid)

    if npFrames[guid] and npFrames[guid] ~= nil then
        return npFrames[guid];
    end

    local parent = C_NamePlate.GetNamePlateForUnit(activeGUIDs[guid]);

    local frame = tremove(npUnusedFrames)

    if(not frame) then
        frame = CreateFrame("Frame");
        npFramesCount = npFramesCount + 1;
    end
    frame:SetFrameStrata("HIGH");
    frame:SetFrameLevel(10);
    frame:SetWidth(16)
    frame:SetHeight(16)
    frame:EnableMouse(false);
    frame:SetParent(parent);
    frame:SetPoint("LEFT", parent, -12, -7);

    frame.Icon = frame:CreateTexture(nil, "ARTWORK");
    frame.Icon:ClearAllPoints();
    frame.Icon:SetAllPoints(frame)


    npFrames[guid] = frame;

    return frame;
end

function QuestieNameplate:removeFrame(guid)
    if npFrames[guid] then
        table.insert(npUnusedFrames, npFrames[guid])
        npFrames[guid].Icon:SetTexture(nil); -- fix for overlapping icons
        npFrames[guid]:Hide();
        npFrames[guid] = nil;
    end
end


-- Event Handlers
function QuestieNameplate:NameplateCreated(token)
    -- to avoid memory issues
    if npFramesCount >= 300 then
        return
    end

    local unitGUID = UnitGUID(token);
    local unitName, _ = UnitName(token);

    if not unitGUID or not unitName then return end

    -- we only need to use put this over creatures.
    -- to avoid running this code over Pet, Player, etc.
    local unitType = strsplit("-", unitGUID);

    if unitType == "Creature" then

        if unitName then
            --[[
                Timer hack to account for delay in populating QuestieTooltips
                Without delay, if nameplates start off toggled, then they need to
                be toggled off and back on again or delay 2 seconds apperas instant
                on the client.  Only needs to be run once, controlled with Timer set.
            ]]
            C_Timer.After(QuestieNameplate.TimerSet, function()
                QuestieNameplate.TimerSet = 0;
                local toKill = QuestieTooltips.tooltipLookup["u_" .. unitName];

                if toKill and toKill[1] and toKill[1].Objective then
				    -- tooltips are now stored in sub tables to support more than 1 objective, quick fix
					local icon = toKill[1].Objective.Icon
					
                    activeGUIDs[unitGUID] = token;

                    local f = QuestieNameplate:getFrame(unitGUID);
                    f.Icon:SetTexture(icon)
                    f:Show();

                end
            end);
        end
    end
end

function QuestieNameplate:NameplateDestroyed(token)

    local unitGUID = UnitGUID(token);
    
    if activeGUIDs[unitGUID] then
        activeGUIDs[unitGUID] = nil;
        QuestieNameplate:removeFrame(unitGUID);
    end

end


function QuestieNameplate:UpdateNameplate(self)

    for k,v in pairs(activeGUIDs) do
        
        unitName, _ = UnitName(activeGUIDs[k]);

        if unitName == nil then return end

        local toKill = QuestieTooltips.tooltipLookup["u_" .. unitName];

        if toKill and toKill[1] and toKill[1].Objective then
			-- tooltips are now stored in sub tables to support more than 1 objective, quick fix
            if toKill[1].Objective.Completed or (tonumber(toKill[1].Objective.Needed) == tonumber(toKill[1].Objective.Collected) and tonumber(toKill[1].Objective.Needed) > 0) then
                activeGUIDs[k] = nil;
                QuestieNameplate:removeFrame(k);
			end
        end
    end
end