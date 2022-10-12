local DreamTSLib = _G.DreamTS or require("DreamTS")

---@type SDK_SDK
local SDK = DreamTSLib.TargetSelectorSdk.SDK

---@type SDK_AIHeroClient
local myHero = SDK.Player

if myHero:GetCharacterName() ~= "Sivir" then return end

local Sivir = {}

local update_data = {
    Robur = {
        ScriptName = "CXSivir",
        ScriptVersion = "1.5",
        Repo = "https://raw.githubusercontent.com/hagbardlol/Public/main/"
    }
}

-- SDK.Common.AutoUpdate(update_data)

local DreamTS = DreamTSLib.TargetSelectorSdk
local DamageLib = Libs.DamageLib
local roburTS = _G.Libs.TargetSelector()

---@param objects SDK_GameObject[]
---@return SDK_AIHeroClient[]
local function GetHerosFromObjects(objects)
    local res = {}
    for i, obj in ipairs(objects) do
        res[i] = obj:AsHero()
    end
    return res
end

local enemies = GetHerosFromObjects(SDK.ObjectManager:GetEnemyHeroes())

local TargetedSpell = {
    ["Headbutt"]                    = {charName = "Alistar"     , slot = "W" , delay = 0   , speed = 2000       , isMissile = false},   -- seems speed base on distance, no idea with the forumla
    ["Frostbite"]                   = {charName = "Anivia"      , slot = "E" , delay = 0.25, speed = 1600       , isMissile = true },
    ["AnnieQ"]                      = {charName = "Annie"       , slot = "Q" , delay = 0.25, speed = 1400       , isMissile = true },
    ["BrandE"]                      = {charName = "Brand"       , slot = "E" , delay = 0.25, speed = math.huge  , isMissile = false},
    ["BrandR"]                      = {charName = "Brand"       , slot = "R" , delay = 0.25, speed = 1000       , isMissile = true },   -- to be comfirm brand R delay 0.25 or 0.5
    ["CassiopeiaE"]                 = {charName = "Cassiopeia"  , slot = "E" , delay = 0.15, speed = 2500       , isMissile = true },   -- delay to be comfirm
    ["CamilleR"]                    = {charName = "Camille"     , slot = "R" , delay = 0.5 , speed = math.huge  , isMissile = false},   -- delay to be comfirm
    ["Feast"]                       = {charName = "Chogath"     , slot = "R" , delay = 0.25, speed = math.huge  , isMissile = false},
    ["DariusExecute"]               = {charName = "Darius"      , slot = "R" , delay = 0.25, speed = math.huge  , isMissile = false},    -- delay to be comfirm
    ["EliseHumanQ"]                 = {charName = "Elise"       , slot = "Q1", delay = 0.25, speed = 2200       , isMissile = true },
    ["EliseSpiderQCast"]            = {charName = "Elise"       , slot = "Q2", delay = 0.25, speed = math.huge  , isMissile = false},
    ["EvelynnE"]                    = {charName = "Evelynn"     , slot = "E" , delay = 0.25, speed = math.huge  , isMissile = false},
    ["EvelynnE2"]                   = {charName = "Evelynn"     , slot = "E" , delay = 0.25, speed = math.huge  , isMissile = false},
    ["Terrify"]                     = {charName = "FiddleSticks", slot = "Q" , delay = 0.25, speed = math.huge  , isMissile = false},
    ["FiddlesticksDarkWind"]        = {charName = "FiddleSticks", slot = "E" , delay = 0.25, speed = 1100       , isMissile = true },
    ["GangplankQProceed"]           = {charName = "Gangplank"   , slot = "Q" , delay = 0.25, speed = 2600       , isMissile = true },
    ["GarenR"]                      = {charName = "Garen"       , slot = "R" , delay = 0.25, speed = math.huge  , isMissile = false},
    ["SowTheWind"]                  = {charName = "Janna"       , slot = "W" , delay = 0.25, speed = 1600       , isMissile = true },
    ["JarvanIVCataclysm"]           = {charName = "JarvanIV"    , slot = "R" , delay = 0.25, speed = math.huge  , isMissile = false},
    ["JaxLeapStrike"]               = {charName = "Jax"         , slot = "Q" , delay = 0   , speed = 1700       , isMissile = false}, -- seems speed base on distance, lazy to find the forumla , maybe fixed delay
    ["JayceToTheSkies"]             = {charName = "Jayce"       , slot = "Q2", delay = 0.25, speed = math.huge  , isMissile = false}, -- seems speed base on distance, lazy to find the forumla , maybe fixed delay
    ["JayceThunderingBlow"]         = {charName = "Jayce"       , slot = "E2", delay = 0.25, speed = math.huge  , isMissile = false},
    ["KatarinaQ"]                   = {charName = "Katarina"    , slot = "Q" , delay = 0.25, speed = 1600       , isMissile = true },
    ["KatarinaE"]                   = {charName = "Katarina"    , slot = "E" , delay = 0.1 , speed = math.huge  , isMissile = false}, -- delay to be comfirm
    ["NullLance"]                   = {charName = "Kassadin"    , slot = "Q" , delay = 0.25, speed = 1400       , isMissile = true },
    ["KhazixQ"]                     = {charName = "Khazix"      , slot = "Q1", delay = 0.25, speed = math.huge  , isMissile = false},
    ["KhazixQLong"]                 = {charName = "Khazix"      , slot = "Q2", delay = 0.25, speed = math.huge  , isMissile = false},
    ["BlindMonkRKick"]              = {charName = "LeeSin"      , slot = "R" , delay = 0.25, speed = math.huge  , isMissile = false},
    ["LeblancQ"]                    = {charName = "Leblanc"     , slot = "Q" , delay = 0.25, speed = 2000       , isMissile = true },
    ["LeblancRQ"]                   = {charName = "Leblanc"     , slot = "RQ", delay = 0.25, speed = 2000       , isMissile = true },
    ["LissandraREnemy"]             = {charName = "Lissandra"   , slot = "R" , delay = 0.5 , speed = math.huge  , isMissile = false},
    ["LucianQ"]                     = {charName = "Lucian"      , slot = "Q" , delay = 0.25, speed = math.huge  , isMissile = false}, --  delay = 0.4 − 0.25 (based on level)
    ["LuluWTwo"]                    = {charName = "Lulu"        , slot = "W" , delay = 0.25, speed = 2250       , isMissile = true },
    ["LuluE"]                       = {charName = "Lulu"        , slot = "E" , delay = 0   , speed = math.huge  , isMissile = false},
    ["SeismicShard"]                = {charName = "Malphite"    , slot = "Q" , delay = 0.25, speed = 1200       , isMissile = true },
    ["MalzaharE"]                   = {charName = "Malzahar"    , slot = "E" , delay = 0.25, speed = math.huge  , isMissile = false},
    ["MalzaharR"]                   = {charName = "Malzahar"    , slot = "R" , delay = 0   , speed = math.huge  , isMissile = false},
    ["MaokaiW"]                     = {charName = "Maokai"      , slot = "W" , delay = 0   , speed = 1300       , isMissile = false},
    ["MissFortuneRicochetShot"]     = {charName = "MissFortune" , slot = "Q" , delay = 0.25, speed = 1400       , isMissile = true },  -- too lazy to calculate the speed forumla
    ["NasusW"]                      = {charName = "Nasus"       , slot = "W" , delay = 0.25, speed = math.huge  , isMissile = false},
    ["NautilusGrandLine"]           = {charName = "Nautilus"    , slot = "R" , delay = 0.5 , speed = 1400       , isMissile = true },  -- delay to be comfirm
    ["NocturneParanoia2"]           = {charName = "Nocturne"    , slot = "R" , delay = 0   , speed = 1800       , isMissile = false},  --seems that you will never detect it.
    ["OlafRecklessStrike"]          = {charName = "Olaf"        , slot = "E" , delay = 0.25, speed = math.huge  , isMissile = false},
    ["PoppyE"]                      = {charName = "Poppy"       , slot = "E" , delay = 0   , speed = 1800       , isMissile = false},
    ["QuinnE"]                      = {charName = "Quinn"       , slot = "E" , delay = 0   , speed = 2500       , isMissile = false},
    ["RekSaiE"]                     = {charName = "RekSai"      , slot = "E" , delay = 0.25, speed = math.huge  , isMissile = false},
    ["RekSaiR"]                     = {charName = "RekSai"      , slot = "R" , delay = 1.5 , speed = math.huge  , isMissile = false},
    ["PuncturingTaunt"]             = {charName = "Rammus"      , slot = "E" , delay = 0.25, speed = math.huge  , isMissile = false},
    ["RyzeW"]                       = {charName = "Ryze"        , slot = "W" , delay = 0.25, speed = math.huge  , isMissile = false},
    ["RyzeE"]                       = {charName = "Ryze"        , slot = "E" , delay = 0.25, speed = 3500       , isMissile = true },
    ["RenektonExecute"]             = {charName = "Renekton"    , slot = "W1", delay = 0.25, speed = math.huge  , isMissile = false},
    ["RenektonSuperExecute"]        = {charName = "Renekton"    , slot = "W2", delay = 0.25, speed = math.huge  , isMissile = false},
    ["SyndraR"]                     = {charName = "Syndra"      , slot = "R" , delay = 0.25, speed = 1400       , isMissile = true },
    ["TwoShivPoison"]               = {charName = "Shaco"       , slot = "E" , delay = 0.25, speed = 1500       , isMissile = true },
    ["Fling"]                       = {charName = "Singed"      , slot = "E" , delay = 0.25, speed = math.huge  , isMissile = false},
    ["BlindingDart"]                = {charName = "Teemo"       , slot = "Q" , delay = 0.25, speed = 1500       , isMissile = true },
    ["TristanaR"]                   = {charName = "Tristana"    , slot = "R" , delay = 0.25, speed = 2000       , isMissile = true },
    ["ViR"]                         = {charName = "Vi"          , slot = "R" , delay = 0.25, speed = 800        , isMissile = false},
    ["VayneCondemn"]                = {charName = "Vayne"       , slot = "E" , delay = 0.25, speed = 2200       , isMissile = true },
    ["VeigarR"]                     = {charName = "Veigar"      , slot = "R" , delay = 0.25, speed = 500        , isMissile = true },
    ["VladimirQ"]                   = {charName = "Vladimir"    , slot = "Q" , delay = 0.25, speed = math.huge  , isMissile = false},        -- speed to be comfirm
    ["XinZhaoE"]                    = {charName = "XinZhao"     , slot = "E" , delay = 0   , speed = 3000       , isMissile = false},
    ["TimeWarp"]                    = {charName = "Zilean"      , slot = "E" , delay = 0   , speed = math.huge  , isMissile = false},
    ["MordekaiserR"]                = {charName = "Mordekaiser" , slot = "R" , delay = 0.5 , speed = math.huge  , isMissile = false},
    ["QuinnE"]                      = {charName = "Quinn"       , slot = "E" , delay = 0   , speed = 2500       , isMissile = false},
    ["NamiW"]                       = {charName = "Nami"        , slot = "W" , delay = 0.25, speed = 2000       , isMissile = true },
    ["ViktorPowerTransfer"]         = {charName = "Viktor"      , slot = "Q" , delay = 0.25, speed = 2000       , isMissile = true },      -- too lazy to calculate the speed forumla
    ["BlueCardPreAttack"]           = {charName = "TwistedFate" , slot = "W" , delay = 0   , speed = 1500       , isMissile = true },
    ["RedCardPreAttack"]            = {charName = "TwistedFate" , slot = "W" , delay = 0   , speed = 1500       , isMissile = true },
    ["GoldCardPreAttack"]           = {charName = "TwistedFate" , slot = "W" , delay = 0   , speed = 1500       , isMissile = true },
    ["TahmKenchR"]                  = {charName = "TahmKench"   , slot = "R" , delay = 0.25, speed = math.huge  , isMissile = false},
}

