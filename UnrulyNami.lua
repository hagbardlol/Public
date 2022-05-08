if Player.CharName ~= "Nami" then return end

module("UnrulyNami", package.seeall, log.setup)
clean.module("UnrulyNami", clean.seeall, log.setup)
CoreEx.AutoUpdate("https://github.com/hagbardlol/Public/raw/main/UnrulyNami.lua", "1.0.2")

local insert = table.insert
local max, min = math.max, math.min

local _SDK = _G.CoreEx
local Console, ObjManager, EventManager, Geometry, Input, Renderer, Enums, Game = _SDK.Console, _SDK.ObjectManager, _SDK.EventManager, _SDK.Geometry, _SDK.Input, _SDK.Renderer, _SDK.Enums, _SDK.Game
local Menu, Orbwalker, Collision, Prediction, HealthPred = _G.Libs.NewMenu, _G.Libs.Orbwalker, _G.Libs.CollisionLib, _G.Libs.Prediction, _G.Libs.HealthPred
local DmgLib, ImmobileLib, Spell = _G.Libs.DamageLib, _G.Libs.ImmobileLib, _G.Libs.Spell

---@type TargetSelector
local TS = _G.Libs.TargetSelector()
local Nami = {}

local spells = {
    Q = Spell.Skillshot({
        Slot            = Enums.SpellSlots.Q,
        Range           = 875,
        Radius          = 150,
        Delay           = 1, --Check 1.25
        Type            = "Circular",
        Collisions      = { WindWall = true },
    }),
    W = Spell.Targeted({
        Slot            = Enums.SpellSlots.W,
        Range           = 725,
        Speed           = 1450,
        Delay           = 0.25,
        Collisions      = { WindWall = true },
    }),
    E = Spell.Targeted({
        Slot            = Enums.SpellSlots.E,
        Range           = 800,
        Delay           = 0
    }),
    R = Spell.Skillshot({
        Slot            = Enums.SpellSlots.R,
        Range           = 1250, --2750
        Speed           = 850,
        Radius          = 250,
        Delay           = 0.5,
        Type            = "Linear",
        Collisions      = { WindWall = true },
    }),
}

local function IsEnabledAndReady(spell, mode)
    return Menu.Get(mode .. ".Use"..spell, true) and spells[spell]:IsReady()
end

function Nami.LoadMenu()
    Menu.RegisterMenu("UnrulyNami", "Unruly Nami", function ()

        Menu.ColumnLayout("cols", "cols", 4, true, function()
            Menu.ColoredText("Combo", 0xFFD700FF, true)
            Menu.Checkbox("Combo.UseQ", "Use [Q]", true) 
            Menu.Checkbox("Combo.UseW", "Use [W]", true)
            Menu.Checkbox("Combo.UseE", "Use [E]", true)
            Menu.Checkbox("Combo.UseR", "Use [R]", true)
            Menu.Indent(function() 
                Menu.Slider("Combo.MinR", "Min", 3, 2, 5)
            end)

            Menu.NextColumn()

            Menu.ColoredText("Harass", 0xFFD700FF, true)
            Menu.Checkbox("Harass.UseQ", "Use [Q]", true) 
            Menu.Checkbox("Harass.UseW", "Use [W]", true)
            Menu.Checkbox("Harass.UseE", "Use [E]", true)

            Menu.NextColumn()

            Menu.ColoredText("FastClear", 0xFFD700FF, true)
            Menu.Checkbox("Clear.PushQ",   "Use [Q]", true)
            Menu.Checkbox("Clear.PushE",   "Use [E]", true)

            Menu.NextColumn()
            
            Menu.ColoredText("Flee", 0xFFD700FF, true)
            Menu.Checkbox("Flee.UseQ",   "Use [Q]", true)             
            Menu.Checkbox("Flee.UseW",   "Use [W]", true)             
            Menu.Checkbox("Flee.UseE",   "Use [E]", true)             
            Menu.Checkbox("Flee.UseR",   "Use [R]", false)  
            Menu.Indent(function() 
                Menu.Slider("Flee.MinR", "Min", 2, 2, 5)
            end)           
        end)

        Menu.Separator()

        Menu.ColumnLayout("cols2", "cols2", 3, true, function()
            Menu.ColoredText("Misc", 0xFFD700FF, true)
            Menu.Checkbox("Misc.GapQ", "Gapclose [Q]", true)
            Menu.Checkbox("Misc.GapR", "Gapclose [R]", false)  
            Menu.Checkbox("Misc.IntQ", "Interrupt [Q]", true)                      
            Menu.Checkbox("Misc.IntR", "Interrupt [R]", false)

            Menu.NextColumn()

            Menu.ColoredText("Whitelist W", 0xFFD700FF, true)
            Menu.Slider("Whitelist.MinSelf", "Min Self", 50, 1, 100)
            Menu.Slider("Whitelist.MinAlly", "Min Ally", 25, 1, 100)
            Menu.Indent(function()
                local added = {}
                for k, v in pairs(ObjManager.Get("enemy", "heroes")) do
                    local charName = v.CharName
                    if not added[charName] then
                        added[charName] = true
                        Menu.Checkbox("Whitelist." .. charName, charName, true)
                    end
                end
            end) 
            
            Menu.NextColumn()

            Menu.ColoredText("Drawing", 0xFFD700FF, true)
            Menu.Checkbox("Drawing.Q.Enabled",  "Range [Q]", true)
            Menu.ColorPicker("Drawing.Q.Color", "Color [Q]", 0xEF476FFF) 
            Menu.Checkbox("Drawing.W.Enabled",  "Range [W]", true)
            Menu.ColorPicker("Drawing.W.Color", "Color [W]", 0x118AB2FF)               
            Menu.Checkbox("Drawing.E.Enabled",  "Range [E]", false)
            Menu.ColorPicker("Drawing.E.Color", "Color [E]", 0x118AB2FF)   
            Menu.Checkbox("Drawing.R.Enabled",  "Range [R]", true) 
            Menu.ColorPicker("Drawing.R.Color", "Color [R]", 0xFFD166FF)
        end)
    end)
