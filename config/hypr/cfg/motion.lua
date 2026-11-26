local v = require("cfg.vars")
local c = v.c

local function hex(col)
    return (col or ""):match("(%x%x%x%x%x%x)")
end

local function rgba(col, alpha)
    local h = hex(col)
    if not h then return nil end
    return string.format("rgba(%s%02x)", h, math.floor(alpha * 255 + 0.5))
end

local function win(name, match, props)
    props.name = name
    props.match = match
    hl.window_rule(props)
end

win("motion-float",   { float = true },                              { animation = "popin 94%" })
win("motion-pip",     { title = "^(Picture-in-Picture)$" },          { animation = "slide right" })
win("motion-polkit",  { class = "^(hyprpolkitagent|org.kde.polkit-kde-authentication-agent-1)$" },
                      { animation = "popin 97%" })
win("motion-yazi",    { class = "^(yazi)$" },                        { animation = "popin 90%" })
win("motion-update",  { class = "^(rosa-update)$" },                 { animation = "slide top" })

hl.animation({ leaf = "borderangle", enabled = true, speed = 14, bezier = "glide" })

local glow = rgba(c.accent, 0.08)
local edge1 = rgba(c.active_border_1, 0.55)
local edge2 = rgba(c.active_border_2, 1.0)
local edge3 = rgba(c.active_border_1, 1.0)
if glow and edge1 and edge2 and edge3 then
    hl.config({
        general = {
            col = {
                active_border = { colors = { edge1, edge3, edge2, edge1 }, angle = 45 },
            },
        },
        decoration = {
            shadow = {
                range        = 26,
                render_power = 4,
                color        = glow,
            },
        },
    })
end

local warm = rgba(c.warn, 1.0) or "rgba(eccf79ff)"
local warmDim = rgba(c.warn, 0.35) or "rgba(eccf7959)"
win("motion-urgent-hi", { tag = "urgent-hi" }, { border_color = warm .. " " .. warm })
win("motion-urgent-lo", { tag = "urgent-lo" }, { border_color = warmDim .. " " .. warmDim })

local pulses = {}

local function tag(addr, t)
    hl.dispatch(hl.dsp.window.tag({ tag = t, window = "address:" .. addr }))
end

local function calm(addr)
    local p = pulses[addr]
    if not p then return end
    p.timer:set_enabled(false)
    pulses[addr] = nil
    pcall(tag, addr, "-urgent-hi")
    pcall(tag, addr, "-urgent-lo")
end

hl.on("window.urgent", function(w)
    if not w or not w.address or w.active then return end
    local addr = w.address
    if pulses[addr] then return end
    local p = { n = 0 }
    pulses[addr] = p
    tag(addr, "+urgent-hi")
    p.timer = hl.timer(function()
        p.n = p.n + 1
        local ok = pcall(function()
            if p.n % 2 == 1 then
                tag(addr, "-urgent-hi"); tag(addr, "+urgent-lo")
            else
                tag(addr, "-urgent-lo"); tag(addr, "+urgent-hi")
            end
        end)
        if not ok or p.n >= 9 then
            p.timer:set_enabled(false)
            if ok and p.n >= 9 then
                pcall(tag, addr, "-urgent-hi")
                pcall(tag, addr, "+urgent-lo")
            end
        end
    end, { timeout = 900, type = "repeat" })
end)

hl.on("window.active", function(w)
    if w and w.address then calm(w.address) end
end)

hl.on("window.close", function(w)
    if w and w.address and pulses[w.address] then
        pulses[w.address].timer:set_enabled(false)
        pulses[w.address] = nil
    end
end)