local TargetedAA = {
    ["PowerFistAttack"] = {charName = "Blitzcrank", delay = 0.25, speed = math.huge},
    ["CamilleQAttackEmpowered"] = {charName = "Camille", delay = 0.25, speed = math.huge},
    ["NautilusRavageStrikeAttack"]  = {charName = "Nautilus"   , slot = "P" },
    ["DariusNoxianTacticsONHAttack"] = {charName = "Darius", delay = 0.25, speed = math.huge},
    ["XinZhaoQThrust3"]             = {charName = "XinZhao"    , slot = "Q3"},
    ["EkkoEAttack"] = {charName = "Ekko", delay = 0.25, speed = math.huge},
    ["FioraEAttack"] = {charName = "Fiora", delay = 0.25, speed = math.huge},
    ["FioraEAttack2"] = {charName = "Fiora", delay = 0.25, speed = math.huge},
    ["FizzWBasicAttack"] = {charName = "Fizz", delay = 0.25, speed = math.huge},
    ["LeonaShieldOfDaybreakAttack"] = {charName = "Leona", delay = 0.32, speed = math.huge},
}

function Sivir:__init()
    self.q = {
        type = "linear",
        speed = 1450,
        range = 1150,
        delay = 0.25,
        width = 180,
        collision = {
            ["Wall"] = true,
            ["Hero"] = false,
            ["Minion"] = false
        }
    }
    self:Menu()
    self.TS =
        DreamTS(
        self.menu:GetLocalChild("dreamTs"),
        {
            Damage = DreamTS.Damages.AD
        }
    )
    SDK.EventManager:RegisterCallback(SDK.Enums.Events.OnTick, function() self:OnTick() end)
    SDK.EventManager:RegisterCallback(SDK.Enums.Events.OnDraw, function() self:OnDraw() end)
    SDK.EventManager:RegisterCallback(SDK.Enums.Events.OnProcessSpell, function(unit, spell) self:OnProcessSpell(unit, spell) end)
    SDK.EventManager:RegisterCallback(SDK.Enums.Events.OnBuffGain, function(obj, buff) self:OnBuffUpdate(obj, buff) end)
    SDK.EventManager:RegisterCallback(SDK.Enums.Events.OnBasicAttack, function(unit, spell) self:OnBasicAttack(unit, spell) end)
    _G.CoreEx.EventManager.RegisterCallback(_G.CoreEx.Enums.Events.OnPostAttack, function(target) self:OnExecuteCastFrame(SDK.Types.AIBaseClient(target)) end)
