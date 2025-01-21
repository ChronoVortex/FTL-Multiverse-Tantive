----------------------
-- HELPER FUNCTIONS --
----------------------

local function vter(cvec)
    local i = -1
    local n = cvec:size()
    return function()
        i = i + 1
        if i < n then return cvec[i] end
    end
end

local function userdata_table(userdata, tableName)
    if not userdata.table[tableName] then userdata.table[tableName] = {} end
    return userdata.table[tableName]
end

local function string_starts(str, start)
    return string.sub(str, 1, string.len(start)) == start
end

local function should_track_achievement(achievement, ship, shipClassName)
    return ship and
           Hyperspace.App.world.bStartedGame and
           Hyperspace.CustomAchievementTracker.instance:GetAchievementStatus(achievement) < Hyperspace.Settings.difficulty and
           string_starts(ship.myBlueprint.blueprintName, shipClassName)
end

local function ship_has_breach(ship)
    for breach in vter(ship.ship:GetHullBreaches(false)) do
        if breach.fDamage > 0 then return true end
    end
    return false
end

local function count_crew_ship(shipId, countDrones)
    local count = 0
    for crew in vter(Hyperspace.CrewFactory.crewMembers) do
        if crew.iShipId == shipId and (crew.clone_ready or not crew.bDead) and (countDrones or not crew:IsDrone()) then
            count = count + 1
        end
    end
    return count
end

local function event_has_ship_unlock(event)
    if event.unlockShip > -1 then return true end
    --[[ Use in Multiverse release when HS 1.16.0 is available
    local customEvent = Hyperspace.CustomEventsParser.GetInstance():GetCustomEvent(event.eventName)
    if customEvent and string.len(customEvent.unlockShip) > 0 then return true end
    --]]
    return false
end

------------------
-- ACHIEVEMENTS --
------------------

-- We're Doomed! (Easy)
do
    local crewCountLastFrame = 0
    script.on_internal_event(Defines.InternalEvents.SHIP_LOOP, function(ship)
        if should_track_achievement("ACH_SHIP_CVX_TANTIVE_1", ship, "PLAYER_SHIP_CVX_TANTIVE") then
            local pVars = Hyperspace.playerVariables
            if pVars.loc_ach_ship_breached <= 0 and ship_has_breach(ship) then
                pVars.loc_ach_ship_breached = 1
            end
            if pVars.loc_ach_intruder_threshold <= 0 and ship.iIntruderCount >= 2 then
                pVars.loc_ach_intruder_threshold = 1
            end
            local crewCount = count_crew_ship(0)
            if pVars.loc_ach_crew_lost <= 0 and crewCount < crewCountLastFrame then
                pVars.loc_ach_crew_lost = 1
            end
            crewCountLastFrame = crewCount
        end
    end)
end
do
    local function check_should_reward(ship)
        if ship.iShipId == 0 then
            local pVars = Hyperspace.playerVariables
            if pVars.loc_ach_ship_breached > 0 and pVars.loc_ach_intruder_threshold > 0 and pVars.loc_ach_crew_lost <= 0 then
                Hyperspace.CustomAchievementTracker.instance:SetAchievement("ACH_SHIP_CVX_TANTIVE_1", false)
            end
        end
    end
    script.on_internal_event(Defines.InternalEvents.JUMP_LEAVE, check_should_reward)
    script.on_internal_event(Defines.InternalEvents.ON_WAIT, check_should_reward)
end
do
    local function reset_vars(ship)
        if ship.iShipId == 0 then
            Hyperspace.playerVariables.loc_ach_ship_breached = 0
            Hyperspace.playerVariables.loc_ach_intruder_threshold = 0
            Hyperspace.playerVariables.loc_ach_crew_lost = 0
        end
    end
    script.on_internal_event(Defines.InternalEvents.JUMP_ARRIVE, reset_vars)
    script.on_internal_event(Defines.InternalEvents.ON_WAIT, reset_vars)
end

-- Consular Ship (Medium)
script.on_internal_event(Defines.InternalEvents.POST_CREATE_CHOICEBOX, function(choiceBox, event)
    if should_track_achievement("ACH_SHIP_CVX_TANTIVE_2", Hyperspace.ships.player, "PLAYER_SHIP_CVX_TANTIVE") and event_has_ship_unlock(event) then
        Hyperspace.playerVariables.loc_ach_ship_unlock_count = Hyperspace.playerVariables.loc_ach_ship_unlock_count + 1
        if Hyperspace.playerVariables.loc_ach_ship_unlock_count >= 2 then
            Hyperspace.CustomAchievementTracker.instance:SetAchievement("ACH_SHIP_CVX_TANTIVE_2", false)
        end
    end
end)

-- Only You Could Be So Bold (Hard)
do
    local crewKilledByLeia = 0
    script.on_internal_event(Defines.InternalEvents.CREW_LOOP, function(crew)
        if should_track_achievement("ACH_SHIP_CVX_TANTIVE_3", Hyperspace.ships.player, "PLAYER_SHIP_CVX_TANTIVE") and crew.iShipId == 1 and userdata_table(crew, "mods.cvxTantive.crewStuff").validLeiaKill ~= false then
            local crewData = userdata_table(crew, "mods.cvxTantive.crewStuff")
            local crewShip = Hyperspace.ships(crew.currentShipId)
            for crewOther in vter(crewShip.vCrewList) do
                -- Check if the other crew member is currently controlled by the player and in the same room
                if (crewOther.iShipId == (crewOther.bMindControlled and 1 or 0)) and (crewOther.iRoomId == crew.iRoomId) then
                    crewData.validLeiaKill = crewOther.type == "cvx_unique_leia"
                end
            end
            if crewData.validLeiaKill and crew.health.first <= 0 then
                crewKilledByLeia = crewKilledByLeia + 1
                crewData.validLeiaKill = false
                if crewKilledByLeia >= 3 then
                     Hyperspace.CustomAchievementTracker.instance:SetAchievement("ACH_SHIP_CVX_TANTIVE_3", false)
                end
            end
        end
    end)
    do
        local function reset_var(ship)
            if ship.iShipId == 0 then crewKilledByLeia = 0 end
        end
        script.on_internal_event(Defines.InternalEvents.JUMP_LEAVE, reset_var)
        script.on_internal_event(Defines.InternalEvents.ON_WAIT, reset_var)
    end
end
