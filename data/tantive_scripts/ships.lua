local function distance(x1, y1, x2, y2)
     return math.sqrt((x2 - x1)^2 + (y2 - y1)^2)
end

-- Leia stun ability
script.on_internal_event(Defines.InternalEvents.ACTIVATE_POWER, function(power, ship)
    local crew = power.crew
    if crew.type == "cvx_unique_leia" then
        -- Find nearest enemy crew in the same room
        local crewTarget
        local dist = 2147483647
        for i = 0, ship.vCrewList:size() - 1 do
            local crewTargetPotential = ship.vCrewList[i]
            if (crewTargetPotential.iShipId ~= (crewTargetPotential.bMindControlled and 1 or 0)) and (crewTargetPotential.iRoomId == crew.iRoomId) then
                local thisDist = distance(crew.x, crew.y, crewTargetPotential.x, crewTargetPotential.y)
                if thisDist < dist then
                    dist = thisDist
                    crewTarget = crewTargetPotential
                end
            end
        end
        
        -- Stun found crew
        if crewTarget then
            crewTarget.fStunTime = math.max(crewTarget.fStunTime, 7)
        end
    end
end)