end

function Sivir:Menu()
    self.menu = SDK.Libs.Menu("cxsivir", "Cyrex Sivir")

    self.menu
    :AddLabel("Cyrex Sivir Settings", true)
    :AddSubMenu("dreamTs", "Target Selector")

    self.menu
    :AddSubMenu("combo", "Combo Settings")
        :AddLabel("Q Settings", true)
        :AddCheckbox("q", "Use Q", true)
        :AddLabel("W Settings", true)
        :AddCheckbox("w", "Use W", true)
        :AddLabel("E Settings", true)
        :AddCheckbox("e", "Use E", true)
        :AddSlider("wDelay", "Xs before spell hit", {min = 0, max = 0.75, default = 0.1, step = 0.01})
        :GetParent()
                
    self.menu
    :AddSubMenu("blockSpell", "Auto E Block Spell")
    local block_sub_menu = self.menu:GetLocalChild("blockSpell")
    for i, enemy in ipairs(enemies) do
        for k, spell in pairs(TargetedSpell) do
            if enemy:GetCharacterName() == spell.charName then
                block_sub_menu:AddLabel(enemy:GetCharacterName(), true)
                block_sub_menu:AddCheckbox(k, enemy:GetCharacterName() .." ["..spell.slot.."] | ", true)
                block_sub_menu:AddSlider(k .. "hp", "^- Health Percent: ", {min = 1, max = 100, default = 50, step = 1})
            end
        end
    end

    self.menu
    :AddSubMenu("blockaa", "Auto E Special AA")
    local block_aa_menu = self.menu:GetLocalChild("blockaa")
    for i, enemy in ipairs(enemies) do
        for k, spell in pairs(TargetedAA) do
            if enemy:GetCharacterName() == spell.charName then
                block_aa_menu:AddLabel(enemy:GetCharacterName(), true)
                block_aa_menu:AddCheckbox(k, enemy:GetCharacterName() .." [AA] | ", true)
                block_aa_menu:AddSlider(k .. "hp", "^- Health Percent: ", {min = 1, max = 100, default = 50, step = 1})
            end
        end
    end

    self.menu
    :AddSubMenu("harass", "Harass Settings")
        :AddLabel("Q Settings", true)
        :AddCheckbox("q", "Use Q", true)
        :AddLabel("W Settings", true)
        :AddCheckbox("w", "Use W", true)
        :GetParent()
    :AddSubMenu("lc", "Lane Clear")
        :AddCheckbox("q", "Use Q (Fast Clear)", true)
        :AddSlider("qx", "Min Minions:", {min = 0, max = 8, default = 3, step = 1})
        :AddSlider("qm", "Min Mana Percent:", {min = 0, max = 100, default = 10, step = 5})
        :GetParent()
    :AddSubMenu("jg", "Jungle Clear")
        :AddCheckbox("q", "Use Q", true)
        :GetParent()
    :AddSubMenu("auto", "Automatic Settings")
        :AddLabel("Killsteal Settings", true)
        :AddCheckbox("uqks", "Use Q in Killsteal", true)
        :GetParent()
    :AddSubMenu("draws", "Draw")
        :AddCheckbox("q", "Q", true)
        :GetParent()
    :AddLabel("Version: " .. update_data.Robur.ScriptVersion .. "", true)
    :AddLabel("Author: Coozbie", true)

    self.menu:Render()
