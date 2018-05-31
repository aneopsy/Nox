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
