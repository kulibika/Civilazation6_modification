include("DiplomacyActionView_Expansion2.lua");

local BASE_PopulateStatementList = PopulateStatementList;
local BASE_MakeDeal_TestValid = MakeDeal_TestValid;

local m_TradedThisTurn = {};

function MakeDeal_TestValid(sessionID, otherPlayer)
    if m_TradedThisTurn[otherPlayer] == Game.GetCurrentGameTurn() then
        return false;
    end
    if BASE_MakeDeal_TestValid then
        return BASE_MakeDeal_TestValid(sessionID, otherPlayer);
    end
    return true;
end

StatementHandlers["MAKE_DEAL"].TestValid = MakeDeal_TestValid;

function PopulateStatementList(options, rootControl, isSubList)
    BASE_PopulateStatementList(options, rootControl, isSubList);
    local curTurn = Game.GetCurrentGameTurn();
    if m_TradedThisTurn[ms_SelectedPlayerID] == curTurn then
        local buttonIM = isSubList and g_ActionListIM or g_SubActionListIM;
        for i = 1, buttonIM.m_iAllocatedInstances do
            local instance = buttonIM:GetAllocatedInstance(i);
            if instance and instance.Button then
                local opt = options[i];
                if opt and opt.Key == "CHOICE_MAKE_DEAL" then
                    instance.Button:SetDisabled(true);
                    instance.Button:SetToolTipString(Locale.Lookup("LOC_DIPLO_DEAL_ALREADY_TRADED_TOOLTIP"));
                end
            end
        end
    end
end

function OnTradeDealEnacted()
    if ms_SelectedPlayerID and ms_SelectedPlayerID ~= -1 then
        m_TradedThisTurn[ms_SelectedPlayerID] = Game.GetCurrentGameTurn();
    end
end

Events.DiplomacyDealEnacted.Add(OnTradeDealEnacted);
