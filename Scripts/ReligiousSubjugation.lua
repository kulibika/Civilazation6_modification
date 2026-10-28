-- ===========================================================================
-- Resource Overhaul: Религиозная присяга (подчинение городов религией)
--
-- Город переходит к игроку, если одновременно:
--   1) ROS.TURNS_REQUIRED ходов подряд в городе преобладает религия, ОСНОВАННАЯ этим игроком;
--   2) Апостолы этого игрока провели в городе ROS.AGITATIONS_REQUIRED агитаций.
-- Столицы цивилизаций не переходят (города-государства — можно). Если религия в городе сменилась — оба счётчика сбрасываются.
--
-- Апостол может провести агитацию в городе, если стоит в его центре или на соседней клетке.
-- Агитация тратит все очки движения юнита. Лимит агитаций за жизнь юнита:
--   1 по умолчанию, 3 с карточкой POLICY_RO_PREACHERS, 5 с POLICY_RO_MISSION_ORDER.
-- ИИ: его Апостолы проводят агитацию автоматически в начале хода, если условия выполнены.
-- ===========================================================================

ROS = {
    TURNS_REQUIRED      = 15,
    AGITATIONS_REQUIRED = 5,
    RANGE               = 1,      -- 0 = только в центре города, 1 = центр + соседние клетки
    BASE_CHARGES        = 1,
    CHARGES_POLICY_1    = 3,
    CHARGES_POLICY_2    = 5,
    UNIT_TYPE           = "UNIT_APOSTLE",
    POLICY_1            = "POLICY_RO_PREACHERS",
    POLICY_2            = "POLICY_RO_MISSION_ORDER",

    -- ключи свойств
    P_UNIT_USED   = "RO_AGIT_USED",
    P_CITY_REL    = "RO_SUBJ_REL",
    P_CITY_TURNS  = "RO_SUBJ_TURNS",
    P_CITY_AGIT   = "RO_SUBJ_AGIT"
};

local function Log(msg) print("[RO Religion] " .. tostring(msg)); end

-- Защищена только столица цивилизации; город-государство (его единственный город
-- тоже считается столицей) и вольные города склонить можно.
-- В игровом (не UI) коде у объекта игрока нет метода "IsMajor", поэтому проверяем по списку цивилизаций
function ROS_IsMajorPlayer(iPlayer)
    for _, id in ipairs(PlayerManager.GetAliveMajorIDs()) do
        if id == iPlayer then return true end
    end
    return false;
end

-- В игровом коде у города нет метода "IsCapital", столицу ищем через GetCapitalCity()
function ROS_IsCapitalCity(pCity)
    local pOwner = Players[pCity:GetOwner()];
    if pOwner == nil then return false end
    local pCapital = pOwner:GetCities():GetCapitalCity();
    return pCapital ~= nil and pCapital:GetID() == pCity:GetID();
end

function ROS_IsProtectedCapital(pCity)
    if not ROS_IsCapitalCity(pCity) then return false end
    return ROS_IsMajorPlayer(pCity:GetOwner());
end

-- ---------------------------------------------------------------------------
-- Вспомогательные функции
-- ---------------------------------------------------------------------------
function ROS_GetFounderOfReligion(eReligion)
    if eReligion == nil or eReligion < 0 then return -1 end
    for _, iPlayer in ipairs(PlayerManager.GetAliveMajorIDs()) do
        local pRel = Players[iPlayer]:GetReligion();
        if pRel ~= nil and pRel:GetReligionTypeCreated() == eReligion then
            return iPlayer;
        end
    end
    return -1;
end

function ROS_GetMaxCharges(iPlayer)
    local pPlayer = Players[iPlayer];
    if pPlayer == nil then return ROS.BASE_CHARGES end
    local pCulture = pPlayer:GetCulture();
    local p2 = GameInfo.Policies[ROS.POLICY_2];
    local p1 = GameInfo.Policies[ROS.POLICY_1];
    if pCulture ~= nil then
        if p2 ~= nil and pCulture:IsPolicyActive(p2.Index) then return ROS.CHARGES_POLICY_2 end
        if p1 ~= nil and pCulture:IsPolicyActive(p1.Index) then return ROS.CHARGES_POLICY_1 end
    end
    return ROS.BASE_CHARGES;
