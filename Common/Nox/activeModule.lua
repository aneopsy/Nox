if _G.NOX_COMMON_LOADED then
    return
end
--
_G.NOX_COMMON_LOADED = true

require "MapPositionGOS"
require "DamageLib"
require "2DGeometry"

--[[
if FileExist(COMMON_PATH .. "Nox/Alpha.lua") then
	require 'Nox/Alpha'
else
	print("ERROR: Auto/Alpha.lua is not present in your Scripts/Common folder. Please re open loader.")
end
--]]

if not _G.SDK or not _G.SDK.TargetSelector then
	print("IC Orbwalker MUST be active in order to use this script.")
	return
end

--
local huge = math.huge
local pi = math.pi
local floor = math.floor
local ceil = math.ceil
local sqrt = math.sqrt
local max = math.max
local min = math.min
--
local lenghtOf = math.lenghtOf
local abs = math.abs
local deg = math.deg
local cos = math.cos
local sin = math.sin
local acos = math.acos
local atan = math.atan
--
local contains = table.contains
local insert = table.insert
local remove = table.remove
local sort = table.sort
--
local TEAM_JUNGLE = 300
local TEAM_ALLY = myHero.team
local TEAM_ENEMY = TEAM_JUNGLE - TEAM_ALLY
--
local _STUN = 5
local _TAUNT = 8
local _SLOW = 10
local _SNARE = 11
local _FEAR = 21
local _CHARM = 22
local _SUPRESS = 24
local _KNOCKUP = 29
local _KNOCKBACK = 30
--
local Vector = Vector
local KeyDown = Control.KeyDown
local KeyUp = Control.KeyUp
local IsKeyDown = Control.IsKeyDown
local SetCursorPos = Control.SetCursorPos
--
local GameCanUseSpell = Game.CanUseSpell
local Timer = Game.Timer
local Latency = Game.Latency
local HeroCount = Game.HeroCount
local Hero = Game.Hero
local MinionCount = Game.MinionCount
local Minion = Game.Minion
local TurretCount = Game.TurretCount
local Turret = Game.Turret
local WardCount = Game.WardCount
local Ward = Game.Ward
local ObjectCount = Game.ObjectCount
local Object = Game.Object
local MissileCount = Game.MissileCount
local Missile = Game.Missile
local ParticleCount = Game.ParticleCount
local Particle = Game.Particle
--
local DrawCircle = Draw.Circle
local DrawLine = Draw.Line
local DrawColor = Draw.Color
local DrawMap = Draw.CircleMinimap
local DrawText = Draw.Text
--
local barHeight = 8
local barWidth = 103
local barXOffset = 18
local barYOffset = 2

