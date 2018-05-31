--x--
icons, Menu = {}
icons.NOX = "https://raw.githubusercontent.com/aneopsy/Nox/master/Icons/NoxLogo.png"
Menu = MenuElement({name = "Nox | Champs tracker", type = MENU, leftIcon = icons.NOX})

-- Timez
Menu:MenuElement(
    {
        id = "Timez",
        name = "Timez",
        type = MENU,
        leftIcon = "https://raw.githubusercontent.com/aneopsy/Nox/master/Icons/drawings.png"
    }
)

-- Tracker
Menu:MenuElement(
    {
        type = MENU,
        id = "Tracker",
        name = "Tracker",
        leftIcon = "http://puu.sh/pPVxo/6e75182a01.png"
    }
)
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
    Menu.Timez:MenuElement({id = "TextColor", name = "Color", color = Draw.Color(255, 255, 255, 255)})
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
class "Tracker"

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
    for i = 1000, 1, -1 do
        if not FileExist(sprite) then
            DownloadFileAsync(
                url,
                sprite,
                function()
                end
            )
        else
            return
        end
    end
    if not FileExist(sprite) then
        print("Download path")
        DownloadFileAsync(
            "https://raw.githubusercontent.com/aneopsy/Nox/master/Icons/notFound.png",
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

function Tracker:__init()
    Menu.Tracker:MenuElement({id = "Enabled", name = "Enabled", value = true})
    Menu.Tracker:MenuElement({id = "gui", name = "Interface", type = MENU})
    Menu.Tracker.gui:MenuElement({id = "drawGUI", name = "Draw Interface", value = true})
    Menu.Tracker.gui:MenuElement({id = "vertical", name = "Draw Vertical", value = true})
    Menu.Tracker.gui:MenuElement({id = "x", name = "X", value = 50, min = 0, max = Game.Resolution().x, step = 1})
    Menu.Tracker.gui:MenuElement({id = "y", name = "Y", value = 50, min = 0, max = Game.Resolution().y, step = 1})

    Menu.Tracker:MenuElement({id = "alert", name = "Gank Alert", type = MENU})
    Menu.Tracker.alert:MenuElement(
        {id = "range", name = "Detection Range", value = 2500, min = 900, max = 4000, step = 10}
    )
    Menu.Tracker.alert:MenuElement({id = "drawGank", name = "Gank Alert", value = true})
    Menu.Tracker.alert:MenuElement({id = "drawGankFOW", name = "FOW Gank Alert", value = true})

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

function Tracker:GetSpriteByName(name)
    for i, summonerSprite in pairs(self.summonerSprites) do
        if summonerSprite[2] == name then
            return summonerSprite[1]
        end
    end
end

function Tracker:OnTick()
    for i = 1, Game.HeroCount() do
        local hero = Game.Hero(i)
        --OnGainVision
        if
            self.invChamp[hero.networkID] ~= nil and self.invChamp[hero.networkID].status == false and hero.visible and
                not hero.dead
         then
            if
                myHero.pos:DistanceTo(hero.pos) <= Menu.Tracker.alert.range:Value() + 90 and
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

function Tracker:OnDraw()
    if not Menu.Tracker.Enabled:Value() then
        return
    end
    for i, v in pairs(self.invChamp) do
        local d = v.champ.dead
        self.champSprite[v.champ.charName]:Draw(
            Menu.Tracker.gui.x:Value() + 22,
            Menu.Tracker.gui.y:Value() + 90 * (v.n - 1) + 16
        )
        if d then
            self.TrackerDeadSprite:Draw(
                Menu.Tracker.gui.x:Value() + 20,
                Menu.Tracker.gui.y:Value() + 90 * (v.n - 1) + 16
            )
        end
        self.TrackerHUDSprite:Draw(Menu.Tracker.gui.x:Value(), Menu.Tracker.gui.y:Value() + 90 * (v.n - 1) + 1)
        if v.status == false and not d then
            local timer = math.floor((GetTickCount() - v.lastTick) / 900)
            if timer < 350 then
                Draw.Text(
                    timer,
                    45,
                    Menu.Tracker.gui.x:Value() + 52 - 10 * string.len(timer),
                    Menu.Tracker.gui.y:Value() + 25 + 90 * (v.n - 1),
                    Draw.Color(200, 225, 225, 225)
                )
            else
                Draw.Text(
                    "AFK",
                    45,
                    Menu.Tracker.gui.x:Value() + 52 - 10 * 3,
                    Menu.Tracker.gui.y:Value() + 30 + 90 * (v.n - 1),
                    Draw.Color(200, 225, 0, 30)
                )
            end
            local eTimer = math.floor(v.lastPos:DistanceTo(myHero.pos) / v.champ.ms) - timer
            if eTimer > 0 then
                Draw.Text(
                    eTimer,
                    18,
                    Menu.Tracker.gui.x:Value() + 276 - 3 * (string.len(eTimer) - 1),
                    Menu.Tracker.gui.y:Value() + 40 + 90 * (v.n - 1),
                    Draw.Color(200, 225, 225, 225)
                )
            else
                self.TrackerDangerSprite:Draw(
                    Menu.Tracker.gui.x:Value() + 264,
                    Menu.Tracker.gui.y:Value() + 90 * (v.n - 1) + 32
                )
            end
        end

        if self.isRecalling[v.champ.networkID].status == true then
            if self.isRecalling[v.champ.networkID].proc.name == "Teleport" then
                Draw.Text(
                    "TELEPORT",
                    20,
                    Menu.Tracker.gui.x:Value() + 155,
                    Menu.Tracker.gui.y:Value() + 23 + 90 * (v.n - 1),
                    Draw.Color(200, 206, 89, 214)
                )
            else
                Draw.Text(
                    "RECALL",
                    20,
                    Menu.Tracker.gui.x:Value() + 155,
                    Menu.Tracker.gui.y:Value() + 23 + 90 * (v.n - 1),
                    Draw.Color(200, 16, 235, 240)
                )
            end
        elseif d then
            Draw.Text(
                "DEAD",
                20,
                Menu.Tracker.gui.x:Value() + 162,
                Menu.Tracker.gui.y:Value() + 23 + 90 * (v.n - 1),
                Draw.Color(200, 255, 0, 0)
            )
        elseif (v.lastPos == eBasePos or v.lastPos:DistanceTo(eBasePos) < 250) and v.status == false then
            Draw.Text(
                "BASE",
                20,
                Menu.Tracker.gui.x:Value() + 162,
                Menu.Tracker.gui.y:Value() + 23 + 90 * (v.n - 1),
                Draw.Color(200, 255, 255, 255)
            )
        elseif v.status == false then
            Draw.Text(
                "MISS",
                20,
                Menu.Tracker.gui.x:Value() + 162,
                Menu.Tracker.gui.y:Value() + 23 + 90 * (v.n - 1),
                Draw.Color(200, 255, 255, 255)
            )
        else
            Draw.Text(
                "VISIBLE",
                20,
                Menu.Tracker.gui.x:Value() + 152,
                Menu.Tracker.gui.y:Value() + 23 + 90 * (v.n - 1),
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
                Menu.Tracker.gui.x:Value() + 14,
                Menu.Tracker.gui.y:Value() + 77 + 90 * (v.n - 1)
            )
            local CutHP = {x = 0, y = 62, w = 4, h = 62 - 62 * (v.champ.health / v.champ.maxHealth)}
            self.TrackerHPSprite:Draw(
                CutHP,
                Menu.Tracker.gui.x:Value() + 88,
                Menu.Tracker.gui.y:Value() + 77 + 90 * (v.n - 1)
            )

            if self.isRecalling[v.champ.networkID].status == true then
                local r =
                    242 / self.isRecalling[v.champ.networkID].proc.totalTime *
                    (self.isRecalling[v.champ.networkID].proc.totalTime -
                        (GetTickCount() - self.isRecalling[v.champ.networkID].tick))
                local recallCut = {x = 0, y = 0, w = r, h = 15}
                self.TrackerLoadingSprite:Draw(
                    recallCut,
                    Menu.Tracker.gui.x:Value() + 98,
                    Menu.Tracker.gui.y:Value() + 75 + 90 * (v.n - 1)
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
                Menu.Tracker.gui.x:Value() + 107,
                Menu.Tracker.gui.y:Value() + 55 + 90 * (v.n - 1)
            )
            for z = 1, FData.level do
                Draw.Rect(
                    Menu.Tracker.gui.x:Value() + 104 + z * 3 - 1,
                    Menu.Tracker.gui.y:Value() + 68 + 90 * (v.n - 1),
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
                Menu.Tracker.gui.x:Value() + 126,
                Menu.Tracker.gui.y:Value() + 55 + 90 * (v.n - 1)
            )
            for z = 1, FData.level do
                Draw.Rect(
                    Menu.Tracker.gui.x:Value() + 123 + z * 3 - 1,
                    Menu.Tracker.gui.y:Value() + 68 + 90 * (v.n - 1),
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
                Menu.Tracker.gui.x:Value() + 145,
                Menu.Tracker.gui.y:Value() + 55 + 90 * (v.n - 1)
            )
            for z = 1, FData.level do
                Draw.Rect(
                    Menu.Tracker.gui.x:Value() + 142 + z * 3 - 1,
                    Menu.Tracker.gui.y:Value() + 68 + 90 * (v.n - 1),
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
                Menu.Tracker.gui.x:Value() + 165,
                Menu.Tracker.gui.y:Value() + 55 + 90 * (v.n - 1)
            )
            for z = 1, FData.level do
                Draw.Rect(
                    Menu.Tracker.gui.x:Value() + 164 + z * 3 - 1,
                    Menu.Tracker.gui.y:Value() + 68 + 90 * (v.n - 1),
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
            SprIdx1:Draw(sprCut, Menu.Tracker.gui.x:Value() + 188, Menu.Tracker.gui.y:Value() + 55 + 90 * (v.n - 1))
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
            SprIdx2:Draw(sprCut, Menu.Tracker.gui.x:Value() + 208, Menu.Tracker.gui.y:Value() + 55 + 90 * (v.n - 1))
        end
    end
end

function Tracker:OnProcessRecall(unit, recall)
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

Tracker()

