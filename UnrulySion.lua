if Player.CharName ~= "Sion" then return end

module("UnrulySion", package.seeall, log.setup)
clean.module("UnrulySion", clean.seeall, log.setup)
CoreEx.AutoUpdate("https://raw.githubusercontent.com/hagbardlol/Public/main/UnrulySion.lua", "1.0.3")

local insert = table.insert
local max, min = math.max, math.min

local _SDK = _G.CoreEx
local Console, ObjManager, EventManager, Geometry, Input, Renderer, Enums, Game = _SDK.Console, _SDK.ObjectManager, _SDK.EventManager, _SDK.Geometry, _SDK.Input, _SDK.Renderer, _SDK.Enums, _SDK.Game
local Menu, Orbwalker, Collision, Prediction, HealthPred = _G.Libs.NewMenu, _G.Libs.Orbwalker, _G.Libs.CollisionLib, _G.Libs.Prediction, _G.Libs.HealthPred
local DmgLib, ImmobileLib, Spell = _G.Libs.DamageLib, _G.Libs.ImmobileLib, _G.Libs.Spell

---@type TargetSelector
local TS = _G.Libs.TargetSelector()
local Sion = {}

local spells = {
    Q = Spell.Skillshot({
        Slot            = Enums.SpellSlots.Q,
        Range           = 750,
        Radius          = 200,
        Delay           = 0, 
        Type            = "Linear",
    }),
    W = Spell.Active({
        Slot            = Enums.SpellSlots.W,
        Range           = 550,
        Delay           = 0, 
    }),
    E = Spell.Skillshot({
        Slot            = Enums.SpellSlots.E,
        Range           = 750,
        Speed           = 2500,
        Radius          = 100,
        Delay           = 0.25,
        Type            = "Linear",
        Collisions      = {Heroes=true, Minions=true, WindWall=true},
        MaxCollisions   = 10,
        UseHitbox       = true
    }),
    E2 = Spell.Skillshot({
        Slot            = Enums.SpellSlots.E,
        Range           = 1550,
        Speed           = 2500,
        Radius          = 100,
        Delay           = 0.25,
        Type            = "Linear",
        ExtraRange      = 775,
    }),
    R = Spell.Skillshot({
        Slot            = Enums.SpellSlots.R,
        Range           = 7600,
        Speed           = 950,
        Radius          = 200,
        Delay           = 0,
    })
}

local function IsEnabledAndReady(spell, mode)
    return Menu.Get(mode .. ".Use"..spell, true) and spells[spell]:IsReady()
end

function Sion.CheckPolygon(castPos, targets, time)
    local pP = Player.Position
    local eP = pP:Extended(castPos, 800)
    local cP = pP:Extended(castPos, 400)

    local perpend = (eP - pP):Perpendicular():Normalized()
    local Hitbox = Geometry.Polygon({
        pP + perpend * 170.0,
        pP - perpend * 170.0,
        eP - perpend * 270.0,
        eP + perpend * 270.0,
    })    

    local res = { HitValue=0, WillHit=0, Entering=0, Leaving=0 }
    for k, v in ipairs(targets) do
        local pos = v.Position
        local pred = v:FastPrediction((time or 0.35)*1000)

        local weight = 1 / max(25, pos:FastDistance(cP)) --Closer to Center = Best
        if Hitbox:Contains(pos) then
            res.WillHit = res.WillHit + 1
            res.HitValue = res.HitValue + weight

            if not Hitbox:Contains(pred) then
                res.Leaving = res.Leaving + 1
                res.HitValue = res.HitValue - weight * 0.5
            end
        elseif Hitbox:Contains(pred) then
            res.Entering = res.Entering + 1
            res.HitValue = res.HitValue + weight * 0.5
        end
    end

    Hitbox:Draw()
    Renderer.DrawTextOnTopLeft("HitValue: " .. res.HitValue)
    Renderer.DrawTextOnTopLeft("WillHit: "  .. res.WillHit)
    Renderer.DrawTextOnTopLeft("Entering: " .. res.Entering)
    Renderer.DrawTextOnTopLeft("Leaving: "  .. res.Leaving)

    return res