--<Interfaces Control>
if not SDK then
    local res, str = Game.Resolution(), "PLEASE ENABLE ICS ORBWALKER"
    Callback.Add(
        "Draw",
        function()
            DrawText(str, 64, res.x / 2 - (#str * 14), res.y / 2, DrawColor(255, 255, 0, 0))
        end
    )
    return
end
local _ENV = _G
local SDK = _G.SDK
local Orbwalker = SDK.Orbwalker
local ObjectManager = SDK.ObjectManager
local TargetSelector = SDK.TargetSelector
local HealthPrediction = SDK.HealthPrediction
--local Prediction     = Pred --Wont work cuz its being initialized before the class
--</Interfaces Control>

--<IOrbwalker>

local function GetMode() --1:Combo|2:Harass|3:LaneClear|4:JungleClear|5:LastHit|6:Flee
    local modes = Orbwalker.Modes
    for i = 0, #modes do
        if modes[i] then
            return i + 1
        end
    end
    return nil
end

local function GetMinions(range)
    return ObjectManager:GetMinions(range)
end

local function GetAllyMinions(range)
    return ObjectManager:GetAllyMinions(range)
end

local function GetEnemyMinions(range)
    return ObjectManager:GetEnemyMinions(range)
end

local function GetMonsters(range)
    return ObjectManager:GetMonsters(range)
end

local function GetHeroes(range)
    return ObjectManager:GetHeroes(range)
end

local function GetAllyHeroes(range)
    return ObjectManager:GetAllyHeroes(range)
end

local function GetEnemyHeroes(range)
    return ObjectManager:GetEnemyHeroes(range)
end

local function GetTurrets(range)
    return ObjectManager:GetTurrets(range)
end

local function GetAllyTurrets(range)
    return ObjectManager:GetAllyTurrets(range)
end

local function GetEnemyTurrets(range)
    return ObjectManager:GetEnemyTurrets(range)
end

local function GetWards(range)
    return ObjectManager:GetOtherMinions(range)
end

local function GetAllyWards(range)
    return ObjectManager:GetOtherAllyMinions(range)
end

local function GetEnemyWards(range)
    return ObjectManager:GetOtherEnemyMinions(range)
end

local function OnPreMovement(fn)
    Orbwalker:OnPreMovement(fn)
end

local function OnPreAttack(fn)
    Orbwalker:OnPreAttack(fn)
end

local function OnAttack(fn)
    Orbwalker:OnAttack(fn)
end

local function OnPostAttack(fn)
    Orbwalker:OnPostAttack(fn)
end

local function SetMovement(bool)
    Orbwalker:SetMovement(bool)
end

local function SetAttack(bool)
    Orbwalker:SetAttack(bool)
end

local function GetTarget(range, mode) --0:Physical|1:Magical|2:True
    return TargetSelector:GetTarget(range or huge, mode or 0)
end

local function ResetAutoAttack()
    Orbwalker:__OnAutoAttackReset()
end

local function Orbwalk()
    Orbwalker:Orbwalk()
end

local function SetHoldRadius(value)
    Orbwalker.Menu.General.HoldRadius:Value(value)
end

local function SetMovementDelay(value)
    Orbwalker.Menu.General.MovementDelay:Value(value)
end

local function ForceTarget(unit)
    Orbwalker.ForceTarget = unit
end

local function ForceMovement(pos)
    Orbwalker.ForceMovement = pos
end

local function GetHealthPrediction(unit, delay)
    return HealthPrediction:GetPrediction(unit, delay)
end

--</IOrbwalker>

local function TextOnScreen(str)
    local res = Game.Resolution()
    Callback.Add(
        "Draw",
        function()
            DrawText(str, 64, res.x / 2 - (#str * 10), res.y / 2, DrawColor(255, 255, 0, 0))
        end
    )
end

local function Ready(spell)
    return GameCanUseSpell(spell) == 0
end

local function RotateAroundPoint(v1, v2, angle)
    local cos, sin = cos(angle), sin(angle)
    local x = ((v1.x - v2.x) * cos) - ((v1.z - v2.z) * sin) + v2.x
    local z = ((v1.z - v2.z) * cos) + ((v1.x - v2.x) * sin) + v2.z
    return Vector(x, v1.y, z or 0)
end

local function GetDistanceSqr(p1, p2)
    p2 = p2 or myHero
    p1 = p1.pos or p1
    p2 = p2.pos or p2

    local dx, dz = p1.x - p2.x, p1.z - p2.z
    return dx * dx + dz * dz
end

local function GetDistance(p1, p2)
    return sqrt(GetDistanceSqr(p1, p2))
end

local ItemHotKey = {
    [ITEM_1] = HK_ITEM_1,
    [ITEM_2] = HK_ITEM_2,
    [ITEM_3] = HK_ITEM_3,
    [ITEM_4] = HK_ITEM_4,
    [ITEM_5] = HK_ITEM_5,
    [ITEM_6] = HK_ITEM_6,
    [ITEM_7] = HK_ITEM_7
}
local function GetItemSlot(id) --returns Slot, HotKey
    for i = ITEM_1, ITEM_7 do
        if myHero:GetItemData(i).itemID == id then
            return i, ItemHotKey[i]
        end
    end
    return 0
end

local wardItemIDs = {3340, 2049, 2301, 2302, 2303, 3711}
local function GetWardSlot() --returns Slot, HotKey
    for i = 1, #wardItemIDs do
        local ward, key = GetItemSlot(wardItemIDs[i])
        if ward ~= 0 then
            return ward, key
        end
    end
end

local rotateAngle = 0
local function DrawMark(pos, thickness, size, color)
    rotateAngle = (rotateAngle + 2) % 720
    local hPos, thickness, color, size =
        pos or myHero.pos,
        thickness or 3,
        color or DrawColor(255, 255, 0, 0),
        size * 2 or 150
    local offset, rotateAngle, mod = hPos + Vector(0, 0, size), rotateAngle / 360 * pi, 240 / 360 * pi
    local points = {
        hPos:To2D(),
        RotateAroundPoint(offset, hPos, rotateAngle):To2D(),
        RotateAroundPoint(offset, hPos, rotateAngle + mod):To2D(),
        RotateAroundPoint(offset, hPos, rotateAngle + 2 * mod):To2D()
    }
    --
    for i = 1, #points do
        for j = 1, #points do
            local lambda =
                i ~= j and
                DrawLine(points[i].x - 3, points[i].y - 5, points[j].x - 3, points[j].y - 5, thickness, color) -- -3 and -5 are offsets (because ext)
        end
    end
end

local function DrawRectOutline(vec1, vec2, width, color)
    local vec3, vec4 = vec2 - vec1, vec1 - vec2
    local A = (vec1 + (vec3:Perpendicular2():Normalized() * width)):To2D()
    local B = (vec1 + (vec3:Perpendicular():Normalized() * width)):To2D()
    local C = (vec2 + (vec4:Perpendicular2():Normalized() * width)):To2D()
    local D = (vec2 + (vec4:Perpendicular():Normalized() * width)):To2D()

    DrawLine(A, B, 3, color)
    DrawLine(B, C, 3, color)
    DrawLine(C, D, 3, color)
    DrawLine(D, A, 3, color)
end

local function VectorPointProjectionOnLineSegment(v1, v2, v)
    local cx, cy, ax, ay, bx, by = v.x, v.z, v1.x, v1.z, v2.x, v2.z
    local rL = ((cx - ax) * (bx - ax) + (cy - ay) * (by - ay)) / ((bx - ax) * (bx - ax) + (by - ay) * (by - ay))
    local pointLine = {x = ax + rL * (bx - ax), z = ay + rL * (by - ay)}
    local rS = rL < 0 and 0 or (rL > 1 and 1 or rL)
    local isOnSegment = rS == rL
    local pointSegment = isOnSegment and pointLine or {x = ax + rS * (bx - ax), z = ay + rS * (by - ay)}
    return pointSegment, pointLine, isOnSegment
end

local function mCollision(pos1, pos2, spell, list) --returns a table with minions (use #table to get count)
    local result, speed, width, delay, list = {}, spell.Speed, spell.Width + 65, spell.Delay, list
    --
    if not list then
        list = GetEnemyMinions(max(GetDistance(pos1), GetDistance(pos2)) + spell.Range + 100)
    end
    --
    for i = 1, #list do
        local m = list[i]
        local pos3 = delay and m:GetPrediction(speed, delay) or m.pos
        if
            m and m.team ~= TEAM_ALLY and m.dead == false and m.isTargetable and
                GetDistanceSqr(pos1, pos2) > GetDistanceSqr(pos1, pos3)
         then
            local pointSegment, pointLine, isOnSegment = VectorPointProjectionOnLineSegment(pos1, pos2, pos3)
            if isOnSegment and GetDistanceSqr(pointSegment, pos3) < width * width then
                result[#result + 1] = m
            end
        end
    end
    return result
end

local function hCollision(pos1, pos2, spell, list) --returns a table with heroes (use #table to get count)
    local result, speed, width, delay, list = {}, spell.Speed, spell.Width + 65, spell.Delay, list
    if not list then
        list = GetEnemyHeroes(max(GetDistance(pos1), GetDistance(pos2)) + spell.Range + 100)
    end
    for i = 1, #list do
        local h = list[i]
        local pos3 = delay and h:GetPrediction(speed, delay) or h.pos
        if
            h and h.team ~= TEAM_ALLY and h.dead == false and h.isTargetable and
                GetDistanceSqr(pos1, pos2) > GetDistanceSqr(pos1, pos3)
         then
            local pointSegment, pointLine, isOnSegment = VectorPointProjectionOnLineSegment(pos1, pos2, pos3)
            if isOnSegment and GetDistanceSqr(pointSegment, pos3) < width * width then
                insert(result, h)
            end
        end
    end
    return result
end

local function HealthPercent(unit)
    return unit.maxHealth > 5 and unit.health / unit.maxHealth * 100 or 100
end

local function ManaPercent(unit)
    return unit.maxMana > 0 and unit.mana / unit.maxMana * 100 or 100
end

local function HasBuffOfType(unit, bufftype, delay) --returns bool and endtime , why not starting at buffCOunt and check back to 1 ?
    local delay = delay or 0
    local bool = false
    local endT = Timer()
    for i = 1, unit.buffCount do
        local buff = unit:GetBuff(i)
        if buff.type == bufftype and buff.expireTime >= Timer() and buff.duration > 0 then
            if buff.expireTime > endT then
                bool = true
                endT = buff.expireTime
            end
        end
    end
    return bool, endT
end

local function HasBuff(unit, buffname) --returns bool
    return GotBuff(unit, buffname) == 1
end

local function GetBuffByName(unit, buffname) --returns buff
    return GetBuffData(unit, buffname)
end

local function GetBuffByType(unit, bufftype) --returns buff
    for i = 1, unit.buffCount do
        local buff = unit:GetBuff(i)
        if buff.type == bufftype and buff.expireTime >= Timer() and buff.duration > 0 then
            return buff
        end
    end
    return nil
end

local UndyingBuffs = {
    ["Aatrox"] = function(target, addHealthCheck)
        return HasBuff(target, "aatroxpassivedeath")
    end,
    ["Fiora"] = function(target, addHealthCheck)
        return HasBuff(target, "FioraW")
    end,
    ["Tryndamere"] = function(target, addHealthCheck)
        return HasBuff(target, "UndyingRage") and (not addHealthCheck or target.health <= 30)
    end,
    ["Vladimir"] = function(target, addHealthCheck)
        return HasBuff(target, "VladimirSanguinePool")
    end
}

local function HasUndyingBuff(target, addHealthCheck)
    --Self Casts Only
    local buffCheck = UndyingBuffs[target.charName]
    if buffCheck and buffCheck(target, addHealthCheck) then
        return true
    end
    --Can Be Casted On Others
    if
        HasBuff(target, "JudicatorIntervention") or
            ((not addHealthCheck or HealthPercent(target) <= 10) and
                (HasBuff(target, "kindredrnodeathbuff") or HasBuff(target, "ChronoShift") or
                    HasBuff(target, "chronorevive")))
     then
        return true
    end
    return target.isImmortal
end

local function IsValidTarget(unit, range) -- the == false check is faster than using "not"
    return unit and unit.valid and unit.visible and not unit.dead and unit.isTargetableToTeam and
        (not range or GetDistance(unit) <= range) and
        (not unit.type == myHero.type or not HasUndyingBuff(unit, true))
end

local function GetTrueAttackRange(unit, target)
    local extra = target and target.boundingRadius or 0
    return unit.range + unit.boundingRadius + extra
end

local function HeroesAround(range, pos, team)
    pos = pos or myHero.pos
    local dist = GetDistance(pos) + range + 100
    local result = {}
    local heroes =
        (team == TEAM_ENEMY and GetEnemyHeroes(dist)) or (team == TEAM_ALLY and GetAllyHeroes(dist) or GetHeroes(dist))
    for i = 1, #heroes do
        local h = heroes[i]
        if GetDistance(pos, h.pos) <= range then
            result[#result + 1] = h
        end
    end
    return result
end

local function CountEnemiesAround(pos, range)
    return #HeroesAround(range, pos, TEAM_ENEMY)
end

local function GetClosestEnemy(unit)
    local unit = unit or myHero
    local closest, list = nil, GetHeroes()
    for i = 1, #list do
        local enemy = list[i]
        if
            IsValidTarget(enemy) and enemy.team ~= unit.team and
                (not closest or GetDistance(enemy, unit) < GetDistance(closest, unit))
         then
            closest = enemy
        end
    end
    return closest
end

local function MinionsAround(range, pos, team)
    pos = pos or myHero.pos
    local dist = GetDistance(pos) + range + 100
    local result = {}
    local minions =
        (team == TEAM_ENEMY and GetEnemyMinions(dist)) or
        (team == TEAM_ALLY and GetAllyMinions(dist) or GetMinions(dist))
    for i = 1, #minions do
        local m = minions[i]
        if m and not m.dead and GetDistance(pos, m.pos) <= range + m.boundingRadius then
            result[#result + 1] = m
        end
    end
    return result
end

local function IsUnderTurret(pos, team)
    local turrets = GetTurrets(GetDistance(pos) + 1000)
    for i = 1, #turrets do
        local turret = turrets[i]
        if GetDistance(turret, pos) <= 915 and turret.team == team then
            return turret
        end
    end
end

local function GetDanger(pos)
    local result = 0
    --
    local turret = IsUnderTurret(pos, TEAM_ENEMY)
    if turret then
        result = result + floor((915 - GetDistance(turret, pos)) / 17.3)
    end
    --
    local nearby = HeroesAround(700, pos, TEAM_ENEMY)
    for i = 1, #nearby do
        local enemy = nearby[i]
        local dist, mod = GetDistance(enemy, pos), enemy.range < 350 and 2 or 1
        result = result + (dist <= GetTrueAttackRange(enemy) and 5 or 0) * mod
    end
    --
    result = result + #HeroesAround(400, pos, TEAM_ENEMY) * 1
    return result
end

local function IsImmobile(unit, delay)
    if unit.ms == 0 then
        return true, unit.pos, unit.pos
    end
    local delay = delay or 0
    local debuff, timeCheck = {}, Timer() + delay
    for i = 1, unit.buffCount do
        local buff = unit:GetBuff(i)
        if buff.expireTime >= timeCheck and buff.duration > 0 then
            debuff[buff.type] = true
        end
    end
    if
        debuff[_STUN] or debuff[_TAUNT] or debuff[_SNARE] or debuff[_SLEEP] or debuff[_CHARM] or debuff[_SUPRESS] or
            debuff[_AIRBORNE]
     then
        return true
    end
end

local function IsFacing(unit, p2)
    p2 = p2 or myHero
    p2 = p2.pos or p2
    local V = unit.pos - p2
    local D = unit.dir
    local Angle = 180 - deg(acos(V * D / (V:Len() * D:Len())))
    if abs(Angle) < 80 then
        return true
    end
end

local function CheckHandle(tbl, handle)
    for i = 1, #tbl do
        local v = tbl[i]
        if handle == v.handle then
            return v
        end
    end
end

local function GetTargetByHandle(handle)
    return CheckHandle(GetEnemyHeroes(1200), handle) or CheckHandle(GetMonsters(1200), handle) or
        CheckHandle(GetEnemyTurrets(1200), handle) or
        CheckHandle(GetEnemyMinions(1200), handle) or
        CheckHandle(GetEnemyWards(1200), handle)
end

local function ShouldWait()
    return myHero.dead or HasBuff(myHero, "recall") or Game.IsChatOpen() or
        (ExtLibEvade and ExtLibEvade.Evading == true)
end

local Emote = {
    Joke = HK_ITEM_1,
    Taunt = HK_ITEM_2,
    Dance = HK_ITEM_3,
    Mastery = HK_ITEM_5,
    Laugh = HK_ITEM_7,
    Casting = false
}

local function CastEmote(emote)
    if not emote or Emote.Casting or myHero.attackData.state == STATE_WINDUP then
        return
    end
    --
    Emote.Casting = true
    KeyDown(HK_LUS)
    KeyDown(emote)
    DelayAction(
        function()
            KeyUp(emote)
            KeyUp(HK_LUS)
            Emote.Casting = false
        end,
        0.01
    )
end

-- Farm Stuff

local function ExcludeFurthest(average, lst, sTar)
    local removeID = 1
    for i = 2, #lst do
        if GetDistanceSqr(average, lst[i].pos) > GetDistanceSqr(average, lst[removeID].pos) then
            removeID = i
        end
    end

    local Newlst = {}
    for i = 1, #lst do
        if (sTar and lst[i].networkID == sTar.networkID) or i ~= removeID then
            Newlst[#Newlst + 1] = lst[i]
        end
    end
    return Newlst
end

local function GetBestCircularCastPos(spell, sTar, lst)
    local average = {x = 0, z = 0, count = 0}
    local heroList = lst and lst[1] and (lst[1].type == myHero.type)
    local range = spell.Range or 2000
    local radius = spell.Radius or 50
    if sTar and (not lst or #lst == 0) then
        return Prediction:GetPrediction(sTar, spell), 1
    end
    --
    for i = 1, #lst do
        if IsValidTarget(lst[i], range) then
            local org = heroList and Prediction:GetPrediction(lst[i], spell) or lst[i].pos
            average.x = average.x + org.x
            average.z = average.z + org.z
            average.count = average.count + 1
        end
    end
    --
    if sTar and sTar.type ~= lst[1].type then
        local org = heroList and Prediction:GetPrediction(sTar, spell) or lst[i].pos
        average.x = average.x + org.x
        average.z = average.z + org.z
        average.count = average.count + 1
    end
    --
    average.x = average.x / average.count
    average.z = average.z / average.count
    --
    local inRange = 0
    for i = 1, #lst do
        local bR = lst[i].boundingRadius
        if GetDistanceSqr(average, lst[i].pos) - bR * bR < radius * radius then
            inRange = inRange + 1
        end
    end
    --
    local point = Vector(average.x, myHero.pos.y, average.z)
    --
    if inRange == #lst then
        return point, inRange
    else
        return GetBestCircularCastPos(spell, sTar, ExcludeFurthest(average, lst))
    end
end

local function GetBestLinearCastPos(spell, sTar, list)
    startPos = spell.From.pos or myHero.pos
    local isHero = list[1].type == myHero.type
    --
    local center = GetBestCircularCastPos(spell, sTar, list)
    local endPos = startPos + (center - startPos):Normalized() * spell.Range
    local MostHit = isHero and #hCollision(startPos, endPos, spell, list) or #mCollision(startPos, endPos, spell, list)
    return endPos, MostHit
end

local function GetBestLinearFarmPos(spell)
    local minions = GetEnemyMinions(spell.Range + spell.Radius)
    if #minions == 0 then
        return nil, 0
    end
    return GetBestLinearCastPos(spell, nil, minions)
end

local function GetBestCircularFarmPos(spell)
    local minions = GetEnemyMinions(spell.Range + spell.Radius)
    if #minions == 0 then
        return nil, 0
    end
    return GetBestCircularCastPos(spell, nil, minions)
end

local function CircleCircleIntersection(c1, c2, r1, r2)
    local D = GetDistance(c1, c2)
    if D > r1 + r2 or D <= abs(r1 - r2) then
        return nil
    end
    local A = (r1 * r2 - r2 * r1 + D * D) / (2 * D)
    local H = sqrt(r1 * r1 - A * A)
    local Direction = (c2 - c1):Normalized()
    local PA = c1 + A * Direction
    local S1 = PA + H * Direction:Perpendicular()
    local S2 = PA - H * Direction:Perpendicular()
    return S1, S2
end

class "Spell"

function Spell:__init(SpellData)
    self.Slot = SpellData.Slot
    self.Range = SpellData.Range or huge
    self.Delay = SpellData.Delay or 0.25
    self.Speed = SpellData.Speed or huge
    self.Radius = SpellData.Radius or SpellData.Width or 0
    self.Width = SpellData.Width or SpellData.Radius or 0
    self.From = SpellData.From or myHero
    self.Collision = SpellData.Collision or false
    self.Type = SpellData.Type or TYPE_PRESS
    --
    return self
end

function Spell:SetRange(value)
    self.Range = value
end

function Spell:SetRadius(value)
    self.Radius = value
end

function Spell:SetSpeed(value)
    self.Speed = value
end

function Spell:SetFrom(value)
    self.From = value
end

function Spell:IsReady()
    return GameCanUseSpell(self.Slot) == READY
end

function Spell:CanCast(unit, range, from)
    local from = from or self.From.pos
    local range = range or self.Range
    return unit and unit.valid and unit.visible and not unit.dead and (not range or GetDistance(from, unit) <= range)
end

function Spell:GetPrediction(target)
    return Prediction:GetPrediction(target, self)
end

function Spell:GetBestLinearCastPos(sTar, lst)
    return GetBestLinearCastPos(self, sTar, lst)
end

function Spell:GetBestCircularCastPos(sTar, lst)
    return GetBestCircularCastPos(self, sTar, lst)
end

function Spell:GetBestLinearFarmPos()
    return GetBestLinearFarmPos(self)
end

function Spell:GetBestCircularFarmPos()
    return GetBestCircularFarmPos(self)
end

function Spell:GetDamage(target, stage)
    local slot = self:SlotToString()
    return getdmg(slot, target, self.From, stage or 1)
end

function Spell:OnDash(target)
    local OnDash, CanHit, Pos = Prediction:IsDashing(target, self)

    if self.Collision then
        local colStatus = #(mCollision(self.From.pos, Pos, self)) > 0
        if colStatus then
            return
        end
        return OnDash, CanHit, Pos
    end

    return OnDash, CanHit, Pos
end

function Spell:OnImmobile(target)
    local TargetImmobile, ImmobilePos, ImmobileCastPosition = Prediction:IsImmobile(target, self)

    if self.Collision then
        local colStatus = #(mCollision(self.From.pos, Pos, self)) > 0
        if colStatus then
            return
        end
        return TargetImmobile, ImmobilePos, ImmobileCastPosition
    end

    return TargetImmobile, ImmobilePos, ImmobileCastPosition
end

function Spell:SlotToHK()
    return ({
        [_Q] = HK_Q,
        [_W] = HK_W,
        [_E] = HK_E,
        [_R] = HK_R,
        [SUMMONER_1] = HK_SUMMONER_1,
        [SUMMONER_2] = HK_SUMMONER_2
    })[self.Slot]
end

function Spell:SlotToString()
    return ({[_Q] = "Q", [_W] = "W", [_E] = "E", [_R] = "R"})[self.Slot]
end

function Spell:Cast(castOn)
    if not self:IsReady() or ShouldWait() then
        return
    end
    --
    local slot = self:SlotToHK()
    if self.Type == 5 then
        KeyDown(slot)
        return KeyUp(slot)
    end
    --
    local pos = castOn.x and castOn
    local targ = castOn.health and castOn
    --
    --if self.Type == "AOE" and targ then
    --    local bestPos, hit = self:GetBestCircularCastPos(targ, GetEnemyHeroes(self.Range+self.Radius))
    --    pos = hit >= 2 and bestPos or pos
    --end
    --
    if (targ and not targ.pos:To2D().onScreen) then
        return
    elseif (pos and not pos:To2D().onScreen) then
        pos = myHero.pos:Extended(pos, 200)
        if self.Type == 2 or self.Type == 3 or not pos:To2D().onScreen then
            return
        end
    end
    --
    return Control.CastSpell(slot, targ or pos)
end

function Spell:CastToPred(target, minHC)
    if not target then
        return
    end
    local predPos, castPos, hC = self:GetPrediction(target)
    if predPos and hC >= minHC then
        return self:Cast(predPos)
    end
end

function Spell:DrawDmg(hero, dmgModMultiplier, dmgModFlat, stage)
    local barPos = hero.hpBar
    if barPos.onScreen then
        local damage =
            (self:IsReady() and 1 or 0) * self:GetDamage(hero, stage) * (dmgModMultiplier or 1) + (dmgModFlat or 0)
        local percentHealthAfterDamage = max(0, hero.health - damage) / hero.maxHealth
        local xPosEnd = barPos.x + barXOffset + barWidth * hero.health / hero.maxHealth
        local xPosStart = barPos.x + barXOffset + percentHealthAfterDamage * 100
        DrawLine(xPosStart, barPos.y + barYOffset, xPosEnd, barPos.y + barYOffset, 10, Draw.Color(255, 235, 103, 25))
    end
end

function Spell:Draw(r, g, b)
    if self.Range and self.Range ~= huge then
        if self:IsReady() then
            DrawCircle(self.From.pos, self.Range, 5, DrawColor(255, r, g, b))
        else
            DrawCircle(self.From.pos, self.Range, 5, DrawColor(80, r, g, b))
        end
        return true
    end
end

function Spell:DrawMap(r, g, b)
    if self.Range and self.Range ~= huge then
        if self:IsReady() then
            DrawMap(self.From.pos, self.Range, 5, DrawColor(255, r, g, b))
        else
            DrawMap(self.From.pos, self.Range, 5, DrawColor(80, r, g, b))
        end
        return true
    end
end

local brokenIconChamps = {
    "Twitch"
}
--
local charName = myHero.charName
local isBrokenIconChamp = contains(brokenIconChamps, charName)
--x--
icons, Menu = {}

--
icons.NOX = "https://raw.githubusercontent.com/aneopsy/Nox/master/Icons/NoxLogo.png"
icons.Q = "https://raw.githubusercontent.com/aneopsy/Nox/master/Icons/spells/" .. myHero:GetSpellData(_Q).name .. ".png"
icons.W = "https://raw.githubusercontent.com/aneopsy/Nox/master/Icons/spells/" .. myHero:GetSpellData(_W).name .. ".png"
icons.E = "https://raw.githubusercontent.com/aneopsy/Nox/master/Icons/spells/" .. myHero:GetSpellData(_E).name .. ".png"
icons.R = "https://raw.githubusercontent.com/aneopsy/Nox/master/Icons/spells/" .. myHero:GetSpellData(_R).name .. ".png"

Menu = MenuElement({id = charName, name = "Nox | " .. charName, type = MENU, leftIcon = icons.NOX})
-- Drawer
Menu:MenuElement(
    {
        id = "Draw",
        name = "Drawings",
        type = MENU,
        leftIcon = "https://raw.githubusercontent.com/aneopsy/Nox/master/Icons/drawings.png"
    }
)
Menu.Draw:MenuElement({id = "ON", name = "Enable Drawings", value = true})
Menu.Draw:MenuElement({id = "TS", name = "Draw Selected Target", value = true, leftIcon = icons.NOX})
Menu.Draw:MenuElement({id = "Dmg", name = "Draw Damage On HP", value = true, leftIcon = icons.NOX})
Menu.Draw:MenuElement({id = "Q", name = "Q", value = false, leftIcon = icons.Q})
Menu.Draw:MenuElement({id = "W", name = "W", value = false, leftIcon = icons.W})
Menu.Draw:MenuElement({id = "E", name = "E", value = false, leftIcon = icons.E})
Menu.Draw:MenuElement({id = "R", name = "R", value = false, leftIcon = icons.R})

-- Spell
if isBrokenIconChamp then
    icons.Q = "https://raw.githubusercontent.com/aneopsy/Nox/master/Icons/spells/" .. charName .. "Q.png"
    icons.W = "https://raw.githubusercontent.com/aneopsy/Nox/master/Icons/spells/" .. charName .. "W.png"
    icons.E = "https://raw.githubusercontent.com/aneopsy/Nox/master/Icons/spells/" .. charName .. "E.png"
    icons.R = "https://raw.githubusercontent.com/aneopsy/Nox/master/Icons/spells/" .. charName .. "R.png"
end

Menu:MenuElement({id = "Q", name = "Q Settings", type = MENU, leftIcon = icons.Q})
local lambda =
    charName == "Lucian" and
    Menu:MenuElement(
        {id = "Q2", name = "Q2 Settings", type = MENU, leftIcon = icons.Q, tooltip = "Extended Q Settings"}
    )
Menu:MenuElement({id = "W", name = "W Settings", type = MENU, leftIcon = icons.W})
Menu:MenuElement({id = "E", name = "E Settings", type = MENU, leftIcon = icons.E})
Menu:MenuElement({id = "R", name = "R Settings", type = MENU, leftIcon = icons.R})

-- Timez
Menu:MenuElement(
    {
        id = "Timez",
        name = "Timez",
        type = MENU,
        leftIcon = "https://raw.githubusercontent.com/aneopsy/Nox/master/Icons/drawings.png"
    }
)

-- RecallTracker
Menu:MenuElement(
    {
        type = MENU,
        id = "RecallTracker",
        name = "Recall Tracker",
        leftIcon = "http://puu.sh/pPVxo/6e75182a01.png"
    }
)
local _PROCESS_SPELL_TABLE = {}
local _ANIMATION_TABLE = {}
local _VISION_TABLE = {}
local _LEVEL_UP_TABLE = {}
local _ITEM_TABLE = {}
local _PATH_TABLE = {}

class "BuffExplorer"

function BuffExplorer:__init()
    __BuffExplorer = true
    self.Heroes = {}
    self.Buffs = {}
    self.RemoveBuffCallback = {}
    self.UpdateBuffCallback = {}
    Callback.Add(
        "Tick",
        function()
            self:Tick()
        end
    )
end

function BuffExplorer:Tick() -- We can easily get rid of the pairs loops
    for i = 1, HeroCount() do
        local hero = Hero(i)
        if not self.Heroes[hero] and not self.Buffs[hero.networkID] then
            insert(self.Heroes, hero)
            self.Buffs[hero.networkID] = {}
        end
    end
    if self.UpdateBuffCallback ~= {} then
        for i = 1, #self.Heroes do
            local hero = self.Heroes[i]
            for i = 1, hero.buffCount do
                local buff = hero:GetBuff(i)
                if self:Valid(buff) then
                    if
                        not self.Buffs[hero.networkID][buff.name] or
                            (self.Buffs[hero.networkID][buff.name] and
                                self.Buffs[hero.networkID][buff.name].expireTime ~= buff.expireTime)
                     then
                        self.Buffs[hero.networkID][buff.name] = {
                            expireTime = buff.expireTime,
                            sent = true,
                            networkID = buff.sourcenID,
                            buff = buff
                        }
                        for i, cb in pairs(self.RemoveBuffCallback) do
                            cb(hero, buff)
                        end
                    end
                end
            end
        end
    end
    if self.RemoveBuffCallback ~= {} then
        for i = 1, #self.Heroes do
            local hero = self.Heroes[i]
            for buffname, buffinfo in pairs(self.Buffs[hero.networkID]) do
                if buffinfo.expireTime < Timer() then
                    for i, cb in pairs(self.UpdateBuffCallback) do
                        cb(hero, buffinfo.buff)
                    end
                    self.Buffs[hero.networkID][buffname] = nil
                end
            end
        end
    end
end

function BuffExplorer:Valid(buff)
    return buff and buff.name and #buff.name > 0 and buff.startTime <= Timer() and buff.expireTime > Timer()
end

class("Animation")

function Animation:__init()
    _G._ANIMATION_STARTED = true
    self.OnAnimationCallback = {}
    Callback.Add(
        "Tick",
        function()
            self:Tick()
        end
    )
end

function Animation:Tick()
    if self.OnAnimationCallback ~= {} then
        for i = 1, HeroCount() do
            local hero = Hero(i)
            local netID = hero.networkID
            if hero.activeSpellSlot then
                if not _ANIMATION_TABLE[netID] and hero.charName ~= "" then
                    _ANIMATION_TABLE[netID] = {animation = ""}
                end
                local _animation = hero.attackData.animationTime
                if _ANIMATION_TABLE[netID] and _ANIMATION_TABLE[netID].animation ~= _animation then
                    for _, Emit in pairs(self.OnAnimationCallback) do
                        Emit(hero, hero.attackData.animationTime)
                    end
                    _ANIMATION_TABLE[netID].animation = _animation
                end
            end
        end
    end
end

class("Vision")

function Vision:__init()
    self.GainVisionCallback = {}
    self.LoseVisionCallback = {}
    _G._VISION_STARTED = true
    Callback.Add(
        "Tick",
        function()
            self:Tick()
        end
    )
end

function Vision:Tick()
    local heroCount = HeroCount()
    --if heroCount <= 0 then return end
    for i = 1, heroCount do
        local hero = Hero(i)
        if hero then
            local netID = hero.networkID
            if not _VISION_TABLE[netID] then
                _VISION_TABLE[netID] = {visible = hero.visible}
            end
            if self.LoseVisionCallback ~= {} then
                if hero.visible == false and _VISION_TABLE[netID] and _VISION_TABLE[netID].visible == true then
                    _VISION_TABLE[netID] = {visible = hero.visible}
                    for _, Emit in pairs(self.LoseVisionCallback) do
                        Emit(hero)
                    end
                end
            end
            if self.GainVisionCallback ~= {} then
                if hero.visible == true and _VISION_TABLE[netID] and _VISION_TABLE[netID].visible == false then
                    _VISION_TABLE[netID] = {visible = hero.visible}
                    for _, Emit in pairs(self.GainVisionCallback) do
                        Emit(hero)
                    end
                end
            end
        end
    end
end

class "Path"

function Path:__init()
    self.OnNewPathCallback = {}
    self.OnDashCallback = {}
    _G._PATH_STARTED = true
    Callback.Add(
        "Tick",
        function()
            self:Tick()
        end
    )
end

function Path:Tick()
    if self.OnNewPathCallback ~= {} or self.OnDashCallback ~= {} then
        for i = 1, HeroCount() do
            local hero = Hero(i)
            self:OnPath(hero)
        end
    end
end

function Path:OnPath(unit)
    if not _PATH_TABLE[unit.networkID] then
        _PATH_TABLE[unit.networkID] = {
            pos = unit.posTo,
            speed = unit.ms,
            time = Timer()
        }
    end

    if _PATH_TABLE[unit.networkID].pos ~= unit.posTo then
        local path = unit.pathing
        local isDash = path.isDashing
        local dashSpeed = path.dashSpeed
        local dashGravity = path.dashGravity
        local dashDistance = GetDistance(unit.pos, unit.posTo)
        --
        _PATH_TABLE[unit.networkID] = {
            startPos = unit.pos,
            pos = unit.posTo,
            speed = unit.ms,
            time = Timer()
        }
        --
        for k, cb in pairs(self.OnNewPathCallback) do
            cb(unit, unit.pos, unit.posTo, isDash, dashSpeed, dashGravity, dashDistance)
        end
        --
        if isDash then
            for k, cb in pairs(self.OnDashCallback) do
                cb(unit, unit.pos, unit.posTo, dashSpeed, dashGravity, dashDistance)
            end
        end
    end
end

class "LevelUp"

function LevelUp:__init()
    _G._LEVEL_UP_START = true
    self.OnLevelUpCallback = {}
    for _ = 1, HeroCount() do
        local obj = Hero(_)
        if obj then
            _LEVEL_UP_TABLE[obj.networkID] = {level = obj.levelData.lvl == 1 and 0 or obj.levelData.lvl}
        end
    end
    Callback.Add(
        "Tick",
        function()
            self:Tick()
        end
    )
end

function LevelUp:Tick()
    if self.OnLevelUpCallback ~= {} then
        for i = 1, HeroCount() do
            local hero = Hero(i)
            local level = hero.levelData.lvl
            local netID = hero.networkID
            if not _LEVEL_UP_TABLE[netID] then
                _LEVEL_UP_TABLE[netID] = {level = obj.levelData.lvl == 1 and 0 or obj.levelData.lvl}
            end
            if _LEVEL_UP_TABLE[netID] and level and _LEVEL_UP_TABLE[netID].level ~= level then
                for _, Emit in pairs(self.OnLevelUpCallback) do
                    Emit(hero, hero.levelData)
                end
                _LEVEL_UP_TABLE[netID].level = level
            end
        end
    end
end

class "ItemEvents"

function ItemEvents:__init()
    self.BuyItemCallback = {}
    self.SellItemCallback = {}
    _G._ITEM_CHECKER_STARTED = true
    for i = ITEM_1, ITEM_7 do
        if myHero:GetItemData(i).itemID ~= 0 then
            _ITEM_TABLE[i] = {has = true, data = myHero:GetItemData(i)}
        else
            _ITEM_TABLE[i] = {has = false, data = nil}
        end
    end

    Callback.Add(
        "Tick",
        function()
            self:Tick()
        end
    )
end

function ItemEvents:Tick()
    for i = ITEM_1, ITEM_7 do
        if myHero:GetItemData(i).itemID ~= 0 then
            if _ITEM_TABLE[i].has == false then
                _ITEM_TABLE[i].has = true
                _ITEM_TABLE[i].data = myHero:GetItemData(i)
                for _, Emit in pairs(self.BuyItemCallback) do
                    Emit(myHero:GetItemData(i), i)
                end
            end
        else
            if _ITEM_TABLE[i].has == true then
                for _, Emit in pairs(self.SellItemCallback) do
                    Emit(_ITEM_TABLE[i].data, i)
                end
                _ITEM_TABLE[i].has = false
                _ITEM_TABLE[i].data = nil
            end
        end
    end
end

class "Interrupter"

function Interrupter:__init()
    _G._INTERRUPTER_START = true
    self.InterruptCallback = {}
    self.spells = {
        ["CaitlynAceintheHole"] = {
            Name = "Caitlyn",
            displayname = "R | Ace in the Hole",
            spellname = "CaitlynAceintheHole"
        },
        ["Crowstorm"] = {Name = "FiddleSticks", displayname = "R | Crowstorm", spellname = "Crowstorm"},
        ["DrainChannel"] = {Name = "FiddleSticks", displayname = "W | Drain", spellname = "DrainChannel"},
        ["GalioIdolOfDurand"] = {Name = "Galio", displayname = "R | Idol of Durand", spellname = "GalioIdolOfDurand"},
        ["ReapTheWhirlwind"] = {Name = "Janna", displayname = "R | Monsoon", spellname = "ReapTheWhirlwind"},
        ["KarthusFallenOne"] = {Name = "Karthus", displayname = "R | Requiem", spellname = "KarthusFallenOne"},
        ["KatarinaR"] = {Name = "Katarina", displayname = "R | Death Lotus", spellname = "KatarinaR"},
        ["LucianR"] = {Name = "Lucian", displayname = "R | The Culling", spellname = "LucianR"},
        ["AlZaharNetherGrasp"] = {Name = "Malzahar", displayname = "R | Nether Grasp", spellname = "AlZaharNetherGrasp"},
        ["Meditate"] = {Name = "MasterYi", displayname = "W | Meditate", spellname = "Meditate"},
        ["MissFortuneBulletTime"] = {
            Name = "MissFortune",
            displayname = "R | Bullet Time",
            spellname = "MissFortuneBulletTime"
        },
        ["AbsoluteZero"] = {Name = "Nunu", displayname = "R | Absoulte Zero", spellname = "AbsoluteZero"},
        ["PantheonRJump"] = {Name = "Pantheon", displayname = "R | Jump", spellname = "PantheonRJump"},
        ["PantheonRFall"] = {Name = "Pantheon", displayname = "R | Fall", spellname = "PantheonRFall"},
        ["ShenStandUnited"] = {Name = "Shen", displayname = "R | Stand United", spellname = "ShenStandUnited"},
        ["Destiny"] = {Name = "TwistedFate", displayname = "R | Destiny", spellname = "Destiny"},
        ["UrgotSwap2"] = {Name = "Urgot", displayname = "R | Hyper-Kinetic Position Reverser", spellname = "UrgotSwap2"},
        ["VarusQ"] = {Name = "Varus", displayname = "Q | Piercing Arrow", spellname = "VarusQ"},
        ["VelkozR"] = {Name = "Velkoz", displayname = "R | Lifeform Disintegration Ray", spellname = "VelkozR"},
        ["InfiniteDuress"] = {Name = "Warwick", displayname = "R | Infinite Duress", spellname = "InfiniteDuress"},
        ["XerathLocusOfPower2"] = {
            Name = "Xerath",
            displayname = "R | Rite of the Arcane",
            spellname = "XerathLocusOfPower2"
        }
    }
    Callback.Add(
        "Tick",
        function()
            self:OnTick()
        end
    )
end

function Interrupter:AddToMenu(unit, menu)
    self.menu = menu
    if unit then
        for k, spells in pairs(self.spells) do
            if spells.Name == unit.charName then
                self.menu:MenuElement(
                    {id = spells.spellname, name = spells.Name .. " | " .. spells.displayname, value = true}
                )
            end
        end
    end
end

function Interrupter:OnTick()
    local enemies = GetEnemyHeroes(3000)
    for i = 1, #(enemies) do
        local enemy = enemies[i]
        if enemy and enemy.activeSpell and enemy.activeSpell.valid then
            local spell = enemy.activeSpell
            if
                self.spells[spell.name] and self.menu and self.menu[spell.name] and self.menu[spell.name]:Value() and
                    spell.isChanneling and
                    spell.castEndTime - Timer() > 0
             then
                for i, Emit in pairs(self.InterruptCallback) do
                    Emit(enemy, spell)
                end
            end
        end
    end
end

class "ProcessSpell"

function ProcessSpell:__init()
    _G._PROCESS_SPELL_START = true
    self.OnProcessSpellCallback = {}
    for _ = 1, HeroCount() do
        local obj = Hero(_)
        if obj then
            _PROCESS_SPELL_TABLE[obj.networkID] = {unit = unit, spell = nil}
        end
    end
    Callback.Add(
        "Tick",
        function()
            self:OnTick()
        end
    )
end

function ProcessSpell:OnTick()
    if self.OnProcessSpellCallback ~= {} then
        for i = 1, #_PROCESS_SPELL_TABLE do
            local hero = _PROCESS_SPELL_TABLE[i].unit
            local last = _PROCESS_SPELL_TABLE[i].spell
            local spell = hero.activeSpell

            if spell and last ~= (spell.name .. spell.startTime) and unit.isChanneling then
                _PROCESS_SPELL_TABLE[i].spell = spell.name .. spell.startTime
                for _, Emit in pairs(self.OnProcessSpellCallback) do
                    Emit(unit, spell)
                end
            end
        end
    end
end

--------------------------------------
local function OnInterruptable(fn)
    if not _INTERRUPTER_START then
        _G.Interrupter = Interrupter()
        print("[NOX] Callbacks | Interrupter Loaded.")
    end
    insert(Interrupter.InterruptCallback, fn)
end
local function OnLevelUp(fn)
    if not _LEVEL_UP_START then
        _G.LevelUp = LevelUp()
        print("[NOX] Callbacks | Level Up Loaded.")
    end
    insert(LevelUp.OnLevelUpCallback, fn)
end

local function OnNewPath(fn)
    if not _PATH_STARTED then
        _G.Path = Path()
        print("[NOX] Callbacks | Pathing Loaded.")
    end
    insert(Path.OnNewPathCallback, fn)
end

local function OnDash(fn)
    if not _PATH_STARTED then
        _G.Path = Path()
        print("[NOX] Callbacks | Pathing Loaded.")
    end
    insert(Path.OnDashCallback, fn)
end

local function OnGainVision(fn)
    if not _VISION_STARTED then
        _G.Vision = Vision()
        print("[NOX] Callbacks | Vision Loaded.")
    end
    insert(Vision.GainVisionCallback, fn)
end

local function OnLoseVision(fn)
    if not _VISION_STARTED then
        _G.Vision = Vision()
        print("[NOX] Callbacks | Vision Loaded.")
    end
    insert(Vision.LoseVisionCallback, fn)
end

local function OnAnimation(fn)
    if not _ANIMATION_STARTED then
        _G.Animation = Animation()
        print("[NOX] Callbacks | Animation Loaded.")
    end
    insert(Animation.OnAnimationCallback, fn)
end

local function OnUpdateBuff(cb)
    if not __BuffExplorer_Loaded then
        _G.BuffExplorer = BuffExplorer()
        print("[NOX] Callbacks | Buff Explorer Loaded.")
    end
    insert(BuffExplorer.UpdateBuffCallback, cb)
end

local function OnRemoveBuff(cb)
    if not __BuffExplorer_Loaded then
        _G.BuffExplorer = BuffExplorer()
        print("[NOX] Callbacks | Buff Explorer Loaded.")
    end
    insert(BuffExplorer.RemoveBuffCallback, cb)
end

local function OnBuyItem(fn)
    if not _ITEM_CHECKER_STARTED then
        _G.ItemEvents = ItemEvents()
        print("[NOX] Callbacks | Item Events Loaded.")
    end
    insert(ItemEvents.BuyItemCallback, fn)
end

local function OnSellItem(fn)
    if not _ITEM_CHECKER_STARTED then
        _G.ItemEvents = ItemEvents()
        print("[NOX] Callbacks | Item Events Loaded.")
    end
    insert(ItemEvents.SellItemCallback, fn)
end

local function OnProcessSpell(fn)
    if not _PROCESS_SPELL_START then
        _G.ProcessSpell = ProcessSpell()
        print("[NOX] Callbacks | ProcessSpell Loaded.")
    end
    insert(ProcessSpell.ProcessSpellCallback, fn)
end

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

class "RecallTracker"

local function percentToRGB(percent)
    local r, g
    if percent == 90 then
        percent = 99
    end

    if percent < 50 then
        g = math.floor(255 * (percent / 50))
        r = 255
    else
        g = 255
        r = math.floor(255 * ((50 - percent % 50) / 50))
    end

    return Draw.Color(90, r, g, 0)
end

local function DownloadSprite(url, path)
    local sprite = SPRITE_PATH .. path
    if not FileExist(sprite) then
        print("Download path")
        DownloadFileAsync(
            url,
            sprite,
            function()
            end
        )
        repeat
        until FileExist(sprite)
    end
end

local function percentToRGB(percent)
    local r, g
    if percent == 90 then
        percent = 99
    end

    if percent < 50 then
        g = math.floor(255 * (percent / 50))
        r = 255
    else
        g = 255
        r = math.floor(255 * ((50 - percent % 50) / 50))
    end

    return Draw.Color(120, r, g, 0)
end

function RecallTracker:__init()
    Menu.RecallTracker:MenuElement({id = "Enabled", name = "Enabled", value = true})
    Menu.RecallTracker:MenuElement(
        {id = "gui", name = "Interface", type = MENU, leftIcon = "http://i.imgur.com/rRpSWA6.png"}
    )
    Menu.RecallTracker.gui:MenuElement({id = "drawGUI", name = "Draw Interface", value = true})
    Menu.RecallTracker.gui:MenuElement({id = "vertical", name = "Draw Vertical", value = true})
    Menu.RecallTracker.gui:MenuElement({id = "x", name = "X", value = 50, min = 0, max = Game.Resolution().x, step = 1})
    Menu.RecallTracker.gui:MenuElement({id = "y", name = "Y", value = 50, min = 0, max = Game.Resolution().y, step = 1})

    Menu.RecallTracker:MenuElement(
        {id = "alert", name = "Gank Alert", type = MENU, leftIcon = "http://i.imgur.com/fXU3MKH.png"}
    )
    Menu.RecallTracker.alert:MenuElement(
        {id = "range", name = "Detection Range", value = 2500, min = 900, max = 4000, step = 10}
    )
    Menu.RecallTracker.alert:MenuElement({id = "drawGank", name = "Gank Alert", value = true})
    Menu.RecallTracker.alert:MenuElement({id = "drawGankFOW", name = "FOW Gank Alert", value = true})

    DownloadSprite("https://raw.githubusercontent.com/aneopsy/Nox/master/Icons/TrackerGUI.png", "TrackerHUD")
    self.TrackerHUDSprite = Sprite("TrackerHUD", 0.8)
    DownloadSprite("https://raw.githubusercontent.com/aneopsy/Nox/master/Icons/TrackerLoading.png", "TrackerLoading")
    self.TrackerLoadingSprite = Sprite("TrackerLoading", 0.8)
    DownloadSprite("https://raw.githubusercontent.com/aneopsy/Nox/master/Icons/TrackerDanger.png", "TrackerDanger")
    self.TrackerDangerSprite = Sprite("TrackerDanger", 0.8)
    DownloadSprite("https://raw.githubusercontent.com/aneopsy/Nox/master/Icons/TrackerDead.png", "TrackerDead")
    self.TrackerDeadSprite = Sprite("TrackerDead", 0.8)
    DownloadSprite("https://raw.githubusercontent.com/aneopsy/Nox/master/Icons/TrackerMana.png", "TrackerMana")
    self.TrackerManaSprite = Sprite("TrackerMana", 0.8)
    DownloadSprite("https://raw.githubusercontent.com/aneopsy/Nox/master/Icons/TrackerHP.png", "TrackerHP")
    self.TrackerHPSprite = Sprite("TrackerHP", 0.8)

    if myHero.team == 90 then
        self.aBasePos = Vector(415, 182, 415)
        self.eBasePos = Vector(14302, 172, 14387.8)
    else
        self.aBasePos = Vector(14302, 172, 14387.8)
        self.eBasePos = Vector(415, 182, 415)
    end

    self.champSprite = {}
    self.spellSprite = {}
    self.isRecalling = {}
    self.rowHeight = 85
    self.myTeam = 0
    self.invChamp = {}
    self.iCanSeeYou = {}
    self.OnGainVision = {}
    self.oldExp = {}
    self.newExp = {}
    self.eT = {}
    self.enemies = {}
    self.before_rip_tick = 50000

    self.summonerSprites = {}
    self.summonerSprites[1] = {Sprite("SpellTracker\\1.png"), "SummonerBarrier"}
    self.summonerSprites[2] = {Sprite("SpellTracker\\2.png"), "SummonerBoost"}
    self.summonerSprites[3] = {Sprite("SpellTracker\\3.png"), "SummonerDot"}
    self.summonerSprites[4] = {Sprite("SpellTracker\\4.png"), "SummonerExhaust"}
    self.summonerSprites[5] = {Sprite("SpellTracker\\5.png"), "SummonerFlash"}
    self.summonerSprites[6] = {Sprite("SpellTracker\\6.png"), "SummonerHaste"}
    self.summonerSprites[7] = {Sprite("SpellTracker\\7.png"), "SummonerHeal"}
    self.summonerSprites[8] = {Sprite("SpellTracker\\8.png"), "SummonerSmite"}
    self.summonerSprites[9] = {Sprite("SpellTracker\\9.png"), "SummonerTeleport"}
    self.summonerSprites[10] = {Sprite("SpellTracker\\10.png"), "S5_SummonerSmiteDuel"}
    self.summonerSprites[11] = {Sprite("SpellTracker\\11.png"), "S5_SummonerSmitePlayerGanker"}
    self.summonerSprites[12] = {Sprite("SpellTracker\\12.png"), "SummonerPoroRecall"}
    self.summonerSprites[13] = {Sprite("SpellTracker\\13.png"), "SummonerPoroThrow"}

    for i = 1, Game.HeroCount() do
        local hero = Game.Hero(i)
        if hero and hero.isEnemy then
            DownloadSprite(
                "https://raw.githubusercontent.com/aneopsy/Nox/master/Icons/champions/" .. hero.charName .. ".png",
                hero.charName .. "RTChampSprite"
            )
            self.champSprite[hero.charName] = Sprite(hero.charName .. "RTChampSprite", 0.52)
            self.invChamp[hero.networkID] = {
                champ = hero,
                lastTick = GetTickCount(),
                lastWP = Vector(0, 0, 0),
                lastPos = hero.pos or eBasePos,
                where = "will be added.",
                status = hero.visible,
                n = i - 1
            }
            self.iCanSeeYou[hero.networkID] = {tick = 0, champ = hero, number = i - 1, draw = false}
            self.isRecalling[hero.networkID] = {status = false, tick = 0, proc = nil, spendTime = 0}
            self.OnGainVision[hero.networkID] = {status = not hero.visible, tick = 0}
            self.oldExp[hero.networkID] = 0
            self.newExp[hero.networkID] = 0
            table.insert(self.enemies, hero)
            self.eT[hero.networkID] = {champ = hero, fow = 0, saw = 0}
            DownloadSprite(
                "https://raw.githubusercontent.com/aneopsy/Nox/master/Icons/spells/" ..
                    hero:GetSpellData(_Q).name .. ".png",
                "RT" .. hero:GetSpellData(_Q).name
            )
            DownloadSprite(
                "https://raw.githubusercontent.com/aneopsy/Nox/master/Icons/spells/" ..
                    hero:GetSpellData(_W).name .. ".png",
                "RT" .. hero:GetSpellData(_W).name
            )
            DownloadSprite(
                "https://raw.githubusercontent.com/aneopsy/Nox/master/Icons/spells/" ..
                    hero:GetSpellData(_E).name .. ".png",
                "RT" .. hero:GetSpellData(_E).name
            )
            DownloadSprite(
                "https://raw.githubusercontent.com/aneopsy/Nox/master/Icons/spells/" ..
                    hero:GetSpellData(_R).name .. ".png",
                "RT" .. hero:GetSpellData(_R).name
            )
            self.spellSprite[hero.charName] = {
                Q = Sprite("RT" .. hero:GetSpellData(_Q).name, 1),
                W = Sprite("RT" .. hero:GetSpellData(_W).name, 1),
                E = Sprite("RT" .. hero:GetSpellData(_E).name, 1),
                R = Sprite("RT" .. hero:GetSpellData(_R).name, 1)
            }
        end
    end

    Callback.Add(
        "ProcessRecall",
        function(...)
            self:OnProcessRecall(...)
        end
    )
    Callback.Add(
        "Draw",
        function(...)
            self:OnDraw(...)
        end
    )
    Callback.Add(
        "Tick",
        function(...)
            self:OnTick(...)
        end
    )
end

function RecallTracker:GetSpriteByName(name)
    for i, summonerSprite in pairs(self.summonerSprites) do
        if summonerSprite[2] == name then
            return summonerSprite[1]
        end
    end
end

function RecallTracker:OnTick()
    for i = 1, Game.HeroCount() do
        local hero = Game.Hero(i)
        --OnGainVision
        if
            self.invChamp[hero.networkID] ~= nil and self.invChamp[hero.networkID].status == false and hero.visible and
                not hero.dead
         then
            if
                myHero.pos:DistanceTo(hero.pos) <= Menu.RecallTracker.alert.range:Value() + 90 and
                    GetTickCount() - self.invChamp[hero.networkID].lastTick > 5000
             then
                self.OnGainVision[hero.networkID].status = true
                self.OnGainVision[hero.networkID].tick = GetTickCount()
            end
            self.newExp[hero.networkID] = hero.levelData.exp
            self.oldExp[hero.networkID] = hero.levelData.exp
        end
        if hero and not hero.dead and hero.isEnemy and hero.visible then
            self.invChamp[hero.networkID].status = hero.visible
            self.isRecalling[hero.networkID].spendTime = 0
            self.newExp[hero.networkID] = hero.levelData.exp
            local hehTicker = GetTickCount()
            if (self.before_rip_tick + 9000) < hehTicker then
                self.oldExp[hero.networkID] = hero.levelData.exp
                self.before_rip_tick = hehTicker
            end
        end
        --OnLoseVision
        if
            self.invChamp[hero.networkID] ~= nil and self.invChamp[hero.networkID].status == true and not hero.visible and
                not hero.dead
         then
            self.invChamp[hero.networkID].lastTick = GetTickCount()
            self.invChamp[hero.networkID].lastWP = hero.posTo
            self.invChamp[hero.networkID].lastPos = hero.pos
            self.invChamp[hero.networkID].status = false
        end
    end
end

function RecallTracker:OnDraw()
    if not Menu.RecallTracker.Enabled:Value() then
        return
    end
    for i, v in pairs(self.invChamp) do
        local d = v.champ.dead
        self.champSprite[v.champ.charName]:Draw(
            Menu.RecallTracker.gui.x:Value() + 22,
            Menu.RecallTracker.gui.y:Value() + 90 * (v.n - 1) + 16
        )
        if d then
            self.TrackerDeadSprite:Draw(
                Menu.RecallTracker.gui.x:Value() + 20,
                Menu.RecallTracker.gui.y:Value() + 90 * (v.n - 1) + 16
            )
        end
        self.TrackerHUDSprite:Draw(Menu.RecallTracker.gui.x:Value(), Menu.RecallTracker.gui.y:Value() + 90 * (v.n - 1)+1)
        if v.status == false and not d then
            local timer = math.floor((GetTickCount() - v.lastTick) / 900)
            if timer < 350 then
                Draw.Text(
                    timer,
                    45,
                    Menu.RecallTracker.gui.x:Value() + 52 - 10 * string.len(timer),
                    Menu.RecallTracker.gui.y:Value() + 25 + 90 * (v.n - 1),
                    Draw.Color(200, 225, 225, 225)
                )
            else
                Draw.Text(
                    "AFK",
                    45,
                    Menu.RecallTracker.gui.x:Value() + 52 - 10 * 3,
                    Menu.RecallTracker.gui.y:Value() + 30 + 90 * (v.n - 1),
                    Draw.Color(200, 225, 0, 30)
                )
            end
            local eTimer = math.floor(v.lastPos:DistanceTo(myHero.pos) / v.champ.ms) - timer
            if eTimer > 0 then
                Draw.Text(
                    eTimer,
                    18,
                    Menu.RecallTracker.gui.x:Value() + 276 - 3 * (string.len(eTimer) - 1),
                    Menu.RecallTracker.gui.y:Value() + 40 + 90 * (v.n - 1),
                    Draw.Color(200, 225, 225, 225)
                )
            else
                self.TrackerDangerSprite:Draw(
                    Menu.RecallTracker.gui.x:Value() + 264,
                    Menu.RecallTracker.gui.y:Value() + 90 * (v.n - 1) + 32
                )
            end
        end

        if self.isRecalling[v.champ.networkID].status == true then
            if self.isRecalling[v.champ.networkID].proc.name == "Teleport" then
                Draw.Text(
                    "TELEPORT",
                    20,
                    Menu.RecallTracker.gui.x:Value() + 155,
                    Menu.RecallTracker.gui.y:Value() + 23 + 90 * (v.n - 1),
                    Draw.Color(200, 206, 89, 214)
                )
            else
                Draw.Text(
                    "RECALL",
                    20,
                    Menu.RecallTracker.gui.x:Value() + 155,
                    Menu.RecallTracker.gui.y:Value() + 23 + 90 * (v.n - 1),
                    Draw.Color(200, 16, 235, 240)
                )
            end
        elseif d then
            Draw.Text(
                "DEAD",
                20,
                Menu.RecallTracker.gui.x:Value() + 162,
                Menu.RecallTracker.gui.y:Value() + 23 + 90 * (v.n - 1),
                Draw.Color(200, 255, 0, 0)
            )
        elseif (v.lastPos == eBasePos or v.lastPos:DistanceTo(eBasePos) < 250) and v.status == false then
            Draw.Text(
                "BASE",
                20,
                Menu.RecallTracker.gui.x:Value() + 162,
                Menu.RecallTracker.gui.y:Value() + 23 + 90 * (v.n - 1),
                Draw.Color(200, 255, 255, 255)
            )
        elseif v.status == false then
            Draw.Text(
                "MISS",
                20,
                Menu.RecallTracker.gui.x:Value() + 162,
                Menu.RecallTracker.gui.y:Value() + 23 + 90 * (v.n - 1),
                Draw.Color(200, 255, 255, 255)
            )
        else
            Draw.Text(
                "VISIBLE",
                20,
                Menu.RecallTracker.gui.x:Value() + 152,
                Menu.RecallTracker.gui.y:Value() + 23 + 90 * (v.n - 1),
                Draw.Color(200, 255, 255, 255)
            )
        end

        if not d then
            local manaMulti = v.champ.mana / v.champ.maxMana
            if v.champ.maxMana == 0 then
                manaMulti = 0
            end
            local CutMANA = {x = 0, y = 62, w = 4, h = 62 - 62 * (manaMulti)}
            self.TrackerManaSprite:Draw(
                CutMANA,
                Menu.RecallTracker.gui.x:Value() + 14,
                Menu.RecallTracker.gui.y:Value() + 77 + 90 * (v.n - 1)
            )
            local CutHP = {x = 0, y = 62, w = 4, h = 62 - 62 * (v.champ.health / v.champ.maxHealth)}
            self.TrackerHPSprite:Draw(
                CutHP,
                Menu.RecallTracker.gui.x:Value() + 88,
                Menu.RecallTracker.gui.y:Value() + 77 + 90 * (v.n - 1)
            )

            if self.isRecalling[v.champ.networkID].status == true then
                local r =
                    242 / self.isRecalling[v.champ.networkID].proc.totalTime *
                    (self.isRecalling[v.champ.networkID].proc.totalTime -
                        (GetTickCount() - self.isRecalling[v.champ.networkID].tick))
                local recallCut = {x = 0, y = 0, w = r, h = 15}
                self.TrackerLoadingSprite:Draw(
                    recallCut,
                    Menu.RecallTracker.gui.x:Value() + 98,
                    Menu.RecallTracker.gui.y:Value() + 75 + 90 * (v.n - 1)
                )
            end
        end

        --Spells
        local sprCut = {x = 0, y = 0, w = 12, h = 12}
        --Q
        local FData = v.champ:GetSpellData(0)
        if FData.level > 0 then
            self.spellSprite[v.champ.charName].Q:Draw(
                sprCut,
                Menu.RecallTracker.gui.x:Value() + 107,
                Menu.RecallTracker.gui.y:Value() + 55 + 90 * (v.n - 1)
            )
            for z = 1, FData.level do
                Draw.Rect(
                    Menu.RecallTracker.gui.x:Value() + 104 + z * 3 - 1,
                    Menu.RecallTracker.gui.y:Value() + 68 + 90 * (v.n - 1),
                    1,
                    2,
                    Draw.Color(0xFFFFFF00)
                )
            end
            --[[
            if FData.ammoCurrentCd > 0 then
                if FData.ammo > 0 then
                    Draw.Rect(
                        hero.pos2D.x - XposX + 3 + 27 * 0,
                        hero.pos2D.y + YposY + 3 + 16,
                        23 - ((FData.ammoCurrentCd / FData.ammoCd) * 23),
                        4,
                        Draw.Color(0xFFFF7F00)
                    )
                else
                    Draw.Rect(
                        hero.pos2D.x - XposX + 3 + 27 * 0,
                        hero.pos2D.y + YposY + 3 + 16,
                        23 - ((FData.ammoCurrentCd / FData.ammoCd) * 23),
                        4,
                        Draw.Color(0xFFFF0000)
                    )
                end
            else
                if FData.currentCd > 0 then
                    Draw.Rect(
                        hero.pos2D.x - XposX + 3 + 27 * 0,
                        hero.pos2D.y + YposY + 3 + 16,
                        23 - ((FData.currentCd / FData.cd) * 23),
                        4,
                        Draw.Color(0xFFFF0000)
                    )
                else
                    Draw.Rect(
                        hero.pos2D.x - XposX + 3 + 27 * 0,
                        hero.pos2D.y + YposY + 3 + 16,
                        23,
                        4,
                        Draw.Color(0xFF00FF00)
                    )
                end
            end--]]
        end
        --W
        local FData = v.champ:GetSpellData(1)
        if FData.level > 0 then
            self.spellSprite[v.champ.charName].W:Draw(
                sprCut,
                Menu.RecallTracker.gui.x:Value() + 126,
                Menu.RecallTracker.gui.y:Value() + 55 + 90 * (v.n - 1)
            )
            for z = 1, FData.level do
                Draw.Rect(
                    Menu.RecallTracker.gui.x:Value() + 123 + z * 3 - 1,
                    Menu.RecallTracker.gui.y:Value() + 68 + 90 * (v.n - 1),
                    1,
                    2,
                    Draw.Color(0xFFFFFF00)
                )
            end
        end
        --E
        local FData = v.champ:GetSpellData(2)
        if FData.level > 0 then
            self.spellSprite[v.champ.charName].E:Draw(
                sprCut,
                Menu.RecallTracker.gui.x:Value() + 145,
                Menu.RecallTracker.gui.y:Value() + 55 + 90 * (v.n - 1)
            )
            for z = 1, FData.level do
                Draw.Rect(
                    Menu.RecallTracker.gui.x:Value() + 142 + z * 3 - 1,
                    Menu.RecallTracker.gui.y:Value() + 68 + 90 * (v.n - 1),
                    1,
                    2,
                    Draw.Color(0xFFFFFF00)
                )
            end
        end
        --R
        local FData = v.champ:GetSpellData(3)
        if FData.level > 0 then
            self.spellSprite[v.champ.charName].R:Draw(
                sprCut,
                Menu.RecallTracker.gui.x:Value() + 165,
                Menu.RecallTracker.gui.y:Value() + 55 + 90 * (v.n - 1)
            )
            for z = 1, FData.level do
                Draw.Rect(
                    Menu.RecallTracker.gui.x:Value() + 164 + z * 3 - 1,
                    Menu.RecallTracker.gui.y:Value() + 68 + 90 * (v.n - 1),
                    1,
                    2,
                    Draw.Color(0xFFFFFF00)
                )
            end
        end
        --Summoner1
        local FData = v.champ:GetSpellData(SUMMONER_1)
        local SpellYOffset = 0
        if FData.ammoCurrentCd > 0 then
            SpellYOffset = math.max((228 - math.ceil((FData.ammoCurrentCd / FData.ammoCd) * 20) * 12), 0)
        else
            if FData.currentCd > 0 then
                SpellYOffset = math.max((228 - math.ceil((FData.currentCd / FData.cd) * 20) * 12), 0)
            else
                SpellYOffset = 228
            end
        end
        local SprIdx1 = self:GetSpriteByName(FData.name)
        if SprIdx1 ~= nil then
            local sprCut = {x = 0, y = SpellYOffset, w = 12, h = SpellYOffset + 12}
            SprIdx1:Draw(
                sprCut,
                Menu.RecallTracker.gui.x:Value() + 188,
                Menu.RecallTracker.gui.y:Value() + 55 + 90 * (v.n - 1)
            )
        end
        --Summoner2
        local FData = v.champ:GetSpellData(SUMMONER_2)
        local SpellYOffset = 0
        if FData.ammoCurrentCd > 0 then
            SpellYOffset = math.max((228 - math.ceil((FData.ammoCurrentCd / FData.ammoCd) * 20) * 12), 0)
        else
            if FData.currentCd > 0 then
                SpellYOffset = math.max((228 - math.ceil((FData.currentCd / FData.cd) * 20) * 12), 0)
            else
                SpellYOffset = 228
            end
        end
        local SprIdx2 = self:GetSpriteByName(FData.name)
        if SprIdx2 ~= nil then
            local sprCut = {x = 0, y = SpellYOffset, w = 12, h = SpellYOffset + 12}
            SprIdx2:Draw(
                sprCut,
                Menu.RecallTracker.gui.x:Value() + 208,
                Menu.RecallTracker.gui.y:Value() + 55 + 90 * (v.n - 1)
            )
        end
    end
end

function RecallTracker:OnProcessRecall(unit, recall)
    if self.isRecalling[unit.networkID] == nil then
        return
    end
    if
        recall.isFinish == false and recall.isStart == true and unit.type == "AIHeroClient" and
            self.isRecalling[unit.networkID] ~= nil
     then
        self.isRecalling[unit.networkID].status = true
        self.isRecalling[unit.networkID].tick = GetTickCount()
        self.isRecalling[unit.networkID].proc = recall
    elseif
        recall.isFinish == true and recall.isStart == false and unit.type == "AIHeroClient" and
            self.isRecalling[unit.networkID] ~= nil
     then
        self.isRecalling[unit.networkID].status = false
        self.isRecalling[unit.networkID].proc = recall
        self.isRecalling[unit.networkID].spendTime = 0
    elseif
        recall.isFinish == false and recall.isStart == false and unit.type == "AIHeroClient" and
            self.isRecalling[unit.networkID] ~= nil and
            self.isRecalling[unit.networkID].status == true
     then
        self.isRecalling[unit.networkID].status = false
        self.isRecalling[unit.networkID].proc = recall
        if not unit.visible then
            self.isRecalling[unit.networkID].spendTime = self.isRecalling[unit.networkID].spendTime + recall.passedTime
        end
    else
        if self.isRecalling[unit.networkID] ~= nil and self.isRecalling[unit.networkID].status == false then
            self.isRecalling[unit.networkID].status = true
            self.isRecalling[unit.networkID].tick = GetTickCount()
            self.isRecalling[unit.networkID].proc = recall
        end
    end
    if
        recall.isFinish == true and recall.isStart == false and unit.type == "AIHeroClient" and
            self.invChamp[unit.networkID] ~= nil
     then
        self.invChamp[unit.networkID].lastPos = self.eBasePos
        self.invChamp[unit.networkID].lastTick = GetTickCount()
    end
end

RecallTracker()

class "Timez"

local lasttick = 0
local drawobjectstab = {}
local varobjecttable = {
	["itemzhonya_base_stasis.troy"] = { lifetime = 2500 },
	["vladimir_base_w_buf.troy"] = { lifetime = 2000 },
	["maokai_base_r_aura.troy"] = { lifetime = 10000},
	["card_yellow.troy"] = { lifetime = 6000},
	["card_blue.troy"] = { lifetime = 6000},
	["card_red.troy"] = { lifetime = 6000},
	["malzahar_base_r_tar.troy"] = { lifetime = 3000},
	["skarner_base_r_beam.troy"] = { lifetime = 2000},
	["undyingrage_glow.troy"] = { lifetime = 5000},
	["monkeyking_base_r_cas.troy"] = { lifetime = 4000},
	["eyeforaneye"] = { lifetime = 2000},
	["nickoftime_tar.troy"] = { lifetime = 5000},
	["vladimir_base_w_buf.troy"] = { lifetime = 2000},
	["karthus_base_r_cas.troy"] = { lifetime = 3000},
	["alistar_trample_"] = { lifetime = 7000},
	["shen_standunited_shield_v2.troy"] = { lifetime = 3000},
	["diplomaticimmunity_buf.troy"] = { lifetime = 7000} ,
	["olaf_ragnorok_"] = { lifetime = 6000},
	["morgana_base_r_indicator_ring.troy"] = { lifetime = 3500},
	["sion_base_r_cas.troy"] = { lifetime = 8000},
	["zac_r_tar.troy"] = { lifetime = 4000},
	["dr_mundo_heal.troy"] = { lifetime = 12000},
	["zhonyas_ring_activate.troy"] = { lifetime = 2500},
	["kennen_ss_aoe_"] = { lifetime = 3500},
	["akali_base_smoke_bomb_tar_team_"] = { lifetime = 8000},
	["masteryi_base_w_buf.troy"] = { lifetime = 4000},
	["w_windwall"] = { lifetime = 4000},
	["velkoz_base_r_beam_eye.troy"] = { lifetime = 2500},
	["lissandra_base_r_ring_"] = { lifetime = 1500},
	["lissandra_base_r_iceblock.troy"] = { lifetime = 2500},
	["shenteleport_v2.troy"] = { lifetime = 3000},
	["passive_death_activate.troy"] = { lifetime = 3000},
	["azir_base_r_soldiercape_"] = { lifetime = 5000},
	["zed_base_w_cloneswap_buf.troy"] = { lifetime = 4500},
	["zed_base_r_cloneswap_buf.troy"] = { lifetime = 7500},
	["leblanc_base_w_return_indicator.troy"] = { lifetime = 4000},
	["leblanc_base_rw_return_indicator.troy"] = { lifetime = 4000},
	["zhonyas_ring_activate.troy"] = { lifetime = 2500},
	["zilean_base_r_buf.troy"] = { lifetime = 3000},
	["lifeaura.troy"] = { lifetime = 4000},
	["global_ss_teleport_"] = { lifetime = 3500},
	["bard_base_e_door.troy"] = { lifetime = 10000},
	["bard_base_r_stasis_skin_"] = { lifetime = 2500},
	["galio_beguilingstatue_taunt_indicator_team_"] = { lifetime = 2000},
	["absolutezero2_"] = { lifetime = 3000},
	["karthus_base_w_post"] = { lifetime = 5000},
	["karthus_base_r_cas.troy"] = { lifetime = 3000},
	["thresh_base_lantern_cas_"] = { lifetime = 6000},
	["viktor_catalyst_"] = { lifetime = 4000},
	["viktor_chaosstorm_"] = { lifetime = 7000},
	["pirate_cannonbarrage_aoe_indicator_"] = { lifetime = 7000},
	["jinx_base_e_mine_ready_"] = { lifetime = 4500},
	["zyra_r_cast_"] = { lifetime = 2000},
	["veigar_base_w_cas_"] = { lifetime = 1200},
	["veigar_base_e_cage_"] = { lifetime = 3000},
	["pantheon_base_r_indicator_red"] = { lifetime = 1500},
	["reapthewhirlwind_"] = { lifetime = 3000}
}

function Timez:__init()
    Menu.Timez:MenuElement({id = "Enabled", name = "Enabled", value = true})
	Menu.Timez:MenuElement({id = "FontSize", name = "Font size", value = 24, min = 5, max = 40, step = 1, identifier = ""})
    Menu.Timez:MenuElement({id = "TickLimiter", name = "Limit ticks", value = 200, min = 50, max = 1000, step = 1, tooltip = "Increase it if you have lags", identifier = ""})
    Menu.Timez:MenuElement({id = "TextColor", name = "Color", color = DrawColor(255, 255, 255, 255)})
    Menu.Timez:MenuElement({id = "OffSetX", name = "OffSet X", value = 0, min = -50, max = 50, step = 1, identifier = ""})
    Menu.Timez:MenuElement({id = "OffSetY", name = "OffSet Y", value = 0, min = -50, max = 50, step = 1, identifier = ""})

	Callback.Add("Tick", function() self:Tick() end)
	Callback.Add("Draw", function() self:Draw() end)
	
end
function Timez:alreadyintable(table, element)
	for _, value in pairs(table) do
		if element.networkID == value.networkID then
			return true
		end
	end
	return false
end
function Timez:GetParticle()
	for i = 1, Game.ObjectCount() do
		local object = Game.Object(i)		
		if object and varobjecttable[object.name:lower()] and not self:alreadyintable(drawobjectstab, object) then
			table.insert(drawobjectstab, {networkID = object.networkID, object = object, endtick = GetTickCount() + varobjecttable[object.name:lower()].lifetime})
		end
	end
end

function Timez:Tick()
    if not Menu.Timez.Enabled:Value() then return end
	local ticklimiter = Menu.Timez.TickLimiter:Value()
	if GetTickCount() > lasttick + ticklimiter then
		self:GetParticle()
		lasttick = GetTickCount()
	end
end


function Timez:Draw()
    if not Menu.Timez.Enabled:Value() then return end
	local fontsize = Menu.Timez.FontSize:Value()
	for i, v in ipairs(drawobjectstab) do
		if not v then return end 
		if GetTickCount() > v.endtick + 500 then
			drawobjectstab[i] = nil
		else
			local bufftime = ((v.endtick - GetTickCount())/1000)
			if bufftime>0 then
                Draw.Text(string.sub(bufftime,0, 3), fontsize, v.object.pos:To2D().x - Menu.Timez.OffSetX:Value()*2, v.object.pos:To2D().y - Menu.Timez.OffSetY:Value()*2, Menu.Timez.TextColor:Value())
			end
		end
	end
end

Timez()
class "Darius"

function Darius:__init()
    --[[Data Initialization]]
    self.Allies, self.Enemies = {}, {}
    self.scriptVersion = "1.0"
    self:Spells()
    self:Menu()
    --[[Default Callbacks]]
    --Callback.Add("Load",          function() self:OnLoad()    end) --Just Use OnLoad()
    Callback.Add(
        "Tick",
        function()
            self:OnTick()
        end
    )
    Callback.Add(
        "Draw",
        function()
            self:OnDraw()
        end
    )
    --[[Orb Callbacks]]
    OnPreAttack(
        function(...)
            self:OnPreAttack(...)
        end
    )
    OnPostAttack(
        function(...)
            self:OnPostAttack(...)
        end
    )
    OnPreMovement(
        function(...)
            self:OnPreMovement(...)
        end
    )
    --[[Custom Callbacks]]
    OnInterruptable(
        function(unit, spell)
            self:OnInterruptable(unit, spell)
        end
    )
    OnDash(
        function(unit, unitPos, unitPosTo, dashSpeed, dashGravity, dashDistance)
            self:OnDash(unit, unitPos, unitPosTo, dashSpeed, dashGravity, dashDistance)
        end
    )
end

function Darius:Spells()
    self.Q =
        Spell(
        {
            Slot = 0,
            Range = 415,
            Delay = 0.75,
            Speed = huge,
            Radius = 250,
            Collision = false,
            From = myHero,
            Type = TYPE_PRESS
        }
    )
    self.W =
        Spell(
        {
            Slot = 1,
            Range = 300,
            Delay = 0.25,
            Speed = 1450,
            Radius = huge,
            Collision = false,
            From = myHero,
            Type = TYPE_PRESS
        }
    )
    self.E =
        Spell(
        {
            Slot = 2,
            Range = 490,
            Delay = 0.3,
            Speed = huge,
            Radius = huge,
            Collision = false,
            From = myHero,
            Type = TYPE_CONE
        }
    )
    self.R =
        Spell(
        {
            Slot = 3,
            Range = 460,
            Delay = 0.25,
            Speed = huge,
            Radius = huge,
            Collision = false,
            From = myHero,
            Type = TYPE_TARGET
        }
    )
end

function Darius:Menu()
    --Q--
    Menu.Q:MenuElement({name = " ", drop = {"Combo Settings"}})
    Menu.Q:MenuElement({id = "Combo", name = "Use on Combo", value = true})
    Menu.Q:MenuElement({id = "Mana", name = "Min Mana %", value = 15, min = 0, max = 100, step = 1})
    Menu.Q:MenuElement({name = " ", drop = {"Harass Settings"}})
    Menu.Q:MenuElement({id = "Harass", name = "Use on Harass", value = true})
    Menu.Q:MenuElement({id = "ManaHarass", name = "Min Mana %", value = 15, min = 0, max = 100, step = 1})
    Menu.Q:MenuElement({name = " ", drop = {"Misc"}})
    Menu.Q:MenuElement({id = "Auto", name = "Positioning Helper", value = true})
    --W--
    Menu.W:MenuElement({name = " ", drop = {"Combo Settings"}})
    Menu.W:MenuElement({id = "Combo", name = "Combo Mode", value = true})
    Menu.W:MenuElement({id = "Mana", name = "Min Mana %", value = 15, min = 0, max = 100, step = 1})
    Menu.W:MenuElement({name = " ", drop = {"Harass Settings"}})
    Menu.W:MenuElement({id = "Harass", name = "Harass Mode", value = true})
    Menu.W:MenuElement({id = "ManaHarass", name = "Min Mana %", value = 15, min = 0, max = 100, step = 1})
    --E--
    Menu.E:MenuElement({name = " ", drop = {"Combo Settings"}})
    Menu.E:MenuElement({id = "Combo", name = "Combo Mode", value = true})
    Menu.E:MenuElement({id = "Mana", name = "Min Mana %", value = 15, min = 0, max = 100, step = 1})
    Menu.E:MenuElement({name = " ", drop = {"Misc"}})
    Menu.E:MenuElement({id = "Auto", name = "Auto Use on Escaping Enemies", value = true})
    Menu.E:MenuElement({id = "Interrupt", name = "Interrupt Targets", type = MENU})
    Menu.E.Interrupt:MenuElement({id = "Loading", name = "Loading Champions...", type = SPACE})
    --R--
    Menu.R:MenuElement({name = " ", drop = {"Combo Settings"}})
    Menu.R:MenuElement({id = "Combo", name = "Use on Combo", value = true})
    Menu.R:MenuElement({id = "Mana", name = "Min Mana %", value = 0, min = 0, max = 100, step = 1})
    Menu.R:MenuElement({name = " ", drop = {"Misc"}})
    Menu.R:MenuElement({id = "Auto", name = "Auto Use on Killable", value = true})
    Menu.R:MenuElement({id = "Tweak", name = "Damage Mod +[%]", value = 0, min = -50, max = 50, step = 5})
    --Items--
    Menu:MenuElement({id = "Items", name = "Items Settings", type = MENU})
    Menu.Items:MenuElement({id = "Tiamat", name = "Use Tiamat", value = true})
    Menu.Items:MenuElement({id = "TitanicHydra", name = "Use Titanic Hydra", value = true})
    Menu.Items:MenuElement({id = "Hydra", name = "Use Ravenous Hydra", value = true})
    Menu.Items:MenuElement({id = "Youmuu", name = "Use Youmuu's", value = true})
    --Misc--
    Menu.Draw:MenuElement({id = "Helper", name = "Draw Q Helper Pos", value = true, leftIcon = icons.WR})
    Menu:MenuElement({name = "[NOX] " .. charName .. " Script", drop = {"Release_" .. self.scriptVersion}})
    --
    self.menuLoadRequired = true
    Callback.Add(
        "Tick",
        function()
            self:MenuLoad()
        end
    )
end

function Darius:MenuLoad()
    if self.menuLoadRequired then
        local count = HeroCount()
        if count == 1 then
            return
        end
        for i = 1, count do
            local hero = Hero(i)
            local charName = hero.charName
            if hero.team == TEAM_ALLY then
                insert(self.Allies, hero)
            else
                insert(self.Enemies, hero)
                Interrupter:AddToMenu(hero, Menu.E.Interrupt)
            end
        end
        local count = -13
        for _ in pairs(Menu.E.Interrupt) do
            count = count + 1
        end
        if count == 1 then
            Menu.E.Interrupt:MenuElement({name = "No Spells To Be Interrupted", drop = {" "}})
            Callback.Del(
                "Tick",
                function()
                    Interrupter:OnTick()
                end
            )
        end
        Menu.E.Interrupt.Loading:Hide(true)
        self.menuLoadRequired = nil
    else
        Callback.Del(
            "Tick",
            function()
                self:MenuLoad()
            end
        )
    end
end

function Darius:OnTick()
    if ShouldWait() then
        return
    end
    --
    self.enemies = GetEnemyHeroes(500)
    self.target = GetTarget(self.Q.Range, 0)
    self.mode = GetMode()
    --
    self:UpdateItems()
    if myHero.isChanneling then
        return
    end
    self:Auto()
    --
    if not self.mode then
        return
    end
    local executeMode = self.mode == 1 and self:Combo() or self.mode == 2 and self:Harass()
end

function Darius:OnPreMovement(args) --args.Process|args.Target
    if ShouldWait() then
        args.Process = false
        return
    end
    --Q Helper logic
    if self.moveTo then
        if GetDistance(self.moveTo) < 20 then
            args.Process = false
        elseif not MapPosition:inWall(self.moveTo) then
            args.Target = self.moveTo
        end
    end
end

function Darius:OnPreAttack(args) --args.Process|args.Target
    if ShouldWait() then
        args.Process = false
        return
    end
end

function Darius:OnPostAttack()
    local target = GetTargetByHandle(myHero.attackData.target)
    if ShouldWait() or not IsValidTarget(target) then
        return
    end
    if target.type == Obj_AI_Hero then
        if
            self.W:IsReady() and
                ((self.mode == 1 and Menu.W.Combo:Value()) or (self.mode == 2 and Menu.W.Harass:Value())) and
                ManaPercent(myHero) >= Menu.W.Mana:Value()
         then
            self.W:Cast()
            ResetAutoAttack()
        elseif self.mode == 1 then
            self:UseItems(target)
        end
    end
end

function Darius:OnInterruptable(unit, spell)
    if ShouldWait() then
        return
    end
    if Menu.E.Interrupt[spell.name]:Value() and IsValidTarget(enemy, self.E.Range) and self.E:IsReady() then
        self.E:Cast(unit)
    end
end

function Darius:OnDash(unit, unitPos, unitPosTo, dashSpeed, dashGravity, dashDistance)
    if ShouldWait() then
        return
    end
    if
        Menu.E.Auto:Value() and IsValidTarget(unit, self.E.Range) and GetDistance(unitPosTo) > 300 and
            unit.team == TEAM_ENEMY and
            not IsFacing(unit, myHero)
     then
        self.E:CastToPred(unit, 2)
    end
end

function Darius:Auto()
    if
        self.enemies and (Menu.R.Auto:Value() or (Menu.R.Combo:Value() and self.mode == 1)) and
            self.R:IsReady()
     then
        for i = 1, #(self.enemies) do
            local enemy = self.enemies[i]
            if self.R:GetDamage(enemy) * self:GetUltMultiplier(enemy) >= enemy.health + enemy.shieldAD then
                self.R:Cast(enemy)
                break
            end
        end
    end
end

function Darius:Combo()
    for i = 1, #(self.enemies) do
        local enemy = self.enemies[i]
        self:Youmuu(enemy)
        local distance = GetDistance(enemy)
        if
            self.E:IsReady() and Menu.E.Combo:Value() and ManaPercent(myHero) >= Menu.E.Mana:Value() and
                distance >= 350 and
                distance <= self.E.Range and
                not IsFacing(enemy, myHero)
         then
            self.E:Cast(enemy)
        end
    end
    if
        self.Q:IsReady() and Menu.Q.Combo:Value() and self.target and
            ((self.W:IsReady() == false and not HasBuff(myHero, "DariusNoxianTacticsONH")) or
                GetDistance(self.target) > 200) and
            ManaPercent(myHero) >= Menu.Q.Mana:Value()
     then
        self.Q:Cast()
    end
end

function Darius:Harass()
    if
        self.target and self.Q:IsReady() and Menu.Q.Harass:Value() and
            ManaPercent(myHero) >= Menu.Q.Mana:Value()
     then
        self.Q:Cast()
    end
end

function Darius:OnDraw()
    local drawSettings = Menu.Draw
    if Menu.Q.Auto:Value() and HasBuff(myHero, "dariusqcast") and self.target then
        self.moveTo = self.target:GetPrediction(huge, 0.2):Extended(myHero.pos, ((self.Q.Radius + self.Q.Range) / 2))
    else
        self.moveTo = nil
    end
    if drawSettings.ON:Value() then
        local qLambda = drawSettings.Q:Value() and self.Q and self.Q:Draw(66, 244, 113)
        local wLambda = drawSettings.W:Value() and self.W and self.W:Draw(66, 229, 244)
        local eLambda = drawSettings.E:Value() and self.E and self.E:Draw(244, 238, 66)
        local rLambda = drawSettings.R:Value() and self.R and self.R:Draw(244, 66, 104)
        local mLambda = drawSettings.Helper:Value() and self.moveTo and Draw.Circle(self.moveTo, 50)
        local tLambda =
            drawSettings.TS:Value() and self.target and
            DrawMark(self.target.pos, 3, self.target.boundingRadius, DrawColor(255, 255, 0, 0))
        if self.enemies and drawSettings.Dmg:Value() and self.R:IsReady() then
            for i = 1, #self.enemies do
                local enemy = self.enemies[i]
                self.R:DrawDmg(enemy, self:GetUltMultiplier(enemy), 0)
            end
        end
    end
end

function Darius:GetStacks(target)
    local buff = GetBuffByName(target, "DariusHemo")
    return buff and buff.count or 0
end

function Darius:GetUltMultiplier(target)
    return 0.855 * (1 + 0.2 * self:GetStacks(target) + Menu.R.Tweak:Value() / 100) --0.84 because dmgLib is off
end

local ItemHotKey = {
    [ITEM_1] = HK_ITEM_1,
    [ITEM_2] = HK_ITEM_2,
    [ITEM_3] = HK_ITEM_3,
    [ITEM_4] = HK_ITEM_4,
    [ITEM_5] = HK_ITEM_5,
    [ITEM_6] = HK_ITEM_6
}
function Darius:UpdateItems()
    --[[
            Youmuu = 3142
            Tiamat = 3077
            Hidra = 3074
            Titanic = 3748
        ]]
    for i = ITEM_1, ITEM_7 do
        local id = myHero:GetItemData(i).itemID
        --[[In Case They Sell Items]]
        if self.Youmuus and i == self.Youmuus.Index and id ~= 3142 then
            self.Youmuus = nil
        elseif self.Tiamat and i == self.Tiamat.Index and id ~= 3077 then
            self.Tiamat = nil
        elseif self.Hidra and i == self.Hidra.Index and id ~= 3074 then
            self.Hidra = nil
        elseif self.Titanic and i == self.Titanic.Index and id ~= 3748 then
            self.Titanic = nil
        end
        ---
        if id == 3142 then
            self.Youmuus = {Index = i, Key = ItemHotKey[i]}
        elseif id == 3077 then
            self.Tiamat = {Index = i, Key = ItemHotKey[i]}
        elseif id == 3074 then
            self.Hidra = {Index = i, Key = ItemHotKey[i]}
        elseif id == 3748 then
            self.Titanic = {Index = i, Key = ItemHotKey[i]}
        end
    end
end

function Darius:UseItems(target)
    if self.Tiamat or self.Hidra then
        self:Hydra(target)
    elseif self.Titanic then
        self:TitanicHydra(target)
    end
end

function Darius:UseItem(key, reset)
    KeyDown(key)
    KeyUp(key)
    return reset and ResetAutoAttack()
end

function Darius:Youmuu(target)
    if
        self.Youmuus and Menu.Items.Youmuu:Value() and myHero:GetSpellData(self.Youmuus.Index).currentCd == 0 and
            IsValidTarget(target, 600)
     then
        self:UseItem(self.Youmuus.Key, false)
    end
end

function Darius:TitanicHydra(target)
    if
        self.Titanic and Menu.Items.TitanicHydra:Value() and
            myHero:GetSpellData(self.Titanic.Index).currentCd == 0 and
            IsValidTarget(target, 380)
     then
        self:UseItem(self.Titanic.Key, true)
    end
end

function Darius:Hydra(target)
    if
        self.Hidra and Menu.Items.Hydra:Value() and myHero:GetSpellData(self.Hidra.Index).currentCd == 0 and
            IsValidTarget(target, 380)
     then
        self:UseItem(self.Hidra.Key, true)
    elseif
        self.Tiamat and Menu.Items.Tiamat:Value() and myHero:GetSpellData(self.Tiamat.Index).currentCd == 0 and
            IsValidTarget(target, 380)
     then
        self:UseItem(self.Tiamat.Key, true)
    end
end

Darius()

