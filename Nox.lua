--[[
        Nox.lua
        AneoPsy
--]]

if _G.Nox_Loaded then
    return
end

local open = io.open
local concat = table.concat
local rep = string.rep
local format = string.format
local insert = table.insert

local NOX_PATH = COMMON_PATH .. "Nox/"
local dotlua = ".lua"
local charName = myHero.charName
local shouldLoad = {}

local function readAll(file)
    local f = assert(open(file, "r"))
    local content = f:read("*all")
    f:close()
    return content
end
print("[NOX] Loader")
--NOX--
local function AutoUpdate()
    local SCRIPT_URL = "https://raw.githubusercontent.com/aneopsy/Nox/master/"
    local NOX_URL = "https://raw.githubusercontent.com/aneopsy/Nox/master/Common/Nox/"
    local versionControl = NOX_PATH .. "versionControl.lua"
    local versionControlNew = NOX_PATH .. "versionControlNew.lua"
    --
    local function serializeTable(val, name, depth)
        skipnewlines = false
        depth = depth or 0
        local res = rep(" ", depth)
        if name then
            res = res .. name .. " = "
        end
        if type(val) == "table" then
            res = res .. "{" .. "\n"
            for k, v in pairs(val) do
                res = res .. serializeTable(v, k, depth + 4) .. "," .. "\n"
            end
            res = res .. rep(" ", depth) .. "}"
        elseif type(val) == "number" then
            res = res .. tostring(val)
        elseif type(val) == "string" then
            res = res .. format("%q", val)
        end
        return res
    end
    --
    local function TextOnScreen(str)
        local res = Game.Resolution()
        Callback.Add(
            "Draw",
            function()
                Draw.Text(str, 64, res.x / 2 - (#str * 10), res.y / 2, Draw.Color(255, 255, 0, 0))
            end
        )
    end
    --
    local function DownloadFile(from, to, filename)
        DownloadFileAsync(
            from .. filename,
            to .. filename,
            function()
            end
        )
        repeat
        until FileExist(to .. filename)
    end
    --
    local function GetVersionControl()
        if not FileExist(versionControl) then
            DownloadFileAsync(
                NOX_URL .. "versionControl_default",
                versionControl,
                function()
                end
            )
            repeat
            until FileExist(versionControl)
        end
        DownloadFileAsync(
            NOX_URL .. "versionControl.lua",
            versionControlNew,
            function()
            end
        )
        repeat
        until FileExist(versionControlNew)
        return true
    end
    --
    local function UpdateVersionControl(t)
        local str = serializeTable(t, "Data") .. "\n\nreturn Data"
        local f = assert(open(versionControl, "w"))
        f:write(str)
        f:close()
    end
    --
    local function CheckUpdate()
        local currentData, latestData = dofile(versionControl), dofile(versionControlNew)
        --[[Loader Version Check]]
        if currentData.Loader.Version < latestData.Loader.Version then
            DownloadFile(SCRIPT_URL, SCRIPT_PATH, "Nox.lua")
            currentData.Loader.Version = latestData.Loader.Version
            TextOnScreen("[Nox Updated] Please Reload The Script! [F6]x2")
        end
        --[[Core Check]]
        if currentData.Core.Version < latestData.Core.Version then
            --DownloadFile(NOX_URL, NOX_PATH, "Core.lua")
            currentData.Core.Version = latestData.Core.Version
            currentData.Core.Changelog = latestData.Core.Changelog
        end
        --[[Dependencies Check]]
        for k, v in pairs(latestData.Dependencies) do
            if not currentData.Dependencies[k] or currentData.Dependencies[k].Version < v.Version then
                DownloadFile(NOX_URL, NOX_PATH, k .. dotlua)
                currentData.Dependencies[k] = {}
                currentData.Dependencies[k].Version = v.Version
            end
            local name = tostring(k)
            print("[NOX Dependencies] " .. name .. "-" .. v.Version)
            if v.Version >= 0 and name ~= "changelog" and name ~= "menuLoad" then
                shouldLoad[#shouldLoad + 1] = name
            end
        end
        --[[Utilities Check]]
        for k, v in pairs(latestData.Utilities) do
            if not currentData.Utilities[k] or currentData.Utilities[k].Version < v.Version then
                DownloadFile(NOX_URL, NOX_PATH, k .. dotlua)
                currentData.Utilities[k] = {}
                currentData.Utilities[k].Version = v.Version
            end
            if v.Version >= 1 then
                shouldLoad[#shouldLoad + 1] = tostring(k)
            end
        end
        table.sort(shouldLoad)
        insert(shouldLoad, 2, "menuLoad")
        UpdateVersionControl(currentData)
        return true
    end
    if GetVersionControl() then
        if CheckUpdate() then
            return true
        end
    end
end

local function LoadNOX()
    local function writeModule(content)
        local f = assert(open(NOX_PATH .. "activeModule.lua", content and "a" or "w"))
        if content then
            f:write(content)
            f:write("\n")
        end
        f:close()
    end
    --
    writeModule()
    for i = 1, #shouldLoad do
        local dependency = readAll(concat({NOX_PATH, shouldLoad[i], dotlua}))
        writeModule(dependency)
    end
    dofile(NOX_PATH .. "activeModule" .. dotlua)
end

--NOX--
function OnLoad()
    if AutoUpdate() then
        _G.NOX_Loaded = true
        --dofile(NOX_PATH .. "changelog" .. dotlua)
        LoadNOX()
    end
end
