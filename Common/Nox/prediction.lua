require("MapPositionGOS")

local myHero = myHero
local LocalHuge = math.huge
local LocalSqrt = math.sqrt
local LocalMax = math.max
local LocalMin = math.min
local LocalAbs = math.abs
local LocalFloor = math.floor
local LocalCos = math.cos
local LocalSin = math.sin

local TYPE_TURRET = Obj_Ai_Turret

local LocalLatency = Game.Latency
local LocalGameTimer = Game.Timer
local LocalMinionCount = Game.MinionCount
local LocalMinion = Game.Minion
local LocalHeroCount = Game.HeroCount
local LocalHero = Game.Hero

local TYPE_HERO = myHero.type

local TEAM_ALLY = myHero.team
local TEAM_JUNGLE = 300
local TEAM_ENEMY = 300 - TEAM_ALLY

local LocalMapPosition = MapPosition
local LocalPoint = Point
local LocalLineSegment = LineSegment

local ENEMY_BASE = nil
local ALLY_BASE = nil

TYPE_LINE = 1
TYPE_CIRCULAR = 2
TYPE_CONE = 3
TYPE_GENERIC = 4
TYPE_PRESS = 5
TYPE_TARGET = 6

local CCBuffs = {
    [5] = "Stun",
    [11] = "Snare",
    [24] = "Surppression",
    [39] = "KnockUp",
    [8] = "Taunt",
    [21] = "Fear",
    [22] = "Charm"
}

class "Prediction"

function Prediction:GetCCBuffData(unit)
    local GameTimer = LocalGameTimer()
    for i = 0, unit.buffCount do
        local Buff = unit:GetBuff(i)
        if Buff.count > 0 and GameTimer >= Buff.startTime and Buff.expireTime > GameTimer and CCBuffs[Buff.type] then
            return Buff
        end
    end
end

function Prediction:VectorMovementCollision(startPoint1, endPoint1, v1, startPoint2, v2, delay)
    local sP1x, sP1y, eP1x, eP1y, sP2x, sP2y =
        startPoint1.x,
        startPoint1.z,
        endPoint1.x,
        endPoint1.z,
        startPoint2.x,
        startPoint2.z
    local d, e = eP1x - sP1x, eP1y - sP1y
    local dist, t1, t2 = sqrt(d * d + e * e), nil, nil
    local S, K = dist ~= 0 and v1 * d / dist or 0, dist ~= 0 and v1 * e / dist or 0
    local function GetCollisionPoint(t)
        return t and {x = sP1x + S * t, y = sP1y + K * t} or nil
    end
    if delay and delay ~= 0 then
        sP1x, sP1y = sP1x + S * delay, sP1y + K * delay
    end
    local r, j = sP2x - sP1x, sP2y - sP1y
    local c = r * r + j * j
    if dist > 0 then
        if v1 == huge then
            local t = dist / v1
            t1 = v2 * t >= 0 and t or nil
        elseif v2 == huge then
            t1 = 0
        else
            local a, b = S * S + K * K - v2 * v2, -r * S - j * K
            if a == 0 then
                if b == 0 then --c=0->t variable
                    t1 = c == 0 and 0 or nil
                else --2*b*t+c=0
                    local t = -c / (2 * b)
                    t1 = v2 * t >= 0 and t or nil
                end
            else --a*t*t+2*b*t+c=0
                local sqr = b * b - a * c
                if sqr >= 0 then
                    local nom = sqrt(sqr)
                    local t = (-nom - b) / a
                    t1 = v2 * t >= 0 and t or nil
                    t = (nom - b) / a
                    t2 = v2 * t >= 0 and t or nil
                end
            end
        end
    elseif dist == 0 then
        t1 = 0
    end
    return t1, GetCollisionPoint(t1), t2, GetCollisionPoint(t2), dist
end

function Prediction:IsDashing(unit, spell)
    local delay, radius, speed, from = spell.Delay, spell.Radius, spell.Speed, spell.From.pos
    local OnDash, CanHit, Pos = false, false, nil
    local pathData = unit.pathing
    --
    if pathData.isDashing then
        local startPos = Vector(pathData.startPos)
        local endPos = Vector(pathData.endPos)
        local dashSpeed = pathData.dashSpeed
        local timer = Timer()
        local startT = timer - Latency() / 2000
        local dashDist = GetDistance(startPos, endPos)
        local endT = startT + (dashDist / dashSpeed)
        --
        if endT >= timer and startPos and endPos then
            OnDash = true
            --
            local t1, p1, t2, p2, dist =
                self:VectorMovementCollision(startPos, endPos, dashSpeed, from, speed, (timer - startT) + delay)
            t1, t2 =
                (t1 and 0 <= t1 and t1 <= (endT - timer - delay)) and t1 or nil,
                (t2 and 0 <= t2 and t2 <= (endT - timer - delay)) and t2 or nil
            local t = t1 and t2 and min(t1, t2) or t1 or t2
            --
            if t then
                Pos = t == t1 and Vector(p1.x, 0, p1.y) or Vector(p2.x, 0, p2.y)
                CanHit = true
            else
                Pos = Vector(endPos.x, 0, endPos.z)
                CanHit = (unit.ms * (delay + GetDistance(from, Pos) / speed - (endT - timer))) < radius
            end
        end
    end

    return OnDash, CanHit, Pos
