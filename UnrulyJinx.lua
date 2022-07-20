if Player.CharName ~= "Jinx" then return end

module("Unruly Jinx", package.seeall, log.setup)
clean.module("Unruly Jinx", clean.seeall, log.setup)
CoreEx.AutoUpdate("https://raw.githubusercontent.com/hagbardlol/Public/main/UnrulyJinx.lua", "1.0.5")
local CoreEx = _G.CoreEx
local Enums, EventManager, Renderer, Game, Vector = CoreEx.Enums, CoreEx.EventManager, CoreEx.Renderer, CoreEx.Game, CoreEx.Geometry.Vector
local Screen = Renderer.GetResolution()

local Text = {
    Title = "Unfortunately, this assembly is no longer supported by us.",
    Subtitle = "No need to panic! We have made a new assembly available for you. Just check the forum or download the new assembly with the in-game downloader.",
    Message = "Please disable this assembly in your loader and press F5 to make the message disappear!",
}

local Size = {
    Border = Vector(800, 230), -- width, height
    Background = Vector(799, 228),
    Logo = Vector(350, 100),
    Warning = Vector(40, 40),
    Text = {
        Title = Renderer.CalcTextSize(Text.Title),
        Subtitle = Renderer.CalcTextSize(Text.Subtitle),
        Message = Renderer.CalcTextSize(Text.Message),
    }
}

local Position = {
    Border = Vector((Screen.x / 2) - Size.Border.x / 2, (Screen.y / 2) - Size.Border.y / 2),
    Background = Vector((Screen.x / 2) - Size.Background.x / 2, (Screen.y / 2) - Size.Background.y / 2),
    Logo = Vector(Screen.x / 2, Screen.y / 2 - Size.Logo.y / 2),
    Line = {
        Start = Vector((Screen.x / 2 - Size.Border.x / 2) + 10, (Screen.y / 2 - Size.Logo.y / 2) + 60),
        End =  Vector((Screen.x / 2 + Size.Border.x / 2) - 10, (Screen.y / 2 - Size.Logo.y / 2) + 60)
    },
    Text = {
        Title = Vector((Screen.x / 2) - Size.Text.Title.x / 2, (Screen.y / 2 - Size.Logo.y / 2) + 60 + Size.Text.Title.y / 2),
        Subtitle = Vector((Screen.x / 2) - Size.Text.Subtitle.x / 2, (Screen.y / 2 - Size.Logo.y / 2) + 60 + Size.Text.Title.y + Size.Text.Subtitle.y / 2),
        Message = Vector((Screen.x / 2) - Size.Text.Message.x / 2, (Screen.y / 2 - Size.Logo.y / 2) + 60 + Size.Text.Title.y + Size.Text.Subtitle.y + Size.Text.Message.y / 2),
    },
    Warning = Vector((Screen.x / 2) - Size.Warning.x / 2, (Screen.y / 2 - Size.Logo.y / 2) + 60 + Size.Text.Title.y + Size.Text.Subtitle.y + Size.Text.Message.y + Size.Warning.y / 2 + 10)
}

local Logo = Renderer.CreateSprite("robur.png", Size.Logo.x, Size.Logo.y)
local WarningSprite = Renderer.CreateSprite("warning.png", Size.Warning.x, Size.Warning.y)

local function DrawBackground()
    Renderer.DrawRectOutline(Position.Border, Size.Border, 1, 2, 0x001A332F)
    Renderer.DrawFilledRect(Position.Background, Size.Background, 1, 0x0D1B18FF)
end

local function DrawLogo()
    Logo:Draw(Position.Logo, 0, true)
end

local function DrawWarning()
    if math.floor(Game.GetTime() * 10) % 2 == 0 then
        WarningSprite:Draw(Position.Warning, 0, true)
    end
end

local function DrawLine()
    Renderer.DrawLine(Position.Line.Start, Position.Line.End, 1, 0xBFA64BFF)
end

local function DrawText()
    Renderer.DrawText(Position.Text.Title, Size.Text.Title, Text.Title, 0xFF0000FF)
    Renderer.DrawText(Position.Text.Subtitle, Size.Text.Subtitle, Text.Subtitle, 0x00FF00FF)
    Renderer.DrawText(Position.Text.Message, Size.Text.Message, Text.Message, 0xFFD966FF)
end


local function OnDraw()
    DrawBackground()
    DrawLogo()
    DrawLine()
    DrawText()
    DrawWarning()
end


local function Initialize()
    EventManager.RegisterCallback(Enums.Events.OnDraw, OnDraw)
end
Initialize()