end

function ROS_GetUsedCharges(pUnit)
    return pUnit:GetProperty(ROS.P_UNIT_USED) or 0;
end

function ROS_IsApostle(pUnit)
    local u = GameInfo.Units[pUnit:GetType()];
    return u ~= nil and u.UnitType == ROS.UNIT_TYPE;
end

-- Найти чужой город, в котором (или рядом с которым) стоит юнит
function ROS_FindTargetCity(pUnit)
    local ux, uy = pUnit:GetX(), pUnit:GetY();
    local owner = pUnit:GetOwner();
    local best = nil;
    for iPlayer = 0, 62 do
        local pPlayer = Players[iPlayer];
        if iPlayer ~= owner and pPlayer ~= nil and pPlayer:IsAlive() then
            for _, pCity in pPlayer:GetCities():Members() do
                if Map.GetPlotDistance(ux, uy, pCity:GetX(), pCity:GetY()) <= ROS.RANGE then
                    -- предпочитаем город, в центре которого стоим
                    if pCity:GetX() == ux and pCity:GetY() == uy then return pCity end
                    best = best or pCity;
                end
            end
        end
    end
    return best;
end

-- Можно ли провести агитацию: возвращает true или false, "причина"
function ROS_CanAgitate(pUnit)
    if pUnit == nil or not ROS_IsApostle(pUnit) then return false, "NOT_APOSTLE" end
    local owner = pUnit:GetOwner();
    if ROS_GetUsedCharges(pUnit) >= ROS_GetMaxCharges(owner) then return false, "NO_CHARGES" end
    if pUnit:GetMovesRemaining() <= 0 then return false, "NO_MOVES" end

    local pCity = ROS_FindTargetCity(pUnit);
    if pCity == nil then return false, "NO_CITY" end
    if ROS_IsProtectedCapital(pCity) then return false, "CAPITAL", pCity end

    local myReligion = Players[owner]:GetReligion():GetReligionTypeCreated();
    if myReligion == nil or myReligion < 0 then return false, "NO_RELIGION", pCity end
    local cityRel = pCity:GetReligion():GetMajorityReligion();
    if cityRel ~= myReligion then return false, "NOT_MAJORITY", pCity end
    if (pCity:GetProperty(ROS.P_CITY_AGIT) or 0) >= ROS.AGITATIONS_REQUIRED
        and (pCity:GetProperty(ROS.P_CITY_REL) or -1) == myReligion then
        return false, "AGIT_FULL", pCity
    end
    return true, "OK", pCity;
end

local function Notify(iPlayer, summary, message, x, y)
    if Players[iPlayer] == nil or not Players[iPlayer]:IsHuman() then return end
    local ok = false;
    if NotificationManager ~= nil and NotificationTypes ~= nil and NotificationTypes.USER_DEFINED_1 ~= nil then
        ok = pcall(NotificationManager.SendNotification, iPlayer, NotificationTypes.USER_DEFINED_1, message, summary, x, y);
    end
    if not ok then Log(summary .. " | " .. message); end
end

local function ResetCity(pCity)
    pCity:SetProperty(ROS.P_CITY_REL, nil);
    pCity:SetProperty(ROS.P_CITY_TURNS, nil);
    pCity:SetProperty(ROS.P_CITY_AGIT, nil);
end

