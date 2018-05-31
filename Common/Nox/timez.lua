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