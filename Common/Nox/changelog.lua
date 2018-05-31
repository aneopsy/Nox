local charName = myHero.charName
local Timer = Game.Timer
local DrawColor = Draw.Color
local DrawLine = Draw.Line
local DrawRect = Draw.Rect
local DrawText = Draw.Text
--
local noxLogo = "MenuElement\\NoxLogo.png"
local starLogo = "MenuElement\\5stars.png"
--
local currentData = dofile(COMMON_PATH .. "Nox/versionControl.lua")
local mainText = currentData.Core.Changelog
local champText = currentData.Champions[charName].Changelog
--
local Color = {
    Black = DrawColor(0, 15, 15, 15),
    White = DrawColor(237, 255, 255, 255),
    Grey = DrawColor(200, 20, 20, 20)
}
--
local delta = 0
--
local wrSprite, starSprite

local function DrawRectOutline(x, y, width, height, thic, color)
    local A = {x = x - width / 2, y = y - height / 2}
    local B = {x = x - width / 2, y = y + height / 2}
    local C = {x = x + width / 2, y = y + height / 2}
    local D = {x = x + width / 2, y = y - height / 2}
    DrawLine(A.x, A.y, B.x, B.y, thic, color)
    DrawLine(B.x, B.y, C.x, C.y, thic, color)
    DrawLine(C.x, C.y, D.x, D.y, thic, color)
    DrawLine(D.x, D.y, A.x, A.y, thic, color)
end

class "Changelog"

function Changelog:__init()
    self:CheckSprites()
    --[[Animation Stuff]]
    self.stage = 1
    self.endT = Timer() + 2
    self.StageDuration = {1, 0.5, 0.3, 1, 0.5}
    --[[Dimension Stuff]]
    local res = Game.Resolution()
    self.x = res.x / 2
    self.y = res.y / 2
    self.width = res.x/2 --If anyone want to change sizes..
    self.height = res.y/2 --If anyone want to change sizes..
    --[[Initialization]]
    self.Load = true
    self.loadTime = Timer()
    Callback.Add(
        "Draw",
        function()
            self:OnDraw()
        end
    )
    Callback.Add(
        "WndMsg",
        function(...)
            self:WndMsg(...)
        end
    )
end

function Changelog:DownloadSprite(url, path)
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

function Changelog:CheckSprites()
    self:DownloadSprite("https://raw.githubusercontent.com/aneopsy/Nox/master/Icons/NoxLogo.png", noxLogo)
    self:DownloadSprite("https://raw.githubusercontent.com/aneopsy/Nox/master/Icons/5stars.png", starLogo)
    wrSprite = Sprite(noxLogo)
    starSprite = Sprite(starLogo)
    starSprite:SetScale(0.33)
end

function Changelog:OnDraw()
    if not self.Load or Timer() - self.loadTime < 1 then
        return
    end --couldnt get Callback.Del to work :/
    --
    self:UpdateStage()
    --
    local mod = ((self.stage <= 2 or self.stage == 5) and delta) or (self.stage == 4 and 1 - delta) or 1
    local args = {1.00 + 0.5 * mod, -0.74 * self.y * mod} --stages 2,3 and 4
    if self.stage == 1 then
        args = {0.01 + 0.99 * mod}
        self:Stage1(mod)
    elseif self.stage == 2 then
        self:Stage2(mod)
    elseif self.stage == 3 then
        self:Stage3(mod)
    elseif self.stage == 4 then
        self:Stage4(mod)
    elseif self.stage == 5 then
        args = {1.00 - 0.99 * mod}
    end
    --
    self:SpriteAnimation(args)
end

function Changelog:Stage1(scale)
    DrawLine(self.x, self.y - self.height, self.x, self.y + self.height, 2 * self.width, Color.Black)
    Color.Black = DrawColor(240 * scale, 15, 15, 15)
end

function Changelog:Stage2(scale)
    self:Stage1(1)
    DrawLine(self.x * 0.823, self.y * 0.5, self.x * 0.823 - self.x * 0.3125 * scale, self.y * 0.5, 4, Color.White)
    DrawLine(self.x * 1.180, self.y * 0.5, self.x * 1.180 + self.x * 0.3125 * scale, self.y * 0.5, 4, Color.White)
end

function Changelog:Stage3(scaleForStage2)
    self:Stage2(scaleForStage2)
    starSprite:Draw(self.x - (starSprite.width / 2), self.y * 0.5)
    starSprite:SetColor(Color.White)
    DrawRect(self.x * 0.965, self.y * 1.64, 70, 34, Color.Grey)
    --DrawRectOutline(self.x * 1.001, self.y * 1.673, 72, 36, Color.White)
    self:Texts()
end

function Changelog:Stage4()
    local b = 1 - delta
    Color.White = DrawColor(237 * b, 255, 255, 255)
    Color.Grey = DrawColor(200 * b, 20, 20, 20)
    Color.Black = DrawColor(240 * b, 15, 15, 15)
    self:Stage3(b)
end

function Changelog:WndMsg(msg, param)
    if self.stage == 3 and msg == 513 and param == 0 then
        local xPos, yPos = cursorPos.x, cursorPos.y
        --if xPos >= self.x * 0.96 and xPos <= self.x * 1.04 and yPos >= self.y * 1.64 and yPos <= self.y * 1.7 then
            self.stage = 4
            self.endT = Timer() + self.StageDuration[self.stage]
        --end
    end
end

function Changelog:UpdateStage()
    local t = Timer()
    if t >= self.endT and self.stage ~= 3 then
        if self.stage == 5 then
            self.Load = false
            return
        elseif self.stage == 2 then
            wrSprite = Sprite(noxLogo)
        end
        self.stage = self.stage + 1
        self.endT = t + self.StageDuration[self.stage]
    end
    delta = (t - self.endT) / self.StageDuration[self.stage] + 1
end

function Changelog:Texts()
    DrawText("NOX", 64, self.x - 54, self.y * 0.46, Color.White)
    DrawText("Changelog: ", 30, self.x * 0.54, self.y * 0.655, Color.White)
    DrawText(mainText, 20, self.x * 0.56, self.y * 0.737, Color.White)
    DrawText(charName .. " Changes:", 30, self.x * 1.15, self.y * 0.655, Color.White)
    DrawText(champText, 20, self.x * 1.17, self.y * 0.737, Color.White)
    --DrawText("OK", 22, self.x * 0.99, self.y * 1.65, Color.White)
end

function Changelog:SpriteAnimation(args)
    if args[1] then
        wrSprite:SetScale(args[1])
    end
    local w, h = wrSprite.width / 2, wrSprite.height / 2
    wrSprite:Draw(self.x - w + 2, self.y - h + (args[2] or 0))
end

if Timer() <= 30 then
    Changelog()
end