-- ---------------------------------------------------------------------------
-- Передача города
-- ---------------------------------------------------------------------------
function ROS_TransferCity(pCity, iNewOwner)
    local x, y = pCity:GetX(), pCity:GetY();
    local iOldOwner = pCity:GetOwner();
    local cityName = Locale.Lookup(pCity:GetName());

    local ok, err = false, "CityManager.TransferCity отсутствует";
    if CityManager ~= nil and CityManager.TransferCity ~= nil then
        ok, err = pcall(CityManager.TransferCity, pCity, iNewOwner);
    end

    local pNew = CityManager.GetCityAt(x, y);
    if pNew ~= nil and pNew:GetOwner() == iNewOwner then
        ResetCity(pNew);
        Log("Город " .. cityName .. " перешёл от игрока " .. iOldOwner .. " к игроку " .. iNewOwner);
        Notify(iNewOwner, Locale.Lookup("LOC_RO_SUBJ_CITY_GAINED_SUMMARY", cityName),
               Locale.Lookup("LOC_RO_SUBJ_CITY_GAINED_MESSAGE", cityName), x, y);
        Notify(iOldOwner, Locale.Lookup("LOC_RO_SUBJ_CITY_LOST_SUMMARY", cityName),
               Locale.Lookup("LOC_RO_SUBJ_CITY_LOST_MESSAGE", cityName), x, y);
        return true;
    end

    Log("ОШИБКА: не удалось передать город " .. cityName .. " (pcall=" .. tostring(ok) .. ", err=" .. tostring(err) .. ")");
    Notify(iNewOwner, Locale.Lookup("LOC_RO_SUBJ_TRANSFER_FAILED_SUMMARY"),
           Locale.Lookup("LOC_RO_SUBJ_TRANSFER_FAILED_MESSAGE", cityName), x, y);
    return false;
end

function ROS_TryCapture(pCity)
    if pCity == nil or ROS_IsProtectedCapital(pCity) then return false end
    local eRel = pCity:GetProperty(ROS.P_CITY_REL);
    local turns = pCity:GetProperty(ROS.P_CITY_TURNS) or 0;
    local agit = pCity:GetProperty(ROS.P_CITY_AGIT) or 0;
    if eRel == nil or turns < ROS.TURNS_REQUIRED or agit < ROS.AGITATIONS_REQUIRED then return false end
    local iFounder = ROS_GetFounderOfReligion(eRel);
    if iFounder < 0 or iFounder == pCity:GetOwner() then return false end
    return ROS_TransferCity(pCity, iFounder);
end

-- ---------------------------------------------------------------------------
-- Агитация
-- ---------------------------------------------------------------------------
function ROS_DoAgitate(iPlayer, pUnit)
    local can, reason, pCity = ROS_CanAgitate(pUnit);
    if not can then
        Log("Агитация отклонена: " .. tostring(reason));
        -- Показываем причину над юнитом (только для человека)
        if Players[iPlayer] ~= nil and Players[iPlayer]:IsHuman() then
            local key = "LOC_RO_SUBJ_DISABLED_" .. tostring(reason);
            local txt = Locale.Lookup(key);
            if txt == key then txt = tostring(reason) end
            Game.AddWorldViewText(0, Locale.Lookup("LOC_RO_SUBJ_REJECTED", txt), pUnit:GetX(), pUnit:GetY());
        end
        return false;
    end

    local myReligion = Players[iPlayer]:GetReligion():GetReligionTypeCreated();
    -- если счётчик города принадлежал другой религии — начинаем заново
    if (pCity:GetProperty(ROS.P_CITY_REL) or -1) ~= myReligion then
        pCity:SetProperty(ROS.P_CITY_REL, myReligion);
        pCity:SetProperty(ROS.P_CITY_TURNS, 0);
        pCity:SetProperty(ROS.P_CITY_AGIT, 0);
    end

    local agit = (pCity:GetProperty(ROS.P_CITY_AGIT) or 0) + 1;
    pCity:SetProperty(ROS.P_CITY_AGIT, agit);
    pUnit:SetProperty(ROS.P_UNIT_USED, ROS_GetUsedCharges(pUnit) + 1);
    UnitManager.FinishMoves(pUnit);
    if UnitManager.ReportActivation ~= nil then pcall(UnitManager.ReportActivation, pUnit, "RO_AGITATE"); end

    local cityName = Locale.Lookup(pCity:GetName());
    local turns = pCity:GetProperty(ROS.P_CITY_TURNS) or 0;
    Game.AddWorldViewText(0, Locale.Lookup("LOC_RO_SUBJ_AGITATION_FLOAT", agit, ROS.AGITATIONS_REQUIRED),
                          pCity:GetX(), pCity:GetY());
    Notify(pCity:GetOwner(), Locale.Lookup("LOC_RO_SUBJ_AGITATED_SUMMARY", cityName),
           Locale.Lookup("LOC_RO_SUBJ_AGITATED_MESSAGE", cityName, agit, ROS.AGITATIONS_REQUIRED,
                         turns, ROS.TURNS_REQUIRED), pCity:GetX(), pCity:GetY());
    Log("Игрок " .. iPlayer .. " агитирует в " .. cityName .. ": " .. agit .. "/" .. ROS.AGITATIONS_REQUIRED
        .. ", ходов " .. turns .. "/" .. ROS.TURNS_REQUIRED);

    ROS_TryCapture(pCity);
    return true;
