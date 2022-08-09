if Player.CharName ~= "Talon" then return end

module("UnrulyTalon", package.seeall, log.setup)
clean.module("UnrulyTalon", clean.seeall, log.setup)
CoreEx.AutoUpdate("https://raw.githubusercontent.com/hagbardlol/Public/main/UnrulyTalon.lua", "1.0.4")

local insert = table.insert
local max, min = math.max, math.min

local _SDK = _G.CoreEx
local Console, ObjManager, EventManager, Geometry, Input, Renderer, Enums, Game = _SDK.Console, _SDK.ObjectManager, _SDK.EventManager, _SDK.Geometry, _SDK.Input, _SDK.Renderer, _SDK.Enums, _SDK.Game
local Menu, Orbwalker, Collision, Prediction, HealthPred = _G.Libs.NewMenu, _G.Libs.Orbwalker, _G.Libs.CollisionLib, _G.Libs.Prediction, _G.Libs.HealthPred
local DmgLib, ImmobileLib, Spell = _G.Libs.DamageLib, _G.Libs.ImmobileLib, _G.Libs.Spell

---@type TargetSelector
local TS = _G.Libs.TargetSelector()
local Talon = {}

local spells = {
    Q = Spell.Targeted({
        Slot            = Enums.SpellSlots.Q,
        Range           = 500,
        Speed           = 1400, 
        Delay           = 0, 
    }),
    QM = Spell.Targeted({
        Slot            = Enums.SpellSlots.Q,
        Range           = 300,
        Delay           = 0.25, 
    }),
    W = Spell.Skillshot({
        Slot            = Enums.SpellSlots.W,
        Range           = 750,
        ConeAngleRad    = 40 * math.pi / 180,
        Speed           = 1450,
        Delay           = 0.25,
        Type            = "Cone",
        Collisions      = { WindWall = true },
    }),
    E = Spell.Skillshot({
        Slot            = Enums.SpellSlots.E,
        Range           = 750,
        Radius          = 50,
        Delay           = 0.25,
        Type            = "Circular"
    }),
    R = Spell.Active({
        Slot            = Enums.SpellSlots.R,
        Range           = 550,
        Delay           = 0.25,
    }),
    Flash = Spell.Skillshot({
        Slot            = Enums.SpellSlots.Unknown,
        Range           = 400,
        Delay           = 0,
    })
}

local function IsEnabledAndReady(spell, mode)
    return Menu.Get(mode .. ".Use"..spell, true) and spells[spell]:IsReady()
end

function Talon.LoadMenu()
    Menu.RegisterMenu("UnrulyTalon", "Unruly Talon", function ()
        Menu.ColumnLayout("cols", "cols", 4, true, function()
           Menu.NewTree("Drawing Options", "Drawing Options", function()
            Menu.Separator("Drawing Options")
            Menu.Checkbox("Drawing.Q.Enabled",  "Draw [Q] Range", true)
            Menu.ColorPicker("Drawing.Q.Color", "Color [Q]", 0xEF476FFF) 
            Menu.Checkbox("Drawing.W.Enabled",  "Draw [W] Range", true)
            Menu.ColorPicker("Drawing.W.Color", "Color [W]", 0x118AB2FF)   
            Menu.Checkbox("Drawing.R.Enabled",  "Draw [R] Range", true) 
            Menu.ColorPicker("Drawing.R.Color", "Color [R]", 0xFFD166FF)
        end)

            Menu.NewTree("Combo Settings", "Combo Settings", function()
            Menu.Separator("Combo Settings")
            Menu.Checkbox("Combo.UseQ", "Use [Q]", true) 
            Menu.Checkbox("Combo.UseW", "Use [W]", true)
            Menu.Checkbox("Combo.UseR", "Use [R]", true)  
        end)
        end)

            Menu.NewTree("Harass Settings", "Harass Settings", function()
            Menu.Separator("Harass Settings")
            Menu.Checkbox("Harass.UseQ", "Use [Q]", true) 
            Menu.Checkbox("Harass.UseW", "Use [W]", true)
        end)

            Menu.NewTree("Lane Clear Settings", "Lane Clear Settings", function()
            Menu.Separator("Lane Clear Settings")
            Menu.Checkbox("Clear.FarmQ",   "Use [Q]", true)
            Menu.Checkbox("Clear.FarmW",   "Use [W]", true)
            Menu.Separator("FastClear")
            Menu.Checkbox("Clear.PushQ",   "Use [Q]", true)          
            Menu.Checkbox("Clear.PushW",   "Use [W]", true)
        end)
            
            Menu.NewTree("Jungle Clear Settings", "Jungle Clear Settings", function()
            Menu.Separator("Jungle Clear Settings")
            Menu.Checkbox("Jungle.UseQ",   "Use [Q]", true)       
            Menu.Checkbox("Jungle.UseW",   "Use [W]", true)
            Menu.Separator("Flee")
            Menu.Checkbox("Flee.UseE",   "Use [E]", true)             
        end)    

        Menu.ColumnLayout("cols2", "cols2", 2, true, function()
            Menu.NewTree("R Settings", "R Settings", function()
            Menu.Separator("Settings [R]")
            Menu.Checkbox("ComboR.Surrounded", "When Surrounded", true) 
            Menu.Indent(function() 
                Menu.Slider("ComboR.SurroundedMin", "Min X Enemies", 3, 2, 5)
            end)                 
            Menu.Checkbox("ComboR.Duel", "To Duel", true) 
            Menu.SameLine()
            Menu.Separator("Left Click Target!", 0xFF0000FF)

            Menu.Indent(function()
                local added = {}
                for k, v in pairs(ObjManager.Get("enemy", "heroes")) do
                    local charName = v.CharName
                    if not added[charName] then
                        added[charName] = true
                        Menu.Checkbox("ComboR.Duel." .. charName, charName, true)
                    end
                end
            end) 
        end)
            Menu.NextColumn()
            Menu.Separator("Left Click Target!")
            Menu.Keybind("Burst.Key", "Burst Key", string.byte('T'), false, false, true)
            Menu.Checkbox("Burst.Flash", "Use Flash", true)
        end)
            Menu.Separator("Author: Thorn")
    end)