end

function Prediction:IsImmobile(unit, spell)
    if unit.ms == 0 then
        return true, unit.pos, unit.pos
    end
    local delay, radius, speed, from = spell.Delay, spell.Radius, spell.Speed, spell.From.pos
    local debuff = {}
    for i = 1, unit.buffCount do
        local buff = unit:GetBuff(i)
        if buff.duration > 0 then
            local ExtraDelay = speed == huge and 0 or (GetDistance(from, unit.pos) / speed)
            if buff.expireTime + (radius / unit.ms) > Timer() + delay + ExtraDelay then
                debuff[buff.type] = true
            end
        end
    end
    if
        debuff[_STUN] or debuff[_TAUNT] or debuff[_SNARE] or debuff[_SLEEP] or debuff[_CHARM] or debuff[_SUPRESS] or
            debuff[_AIRBORNE]
     then
        return true, unit.pos, unit.pos
    end
    return false, unit.pos, unit.pos
end

function Prediction:IsSlowed(unit, spell)
    local delay, speed, from = spell.Delay, spell.Speed, spell.From.pos
    for i = 1, unit.buffCount do
        local buff = unit:GetBuff(i)
        if buff.type == _SLOW and buff.expireTime >= Timer() and buff.duration > 0 then
            if buff.expireTime > Timer() + delay + GetDistance(unit.pos, from) / speed then
                return true
            end
        end
    end
    return false
end

function Prediction:CalculateTargetPosition(unit, spell, tempPos)
    local delay, radius, speed, from = spell.Delay, spell.Radius, spell.Speed, spell.From
    local calcPos = nil
    local pathData = unit.pathing
    local pathCount = pathData.pathCount
    local pathIndex = pathData.pathIndex
    local pathEndPos = Vector(pathData.endPos)
    local pathPos = tempPos and tempPos or unit.pos
    local pathPot = (unit.ms * ((GetDistance(pathPos) / speed) + delay))
    local unitBR = unit.boundingRadius
    --
    if pathCount < 2 then
        local extPos = unit.pos:Extended(pathEndPos, pathPot - unitBR)
        --
        if GetDistance(unit.pos, extPos) > 0 then
            if GetDistance(unit.pos, pathEndPos) >= GetDistance(unit.pos, extPos) then
                calcPos = extPos
            else
                calcPos = pathEndPos
            end
        else
            calcPos = pathEndPos
        end
    else
        for i = pathIndex, pathCount do
            if unit:GetPath(i) and unit:GetPath(i - 1) then
                local startPos = i == pathIndex and unit.pos or unit:GetPath(i - 1)
                local endPos = unit:GetPath(i)
                local pathDist = GetDistance(startPos, endPos)
                --
                if unit:GetPath(pathIndex - 1) then
                    if pathPot > pathDist then
                        pathPot = pathPot - pathDist
                    else
                        local extPos = startPos:Extended(endPos, pathPot - unitBR)

                        calcPos = extPos

                        if tempPos then
                            return calcPos, calcPos
                        else
                            return self:CalculateTargetPosition(unit, spell, calcPos)
                        end
                    end
                end
            end
        end
        --
        if GetDistance(unit.pos, pathEndPos) > unitBR then
            calcPos = pathEndPos
        else
            calcPos = unit.pos
        end
    end

    calcPos = calcPos and calcPos or unit.pos

    if tempPos then
        return calcPos, calcPos
    else
        return self:CalculateTargetPosition(unit, spell, calcPos)
    end
end

function Prediction:GetPrediction(unit, spell)       
    local range = spell.Range and spell.Range - 15 or huge
    local radius = spell.Radius == 0 and 1 or (spell.Radius + unit.boundingRadius) - 4
    local speed = spell.Speed or huge
    local from = spell.From or myHero
    local delay = spell.Delay + (0.07 + Latency() / 2000)
    local collision = spell.Collision or false
    --
    local Position, CastPosition, HitChance = Vector(unit), Vector(unit), 0
    local TargetDashing, CanHitDashing, DashPosition = self:IsDashing(unit, spell)
    local TargetImmobile, ImmobilePos, ImmobileCastPosition = self:IsImmobile(unit, spell)

    if TargetDashing then
        if CanHitDashing then
            HitChance = 5
        else
            HitChance = 0
        end
        Position, CastPosition = DashPosition, DashPosition
    elseif TargetImmobile then
        Position, CastPosition = ImmobilePos, ImmobileCastPosition
        HitChance = 4
    else
        Position, CastPosition = self:CalculateTargetPosition(unit, spell)

        if unit.activeSpell and unit.activeSpell.valid then
            HitChance = 2
        end

        if GetDistanceSqr(from.pos, CastPosition) < 250 then
            HitChance = 2
            local newSpell = {Range = range, Delay = delay * 0.5, Radius = radius, Width = radius, Speed = speed *2, From = from}
            Position, CastPosition = self:CalculateTargetPosition(unit, newSpell)
        end

        local temp_angle = from.pos:AngleBetween(unit.pos, CastPosition)
        if temp_angle > 60 then
            HitChance = 1
        elseif temp_angle < 30 then
            HitChance = 2
        end
    end
    if GetDistanceSqr(from.pos, CastPosition) >= range * range then
        HitChance = 0                
    end
    if collision and HitChance > 0 then
        local newSpell = {Range = range, Delay = delay, Radius = radius * 2, Width = radius * 2, Speed = speed *2, From = from}
        if #(mCollision(from.pos, CastPosition, newSpell)) > 0 then
            HitChance = 0                    
        end
    end        
    
    return Position, CastPosition, HitChance