end

local color_white = SDK.Libs.Color.GetD3DColor(255,7,141,237)

function Sivir:OnDraw()
    if not myHero:IsOnScreen() then
        return
    end

    if self.menu:GetLocal("draws.q") and myHero:CanUseSpell(SDK.Enums.SpellSlot.Q) then
        SDK.Renderer:DrawCircle3D(myHero:GetPosition(), self.q.range, color_white)
    end    
end

function Sivir:GetAARange(target)
    return myHero:GetAttackRange() + myHero:GetBoundingRadius() + (target and target:GetBoundingRadius() or 0)
end

function Sivir:qDmg(target)
    if myHero:CanUseSpell(SDK.Enums.SpellSlot.Q) then
        return DamageLib.GetSpellDamage(Player, target.data, SDK.Enums.SpellSlot.Q)
    end
end

function Sivir:OnProcessSpell(unit, spell)
    local target = spell:GetTarget()
    if not (unit:IsEnemy() and target and target:IsMe()) then return end

    if myHero:CanUseSpell(SDK.Enums.SpellSlot.E) and self.menu:GetLocal("combo.e") then
        local spellName = spell:GetName()
        local data = TargetedSpell[spellName]
        if data and self.menu:GetLocal("blockSpell." .. spellName) and self.menu:GetLocal("blockSpell." .. spellName .. "hp") >= Player.HealthPercent * 100 then
            local dt = unit:GetPosition():Distance(myHero:GetPosition())
            local hitTime = data.delay + dt/data.speed - self.menu:GetLocal("combo.wDelay")
            delay(hitTime*1000, function() SDK.Input:Cast(SDK.Enums.SpellSlot.E, myHero) end)
        end
    end