end

function Nami.Combo(lagfree)  Nami.ComboLogic("Combo", lagfree)  end
function Nami.Harass(lagfree) Nami.ComboLogic("Harass", lagfree) end
function Nami.Flee(lagfree)   Nami.ComboLogic("Flee", lagfree) end
function Nami.Waveclear(lagfree)
    if not Orbwalker.IsFastClearEnabled() then return end
       
    if lagfree == 1 and Menu.Get("Clear.PushQ") and spells.Q:IsReady() then
        if spells.Q:CastIfWillHit(3, "minions") then
            return
        end
    end    
    if lagfree == 2 and Menu.Get("Clear.PushE") and spells.E:IsReady() then
        local minionsNearby = 0
        for k, v in ipairs(ObjManager.GetNearby("enemy", "minions")) do
            if v.IsTargetable then
                minionsNearby = minionsNearby + 1
            end
        end
        
        if minionsNearby >= 3 then 
            for k, obj in pairs(ObjManager.GetNearby("ally", "heroes")) do
                if not obj.IsMe and obj.IsTargetable and spells.E:Cast(obj) then
                    return
                end
            end
            if spells.E:Cast(Player) then
                return
            end
        end
    end
end

function Nami.HealLogic(onlySelf)
    if Player.IsRecalling or Player.IsInFountain then
        return
    end
    
    if Player.HealthPercent <= (Menu.Get("Whitelist.MinSelf")/100) then            
        if spells.W:Cast(Player) then
            return true
        end
    end
    
    if onlySelf then return end
    for k, obj in pairs(ObjManager.GetNearby("ally", "heroes")) do
        if not obj.IsMe and obj.IsTargetable then
            local whiteList = Menu.Get("Whitelist." .. obj.CharName, true)
            local lowHP = obj.HealthPercent <= (Menu.Get("Whitelist.MinAlly")/100)
            if whiteList and lowHP and spells.W:Cast(obj) then
                return true
            end
        end
    end
end
function Nami.ComboLogic(mode, lagfree)     
    if lagfree == 1 and IsEnabledAndReady("R", mode) then
        local minHit = Menu.Get(mode..".MinR")
        if spells.R:CastIfWillHit(minHit, "heroes") then
            return
        end
    end 
    if lagfree == 2 and IsEnabledAndReady("E", mode) then
        local enemyInRange = spells.E:GetTarget()
        if enemyInRange then
            local maxAD, bestTarg = 0, nil
            for k, v in ipairs(ObjManager.GetNearby("ally", "heroes")) do
                if spells.E:IsInRange(v) and v.IsTargetable then
                    local tAD = v.TotalAD
                    if tAD > maxAD then
                        maxAD = tAD
                        bestTarg = v
                    end
                end
            end
            if bestTarg and spells.E:Cast(bestTarg) then
                return
            end
        end
    end   
    if lagfree == 3 and IsEnabledAndReady("Q", mode) then
        for k, qTarget in ipairs(spells.Q:GetTargets()) do
            if spells.Q:CastOnHitChance(qTarget, Enums.HitChance.VeryHigh) then
                return
            end
        end
    end   
    if lagfree == 4 and IsEnabledAndReady("W", mode) then
        if Nami.HealLogic(mode == "Flee") then
            return
        end

        local wTarget = spells.W:GetTarget()
        if wTarget and spells.W:Cast(wTarget) then
            return
        end
    end 
end

---@param source AIBaseClient
---@param dash DashInstance
function Nami.OnGapclose(source, dash)
    if not source.IsEnemy then return end

    if Menu.Get("Misc.GapQ") and spells.Q:IsReady() then 
        if spells.Q:CastOnHitChance(source, Enums.HitChance.VeryHigh) then
            return
        end
    end    
    if Menu.Get("Misc.GapR") and spells.R:IsReady() then 
        if spells.R:CastOnHitChance(source, Enums.HitChance.VeryHigh) then
            return
        end
    end    
end

function Nami.OnInterruptibleSpell(Source, SpellCast, Danger, EndTime, CanMoveDuringChannel)
    if Danger < 3 or CanMoveDuringChannel or not Source.IsEnemy then return end
    
    if Menu.Get("Misc.IntQ") and spells.Q:IsReady() then 
        if spells.Q:CastOnHitChance(Source, Enums.HitChance.VeryHigh) then
            return
        end
    end    
    if Menu.Get("Misc.IntR") and spells.R:IsReady() then 
        if spells.R:CastOnHitChance(Source, Enums.HitChance.VeryHigh) then
            return
        end
    end
end

function Nami.OnNormalPriority(lagfree)     
    if not Game.CanSendInput() then return end 
    
    if not Orbwalker.CanCast() then return end    
    local ModeToExecute = Nami[Orbwalker.GetMode()]
    if ModeToExecute then
        ModeToExecute(lagfree)
    end
end

function Nami.OnDraw()
    local playerPos = Player.Position    
    for k, v in pairs(spells) do
        if Menu.Get("Drawing."..k..".Enabled", true) then
            Renderer.DrawCircle3D(playerPos, v.Range, 30, 2, Menu.Get("Drawing."..k..".Color")) 
        end
    end
end

-- Load Script
local function Init()    
    Nami.LoadMenu()    

    for EventName, EventId in pairs(Enums.Events) do
        if Nami[EventName] then
            EventManager.RegisterCallback(EventId, Nami[EventName])
        end
    end
    return true
end
Init()