end
--[[
function Prediction:GetPrediction(unit, spellData)
    local Origin = unit.pos
    local Waypoint = unit.posTo
    if Waypoint.x == 0 or Waypoint.z == 0 then
        Waypoint = Origin
    end
    local Delay = spellData.Delay + (LocalLatency() / 2000)
    local Range = spellData.Range
    local Width = spellData.Width
    local Speed = spellData.Speed
    local sourcePos = spellData.from or myHero.pos
    local skillshotType = spellData.Type
    if skillshotType == TYPE_CIRCULAR then
        Range = Range + Width
    end
    local useHitBoxPrediction = self.useHitBoxPrediction

    local velocity = unit.ms
    local Direction = unit.dir
    local WPDirection = (Waypoint - Origin):Normalized()
    local dx, dz = Origin.x - sourcePos.x, Origin.z - sourcePos.z
    local Distance = LocalSqrt((dx * dx) + (dz * dz))
    local boundingRadius = unit.boundingRadius
    if skillshotType == 1 or skillshotType == 3 then
        Distance = (Distance + boundingRadius) - myHero.boundingRadius
    end
    local WPDistance = GetDistance(Origin, Waypoint)
    local vx, vz = (dx / WPDistance) * velocity, (dz / WPDistance) * velocity

    local TimeToHit = Delay

    if Speed < LocalHuge then
        if Origin ~= Waypoint then
            local a = (vx * vx) + (vz * vz) - (Speed * Speed)
            local b = 2 * (vx * (Origin.x - sourcePos.x) + vz * (Origin.z - sourcePos.z))
            local c =
                (Origin.x * Origin.x) + (Origin.z * Origin.z) + (sourcePos.x * sourcePos.x) +
                (sourcePos.z * sourcePos.z) -
                (2 * sourcePos.x * Origin.x) -
                (2 * sourcePos.z * Origin.z)
            local d = b * b - (4 * a * c)
            local t = 0
            if d >= 0 then
                d = LocalSqrt(d)
                local t1 = (-b + d) / (2 * a)
                local t2 = (-b - d) / (2 * a)
                t = LocalMin(t1, t2)
                if t < 0 then
                    t = LocalMax(t1, t2)
                end
            end
            TimeToHit = TimeToHit + t
        else
            TimeToHit = TimeToHit + (Distance / Speed)
        end
    end

    local MaxWalkDistance = (TimeToHit * unit.ms)
    local WalkDistance = MaxWalkDistance
    if MaxWalkDistance > WPDistance then
        WalkDistance = WPDistance
    end
    if useHitBoxPrediction then
        WalkDistance = LocalMax((MaxWalkDistance + 4) - ((boundingRadius + Width) * 0.5), 0)
    end
    local GameTimer = LocalGameTimer()
    local CastPos = Origin
    local TrueWidth = Width + boundingRadius

    local mod = 0.5
    if unit.type == TYPE_HERO then
        local Buff = self:GetCCBuffData(unit)
        if Buff then
            mod = mod + Buff.expireTime - GameTimer
            CastPos = Waypoint == Origin and Origin or Origin + WPDirection * WalkDistance
        else
            local ActiveSpell = unit.activeSpell
            if ActiveSpell.valid then
                if ActiveSpell.spellWasCast == false then
                    mod = mod + (ActiveSpell.castEndTime - GameTimer)
                elseif ActiveSpell.isChanneling then
                    mod = mod + (ActiveSpell.endTime - GameTimer)
                end
            end
        end
        if unit.visible == false then
            mod = 0
        end
    end
    if Origin ~= Waypoint then
        local line = LocalLineSegment(LocalPoint(Origin), LocalPoint(Waypoint))
        if LocalMapPosition:intersectsWall(line) then
            CastPos = Origin + Direction * WalkDistance
        else
            CastPos = Origin + WPDirection * WalkDistance
        end
    end

    return CastPos, sourcePos, GetDistanceSqr(sourcePos, CastPos) > Range * Range and 0 or
    LocalMin(LocalMax((TrueWidth / (WalkDistance == 0 and MaxWalkDistance or WalkDistance)) * mod, 0), 1)
end
--]]