end

function Sivir:OnBasicAttack(unit, spell)
    if not spell:GetName():lower():find("attack") then return end
    local target = spell:GetTarget()
    if not (unit:IsEnemy() and target and target:IsMe()) then return end

    if myHero:CanUseSpell(SDK.Enums.SpellSlot.E) and self.menu:GetLocal("combo.e") then
        local spellName = spell:GetName()
        local data = TargetedAA[spellName]
        if data and self.menu:GetLocal("blockaa." .. spellName) and self.menu:GetLocal("blockaa." .. spellName .. "hp") >= Player.HealthPercent * 100 then
            local dt = unit:GetPosition():Distance(myHero:GetPosition())
            local hitTime = unit:GetAttackCastDelay() - self.menu:GetLocal("combo.wDelay")
            delay(hitTime*1000, function() SDK.Input:Cast(SDK.Enums.SpellSlot.E, myHero) end)
        end
    end
end

function Sivir:OnExecuteCastFrame(target)
    if ((_G.Libs.Orbwalker.GetMode() == "Combo" and self.menu:GetLocal("combo.w")) or (self.menu:GetLocal("harass.w") and _G.Libs.Orbwalker.GetMode() == "Harass")) and myHero:CanUseSpell(SDK.Enums.SpellSlot.W) then
        if target and roburTS:IsValidTarget(target.data) and target:GetPosition():DistanceSqr(myHero:GetPosition()) < self:GetAARange(target)^2 then
            SDK.Input:Cast(SDK.Enums.SpellSlot.W, myHero)
        end
    end
end

function Sivir:CastQ(pred)
    if pred.rates["slow"] then
        SDK.Input:Cast(SDK.Enums.SpellSlot.Q, pred.castPosition)
        pred:Draw()
        return true
    end
end