end

-- Команда из панели юнита (UnitManager.RequestCommand ... EXECUTE_SCRIPT)
function ROS_OnAgitateCommand(iPlayer, iUnitID)
    -- Через операцию игрока второй аргумент — таблица параметров
    if type(iUnitID) == "table" then iUnitID = iUnitID.unitID; end
    Log("Получена команда агитации: игрок " .. tostring(iPlayer) .. ", юнит " .. tostring(iUnitID));
    if iUnitID == nil then return end
    local pPlayer = Players[iPlayer];
    if pPlayer == nil then return end
    local pUnit = pPlayer:GetUnits():FindID(iUnitID);
    if pUnit == nil then return end
    ROS_DoAgitate(iPlayer, pUnit);
end

-- ---------------------------------------------------------------------------
-- Каждый ход: счётчик ходов с вашей религией
-- ---------------------------------------------------------------------------
function ROS_OnGameTurnStarted()
    for iPlayer = 0, 62 do
        local pPlayer = Players[iPlayer];
        if pPlayer ~= nil and pPlayer:IsAlive() then
            for _, pCity in pPlayer:GetCities():Members() do
                local eMaj = pCity:GetReligion():GetMajorityReligion();
                local iFounder = ROS_GetFounderOfReligion(eMaj);
                if iFounder >= 0 and iFounder ~= iPlayer and not ROS_IsProtectedCapital(pCity) then
                    if (pCity:GetProperty(ROS.P_CITY_REL) or -1) == eMaj then
                        pCity:SetProperty(ROS.P_CITY_TURNS, (pCity:GetProperty(ROS.P_CITY_TURNS) or 0) + 1);
                    else
                        pCity:SetProperty(ROS.P_CITY_REL, eMaj);
                        pCity:SetProperty(ROS.P_CITY_TURNS, 1);
                        pCity:SetProperty(ROS.P_CITY_AGIT, 0);
                    end
                    ROS_TryCapture(pCity);
                elseif pCity:GetProperty(ROS.P_CITY_REL) ~= nil then
                    ResetCity(pCity);
                end
            end
        end
    end
end

-- ---------------------------------------------------------------------------
-- ИИ: простая автоагитация в начале его хода
-- ---------------------------------------------------------------------------
function ROS_OnPlayerTurnActivated(iPlayer, bFirstTime)
    local pPlayer = Players[iPlayer];
    if pPlayer == nil or not pPlayer:IsAlive() or pPlayer:IsHuman() or not ROS_IsMajorPlayer(iPlayer) then return end
    for _, pUnit in pPlayer:GetUnits():Members() do
        if ROS_IsApostle(pUnit) then
            local can = ROS_CanAgitate(pUnit);
            if can then ROS_DoAgitate(iPlayer, pUnit); end
        end
    end
end

GameEvents.RO_AgitateCommand.Add(ROS_OnAgitateCommand);
GameEvents.RO_AgitateOperation.Add(ROS_OnAgitateCommand);
GameEvents.OnGameTurnStarted.Add(ROS_OnGameTurnStarted);
Events.PlayerTurnActivated.Add(ROS_OnPlayerTurnActivated);
-- Метка для интерфейса: игровой скрипт агитации загружен в этой игре
function ROS_MarkLoaded() Game:SetProperty("RO_SUBJ_SCRIPT_LOADED", 1); end
ROS_MarkLoaded();
if Events.LoadScreenClose ~= nil then Events.LoadScreenClose.Add(ROS_MarkLoaded); end
Log("Religious subjugation loaded");