end

function Sion.LoadMenu()
    Menu.RegisterMenu("UnrulySion", "Unruly Sion", function ()

        Menu.ColumnLayout("cols", "cols", 4, true, function()
            Menu.ColoredText("Combo", 0xFFD700FF, true)
            Menu.Checkbox("Combo.UseQ", "Use [Q]", true) 
            Menu.Indent(function() 
                Menu.Slider("Combo.MinQ", "Min", 1, 1, 5)
            end) 
            Menu.Checkbox("Combo.UseW", "Use [W]", true)
            Menu.Checkbox("Combo.UseE", "Use [E]", true)
            Menu.Checkbox("Combo.UseR", "Use [R]", true)  
            Menu.ColoredText("  Only Melee!", 0xFFD700FF)

            Menu.NextColumn()

            Menu.ColoredText("Harass", 0xFFD700FF, true)
            Menu.Checkbox("Harass.UseQ", "Use [Q]", true) 
            Menu.Indent(function() 
                Menu.Slider("Harass.MinQ", "Min", 1, 1, 5)
            end) 
            Menu.Checkbox("Harass.UseW", "Use [W]", false)
            Menu.Checkbox("Harass.UseE", "Use [E]", true)

            Menu.NextColumn()

            Menu.ColoredText("Farm", 0xFFD700FF, true)
            Menu.Checkbox("Clear.FarmQ",   "Use [Q]", true)
            Menu.Checkbox("Clear.FarmE",   "Use [E]", true)
            Menu.ColoredText("FastClear", 0xFFD700FF, true)
            Menu.Checkbox("Clear.PushQ",   "Use [Q]", true)          
            Menu.Checkbox("Clear.PushW",   "Use [W]", true)
            Menu.Checkbox("Clear.PushE",   "Use [E]", true)

            Menu.NextColumn()
            
            Menu.ColoredText("Jungle", 0xFFD700FF, true)
            Menu.Checkbox("Jungle.UseQ",   "Use [Q]", true)       
            Menu.Checkbox("Jungle.UseW",   "Use [W]", true)
            Menu.Checkbox("Jungle.UseE",   "Use [E]", true)
            Menu.ColoredText("Flee", 0xFFD700FF, true)
            Menu.Checkbox("Flee.UseW",   "Use [W]", true)             
            Menu.Checkbox("Flee.UseE",   "Use [E]", true)             
        end)    

        Menu.Separator()

        Menu.NewTree("DrawTree", "Drawing Settings", function()
            Menu.Checkbox("Drawing.Q.Enabled",  "Draw [Q] Range", true)
            Menu.ColorPicker("Drawing.Q.Color", "Color [Q]", 0xEF476FFF) 
            Menu.Checkbox("Drawing.W.Enabled",  "Draw [W] Range", true)
            Menu.ColorPicker("Drawing.W.Color", "Color [W]", 0x118AB2FF)   
            Menu.Checkbox("Drawing.E.Enabled",  "Draw [E] Range", true) 
            Menu.ColorPicker("Drawing.E.Color", "Color [E]", 0xFFD166FF)
            Menu.Checkbox("Drawing.R_MM.Enabled",  "Draw [R] Minimap", true) 
            Menu.ColorPicker("Drawing.R_MM.Color", "Color [R] Minimap", 0xFFD166FF)
        end)
    end)
end

function Sion.Combo(lagfree)  Sion.ComboLogic("Combo", lagfree)  end
function Sion.Harass(lagfree) Sion.ComboLogic("Harass", lagfree) end
function Sion.Flee(lagfree) 
    if lagfree == 1 and IsEnabledAndReady("W", "Flee") and not Player:GetBuff("sionwshieldstacks") then
        if spells.W:GetTarget() and spells.W:Cast() then
            return
        end
    end 
    if lagfree == 2 and IsEnabledAndReady("E", "Flee") then
        for k, eTarg in ipairs(spells.E:GetTargets()) do
            if spells.E:CastOnHitChance(eTarg, Enums.HitChance.High) then
                return
            end
        end
    end