end

function Talon.Combo(lagfree)  Talon.ComboLogic("Combo", lagfree)  end
function Talon.Harass(lagfree) Talon.ComboLogic("Harass", lagfree) end
function Talon.OnPreMove(args) 
    if IsEnabledAndReady("E", Orbwalker.GetMode()) then
        local pPos = Player.Position
        local wallCol = Collision.SearchWall(pPos, args.Position, 70, 25000, 0)
        if wallCol.Result then
            local wallExt = wallCol.Positions[1]:Extended(pPos, -100)
            for _, poly in pairs(Talon.WallCDs) do
                if poly:Contains(wallExt) then
                    return
                end
            end
            args.Position = wallCol.Positions[1]
            spells.E:Cast(Renderer.GetMousePos())
        end
    end
end
function Talon.Waveclear(lagfree)
    local fastClear = Orbwalker.IsFastClearEnabled()
    local lastTarg = Orbwalker.GetLastTarget()
       
    if lagfree == 2 and spells.Q:IsReady() then
        local qMonster = lastTarg and lastTarg.IsMonster and Menu.Get("Jungle.UseQ")
        if qMonster and TS:IsValidAutoRange(lastTarg) then
            if spells.Q:Cast(lastTarg) then
                return
            end
        end

        if fastClear and Menu.Get("Clear.PushQ") then
            local pPos = Player.Position
            for i, obj in ipairs(ObjManager.GetNearby("enemy", "minions")) do
                if obj.IsTargetable and spells.Q:IsInRange(obj.Position) then
                    local isEmpower = obj:Distance(pPos) <= spells.QM.Range
                    local extraAA = Orbwalker.GetAutoAttackDamage(obj)
                    if ((isEmpower and spells.QM) or spells.Q):CanKillTarget(obj, isEmpower and "Empowered", extraAA) and spells.Q:Cast(obj) then
                        return
                    end
                end
            end
        end
    end
    if lagfree == 4 and spells.W:IsReady() then        
        local wMonster = lastTarg and lastTarg.IsMonster and Menu.Get("Jungle.UseW")
        if wMonster and TS:IsValidAutoRange(lastTarg) then
            if spells.W:Cast(lastTarg:FastPrediction(500)) then
                return
            end
        end

        if fastClear and Menu.Get("Clear.PushW") then
            if spells.W:CastIfWillHit(3, "minions") then
                return
            end
        end
    end  
end

function Talon.IsInvisible()
    return Player.IsStealthed
end

function Talon.GetBleedStacks(obj)
    return obj:GetBuffCount("TalonPassiveStack")
end

function Talon.ResetBurstMode()
    Talon.BurstStage = nil
    Talon.BurstTarget = nil
end