local buffsToCheck = {
    [SDK.Enums.BuffType.Charm] = true,
    [SDK.Enums.BuffType.Snare] = true,
    [SDK.Enums.BuffType.Taunt] = true,
    [SDK.Enums.BuffType.Stun] = true
}
function Sivir:OnBuffUpdate(obj, buff)
    if not (buffsToCheck[buff:GetType()] and myHero:CanUseSpell(SDK.Enums.SpellSlot.Q)) then
        return
    end
        
    if obj:IsValid() and obj:IsEnemy() and obj:IsAlive() and obj.IsHero and buff then
        if obj:GetPosition():DistanceSqr(myHero:GetPosition()) < (1100 * 1100) then
            SDK.Input:Cast(SDK.Enums.SpellSlot.Q, obj:GetPosition())
        end
    end
end

local immunityList = {
    "MorganaE",
    "itemmagekillerveil",
    "bansheesveil",
    "sivire",
}
function Sivir:IsImmuneMagic(target)
    for index = 1, #immunityList do
        local immunity = immunityList[index]
        local buff = target:GetBuff(immunity)
        if buff and buff:IsValid() then
            return true
        end
    end
    return false
end

function Sivir:DoingDodge()    
    if self:IsImmuneMagic(myHero) then return end
    if _G.DreamEvade.IsPositionSafe(myHero:GetPosition(), 0) then return end
    local Spells = _G.DreamEvade.ActiveSpells
    for index = 1, #Spells do
        local Spell = Spells[index]
        if myHero:CanUseSpell(SDK.Enums.SpellSlot.E) and ((Spell:IsCC() and Spell:IsOhShit() and Spell:IsActive()) or (Spell:GetDangerLevel() >= 4 and Spell:IsOhShit())) then
            SDK.Input:Cast(SDK.Enums.SpellSlot.E, myHero)
            return
        end
    end
end

function Sivir:LaneClear()
    if not (_G.Libs.Orbwalker.IsFastClearEnabled() and self.menu:GetLocal("lc.q")) then
        return
    end

    if not (Player.ManaPercent * 100 >= self.menu:GetLocal("lc.qm")) then
        return
    end

    local minionsPositions = {}
    local myPos = myHero:GetPosition()
    for _, minion in ipairs(_G.CoreEx.ObjectManager.GetNearby("enemy", "minions")) do
        if minion:Distance(myPos) < self.q.range then
            table.insert(minionsPositions, minion.Position)
        end
    end
    local bestPos, numberOfHits = _G.CoreEx.Geometry.BestCoveringRectangle(minionsPositions, myPos, self.q.width)    
    if numberOfHits >= self.menu:GetLocal("lc.qx") then
        SDK.Input:Cast(SDK.Enums.SpellSlot.Q, bestPos)
        return
    end
end

function Sivir:JungleClear()
    if not self.menu:GetLocal("jg.q") then
        return
    end

    local Jungle = _G.CoreEx.ObjectManager.GetNearby("neutral", "minions")
    for iJGLQ, minion in ipairs (Jungle) do
        if minion.MaxHealth > 6 and minion:Distance(Player) < 600 and roburTS:IsValidTarget(minion) then
            SDK.Input:Cast(SDK.Enums.SpellSlot.Q, minion.Position)
            return
        end
    end
end

function Sivir:OnTick()
    local orbMode = _G.Libs.Orbwalker.GetMode()
    local ComboMode = orbMode == "Combo"
    local HarassMode = orbMode == "Harass"
    local WaveclearMode = orbMode == "Waveclear"

    if self.menu:GetLocal("combo.e") and rawget(_G, "DreamEvade") and _G.DreamEvade.IsEvadeEnabled() then
        self:DoingDodge()
    end

    if myHero:CanUseSpell(SDK.Enums.SpellSlot.Q) then
        if (ComboMode and self.menu:GetLocal("combo.q")) or (HarassMode and self.menu:GetLocal("harass.q")) then
            local q_target, q_pred = self.TS:GetTarget(self.q, myHero:GetPosition())
            if q_pred and self:CastQ(q_pred) then
                return
            end
        end
        if self.menu:GetLocal("auto.uqks") then
            local q_ks, q_ks_pred = self.TS:GetTarget(self.q, myHero:GetPosition(), function(enemy) return self:qDmg(enemy) >= enemy:GetHealth() end)
            if q_ks_pred and self:CastQ(q_ks_pred) then
                return
            end
        end
        if WaveclearMode then
            self:LaneClear()
            self:JungleClear()
        end
    end    
end

Sivir:__init()