end
function Sion.Waveclear(lagfree)
    local fastClear = Orbwalker.IsFastClearEnabled()
    local lastTarg = Orbwalker.GetLastTarget()
       
    if lagfree == 1 and spells.E:IsReady() then        
        local eMonster = lastTarg and lastTarg.IsMonster and Menu.Get("Jungle.UseE")
        if eMonster and spells.E:IsInRange(lastTarg) then
            if spells.E:Cast(lastTarg:FastPrediction(spells.E.Delay*1000)) then
                return
            end
        end

        if fastClear and Menu.Get("Clear.PushE") then
            if spells.E:CastIfWillHit(3, "minions") then
                return
            end
        end
    end
    if lagfree == 2 and spells.Q:IsReady() then
        local qMonster = lastTarg and lastTarg.IsMonster and Menu.Get("Jungle.UseQ")
        if qMonster and TS:IsValidTarget(lastTarg, spells.Q.Range) then
            local isWorthCasting = lastTarg.Health > (Orbwalker.GetAutoAttackDamage(lastTarg) * 2)
            if isWorthCasting and spells.Q:Cast(lastTarg:FastPrediction(500)) then
                Sion.SearchQ = "Monsters"
                return
            end
        end

        if fastClear and Menu.Get("Clear.PushQ") then
            local minions = ObjManager.GetNearby("enemy", "minions")
            local bestPos, hitCount = spells.Q:GetBestLinearCastPos(minions)
            if bestPos and hitCount >= 4 and spells.Q:Cast(bestPos) then
                -- Sion.SearchQ = "Minions"
                return
            end
        end
    end

    if lagfree == 3 and spells.W:IsReady() then        
        local wMonster = lastTarg and lastTarg.IsMonster and Menu.Get("Jungle.UseW")
        if wMonster and spells.W:IsInRange(lastTarg) then
            if spells.W:Cast() then
                return
            end
        end

        if fastClear and Menu.Get("Clear.PushW") then
            local count = 0
            for i, obj in ipairs(ObjManager.GetNearby("enemy", "minions")) do
                if TS:IsValidTarget(obj, spells.W.Range) then
                    count = count + 1
                    if count >= 3 and spells.W:Cast() then
                        return
                    end
                end
            end
        end
    end  
end

function Sion.ComboLogic(mode, lagfree)      
    if lagfree == 1 and IsEnabledAndReady("W", mode) then
        if spells.W:GetTarget() and spells.W:Cast() then
            return
        end
    end 
    if lagfree == 2 and IsEnabledAndReady("E", mode) then
        for k, eTarg in ipairs(spells.E2:GetTargets()) do
            local pred = spells.E2:GetPrediction(eTarg)
            if pred and pred.HitChanceEnum >= Enums.HitChance.High then
                if #pred.CollisionObjects >= 1 or spells.E:IsInRange(pred.CastPosition) then
                    if spells.E:Cast(pred.CastPosition) then
                        return
                    end
                end
            end
        end
    end
    local waitForE = IsEnabledAndReady("E", mode) and not Player.Position:IsGrass()
    if lagfree == 3 and IsEnabledAndReady("Q", mode) and not waitForE then
        local qTargs = spells.Q:GetTargets()
        local pos, hit = spells.Q:GetBestCircularCastPos(qTargs)
        local r = Sion.CheckPolygon(pos, qTargs)
        if r.WillHit >= Menu.Get(mode .. ".MinQ") and r.Leaving == 0 then
            local maxRange = spells.Q.Range * 0.6
            if Player:Distance(pos) <= maxRange and spells.Q:Cast(pos) then
                Sion.SearchQ = "Heroes"
                return
            end
        end
    end
    if lagfree == 4 and IsEnabledAndReady("R", mode) then
        local targ = TS:GetTarget(-1)
        if targ and spells.R:GetDamage(targ) > spells.R:GetKillstealHealth(targ) and spells.R:Cast(targ.Position) then
            return
        end
    end