function Talon.BurstLogic()
    if not Menu.Get("Burst.Key") then
        Talon.BurstWaitMsg = nil
        return
    end

    Orbwalker.Orbwalk(nil, nil, "Flee")
    local forced = TS:GetForcedTarget() 
    if Talon.BurstTarget then
        --[[Lost Target Before Starting Burst]]
        if not forced and Talon.BurstStage == 1 then
            Talon.BurstStage = nil
            Talon.BurstTarget = nil
            Talon.BurstWaitMsg = "Left Click A Target!"
            return
        end
    elseif forced and TS:IsValidTarget(forced) then
        Talon.BurstStage = 1
        Talon.BurstTarget = forced
    else
        Talon.BurstWaitMsg = "Left Click A Target!"
        return
    end    

    local target = Talon.BurstTarget
    if not TS:IsValidTarget(target) then
        Talon.BurstWaitMsg = "Invalid Target!"
        return
    end

    if Talon.BurstStage == 1 and not (spells.Q:IsReady() and spells.W:IsReady() and spells.R:IsReady()) then
        Talon.BurstWaitMsg = "Spell Not Ready!"
        return
    end

    local dist = target:Distance(Player)
    local canUseFlash = Menu.Get("Burst.Flash") and spells.Flash:IsReady()
    local maxRange = spells.Q.Range + (canUseFlash and spells.Flash.Range or 0)
    if dist > maxRange then
        Talon.BurstWaitMsg = "Out Of Range!"
        return
    end

    Talon.BurstWaitMsg = "Bursting!"
    if canUseFlash then        
        if dist > spells.W.Range and dist < (spells.W.Range + spells.Flash.Range) then
            spells.Flash:Cast(target.Position)
        end
    end

    if Talon.BurstStage == 1 and spells.W:CastOnHitChance(target, Enums.HitChance.Low) then
        return
    elseif Talon.BurstStage == 2 and spells.Q:Cast(target) then
        return
    elseif Talon.BurstStage == 3 and spells.R:Cast() then
        return
    end
end

function Talon.ComboLogic(mode, lagfree)     
    if lagfree == 1 and IsEnabledAndReady("W", mode) then
        for k, wTarget in ipairs(spells.W:GetTargets()) do
            if spells.W:CastOnHitChance(wTarget, Enums.HitChance.Low) then
                return
            end
        end
    end 
    if lagfree == 2 and IsEnabledAndReady("Q", mode) then
        local qTargs = spells.Q:GetTargets()

        for k, qTarget in ipairs(qTargs) do
            if Talon.GetBleedStacks(qTarget) >= 2 and spells.Q:Cast(qTarget) then
                return
            end
        end
        if not IsEnabledAndReady("W", mode) then
            for k, qTarget in ipairs(qTargs) do
                if spells.Q:Cast(qTarget) then
                    return
                end
            end
        end
    end   
    if lagfree == 3 and IsEnabledAndReady("R", mode) then
        local rTargets = spells.R:GetTargets()
        if Menu.Get("ComboR.Surrounded") and #rTargets >= Menu.Get("ComboR.SurroundedMin") then
            if spells.R:Cast() then
                return
            end
        end
        if Menu.Get("ComboR.Duel") then
            local forced = TS:GetForcedTarget()     
            if forced and Menu.Get("ComboR.Duel." .. forced.CharName, true) then
                for k, rTarget in ipairs(rTargets) do
                    if rTarget == forced and spells.R:Cast() then
                        return
                    end
                end
            end
        end
    end
end

function Talon.OnSpellCast(obj, spellcast)
    if not (obj.IsMe and Talon.BurstStage) then return end

    local castSlot = spellcast.Slot
    if castSlot == spells.W.Slot and Talon.BurstStage == 1 then
        Talon.BurstStage = 2
    elseif castSlot == spells.Q.Slot and Talon.BurstStage == 2 then
        Talon.BurstStage = 3
    elseif castSlot == spells.R.Slot and Talon.BurstStage == 3 then
        Talon.ResetBurstMode()
    end
end

function Talon.OnHighPriority(lagfree)
    if not Game.CanSendInput() then return end 
    
    Talon.BurstLogic()     
end
function Talon.OnNormalPriority(lagfree)     
    Orbwalker.MoveTo() -- Reset Forced Move Position   
    if not Game.CanSendInput() then return end 
    
    if not Orbwalker.CanCast() then return end
    local ModeToExecute = Talon[Orbwalker.GetMode()]
    if ModeToExecute then
        ModeToExecute(lagfree)
    end