end

function Sion.OnHighPriority(lagfree)
    if not (spells.Q:IsReady() and Game.CanSendInput()) then return end 

    local mode = Orbwalker.GetMode()
    local canReleaseQ = Menu.Get(mode..".UseQ", true) or (mode == "Waveclear" and (Menu.Get("Jungle.UseQ") or Menu.Get("Clear.PushQ")))
    if not canReleaseQ then return end

    local aS = Player.ActiveSpell
    if aS and aS.Name == "SionQ" then
        if Sion.InstaReleaseQ and spells.Q:Cast(Renderer.GetMousePos()) then
            Sion.InstaReleaseQ = false
            return
        end
        local qTargs = {}
        if Sion.SearchQ then
            if Sion.SearchQ == "Heroes" then
                qTargs = spells.Q:GetTargets()
            else
                local team
                if Sion.SearchQ == "Minions"  then team = "enemy" end
                if Sion.SearchQ == "Monsters" then team = "neutral" end
                for k, v in ipairs(ObjManager.GetNearby(team, "minions")) do
                    if TS:IsValidTarget(v) and v.MaxHealth > 5 then
                        insert(qTargs, v)
                    end
                end
            end
        end
        if #qTargs > 0 then
            local r = Sion.CheckPolygon(aS.EndPos, qTargs)
            if r.WillHit == 0 or (r.Leaving > 0 and r.Leaving >= r.Entering) then                    
                if spells.Q:Cast(Renderer.GetMousePos()) then 
                    Sion.SearchQ = nil 
                    return
                end           
            end 
        end     
    end
end

function Sion.OnNormalPriority(lagfree)     
    if not Game.CanSendInput() then return end 
    
    if not Orbwalker.CanCast() then return end
    local ModeToExecute = Sion[Orbwalker.GetMode()]
    if ModeToExecute then
        ModeToExecute(lagfree)
    end
end

function Sion.OnDraw()  
    -- do 
    --     local targs = {}
    --     for k, v in ipairs(ObjManager.GetNearby("neutral", "minions")) do
    --         if v.MaxHealth > 5 and TS:IsValidTarget(v, 800) then
    --             insert(targs, v)
    --         end
    --     end

    --     local aS = Player.ActiveSpell
    --     local castPos = aS and aS.Name == "SionQ" and aS.EndPos or Renderer.GetMousePos()
    --     Sion.CheckPolygon(castPos, targs)
    -- end

    local playerPos = Player.Position 
    if Menu.Get("Drawing.R_MM.Enabled") then
        Renderer.DrawCircleMM(playerPos, spells.R.Range, 2, Menu.Get("Drawing.R_MM.Color")) 
    end  
    for k, v in pairs(spells) do
        if Menu.Get("Drawing."..k..".Enabled", true) then
            Renderer.DrawCircle3D(playerPos, v.Range, 30, 2, Menu.Get("Drawing."..k..".Color")) 
        end
    end
end

function Sion.OnUnkillableMinion(minion)
    local mode = Orbwalker.GetMode()
    if (mode == "Waveclear" or mode == "Harass" or mode == "Lasthit") then
        if Menu.Get("Clear.FarmQ") and spells.Q:IsReady() then
            if spells.Q:CanKillTarget(minion) and spells.Q:Cast(minion.Position) then
                Sion.InstaReleaseQ = true
                return
            end
        end
        if Menu.Get("Clear.FarmE") and spells.E:IsReady() then
            if spells.E:CanKillTarget(minion) and spells.E:Cast(minion.Position) then
                return
            end
        end
    end
end

-- Load Script
local function Init()    
    Sion.LoadMenu()
    
    for EventName, EventId in pairs(Enums.Events) do
        if Sion[EventName] then
            EventManager.RegisterCallback(EventId, Sion[EventName])
        end
    end
    return true
end
Init()