end

local Nav = CoreEx.Nav
local function CheckNeighbors(x, y, result)   
    if x < 12 or x > 265 or y < 12 or y > 265 then 
        return 
    end 
    for i = x-1, x+1 do
        for j = y-1, y+1 do 
            if not result[i] then result[i] = {} end
            if result[i][j] == nil then
                result[i][j] = Nav.CellToWorld(i, j):IsWall()
                if result[i][j] then
                    CheckNeighbors(i, j, result)
                end
            end
        end
    end
end
local function FindContainingWall(pos)
    local cells = {}
    if pos:IsWall() and pos:IsWithinTheMap() then
        local cell = CoreEx.Nav.WorldToCell(pos)
        CheckNeighbors(cell.x, cell.z, cells)
    end    

    local unordTbl = {}
    for i, tbl in pairs(cells) do
        for j, v in pairs(tbl) do
            if not v then
                insert(unordTbl, Nav.CellToWorld(i, j):SetHeight(0))
            end
        end
    end

    local ordTbl = {}
    for i=#unordTbl, 1, -1 do
        ordTbl[i] = unordTbl[i]
        for j=i-1, 1, -1 do
            if unordTbl[j]:FastDistance(unordTbl[i]) <= 50 then
                unordTbl[i-1], unordTbl[j] = unordTbl[j], unordTbl[i-1]
            end
        end
    end  

    if #ordTbl > 3 then
        return Geometry.Polygon(ordTbl)
    end
end

function Talon.CheckParticle(obj)
    local name = obj.Name
    if name:starts_with("Talon") and name:find("_E_Edgemesh_") then
        Talon.WallCDs[obj.Handle] = FindContainingWall(obj.Position)
    end
end

function Talon.OnCreateObject(obj)
    if not obj.IsParticle then return end
    Talon.CheckParticle(obj)
end

function Talon.OnDeleteObject(obj)
    Talon.WallCDs[obj.Handle] = nil
end

function Talon.OnDraw()  
    -- for handle, poly in pairs(Talon.WallCDs) do
    --     local obj = ObjManager.GetObjectByHandle(handle)
    --     Renderer.DrawCircle3D(obj.Position, 25, nil, 2, 0xFFFF00FF)
    --     Renderer.DrawText(obj.Position:ToScreen(), nil, obj.Name)
    --     if poly then poly:Draw(0xFF0000FF) end
    -- end    

    local playerPos = Player.Position    
    for k, v in pairs(spells) do
        if Menu.Get("Drawing."..k..".Enabled", true) then
            Renderer.DrawCircle3D(playerPos, v.Range, 30, 2, Menu.Get("Drawing."..k..".Color")) 
        end
    end

    if Talon.BurstWaitMsg then
        Renderer.DrawTextOnCursor(Talon.BurstWaitMsg, Talon.BurstWaitMsg == "Bursting!" and 0x00FF00FF or 0xFF0000FF)
    end
end

function Talon.OnUnkillableMinion(minion)
    local mode = Orbwalker.GetMode()
    if (mode == "Waveclear" or mode == "Harass" or mode == "Lasthit") then
        if Menu.Get("Clear.FarmQ") and spells.Q:IsReady() then
            local extraAA = Orbwalker.GetAutoAttackDamage(minion)
            local isEmpower = minion:Distance(Player) <= spells.QM.Range            
            if ((isEmpower and spells.QM) or spells.Q):CanKillTarget(minion, isEmpower and "Empowered", extraAA) and spells.Q:Cast(minion) then
                return
            end
        end
        if Menu.Get("Clear.FarmW") and spells.W:IsReady() then
            if spells.W:CanKillTarget(minion) and spells.W:Cast(minion.Position) then
                return
            end
        end
    end
end

-- Load Script
local function Init()
    for i=Enums.SpellSlots.Summoner1, Enums.SpellSlots.Summoner2 do
        if Player:GetSpell(i).Name:lower():find("flash") then 
            spells.Flash.Slot = i
            break
        end
    end    
    Talon.LoadMenu()
    Talon.WallCDs = {}
    for k, obj in pairs(ObjManager.GetNearby("all", "particles")) do
        Talon.CheckParticle(obj)
    end

    for EventName, EventId in pairs(Enums.Events) do
        if Talon[EventName] then
            EventManager.RegisterCallback(EventId, Talon[EventName])
        end
    end
    return true
end
Init()
