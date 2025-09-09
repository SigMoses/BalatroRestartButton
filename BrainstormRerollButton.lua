--- STEAMODDED HEADER
--- MOD_NAME: Brainstorm Reroll Button
--- MOD_ID: BrainstormRerollButton
--- MOD_AUTHOR: [Jdbye]
--- MOD_DESCRIPTION: Adds an Auto Reroll button to ESC and Game Over menus; compatible with OceanRamen Brainstorm and ABGamma Brainstorm‑Rerolled. The button is always shown and triggers a compatibility layer with a Ctrl+A fallback.

----------------------------------------------
------------ MOD CODE ------------------------

-- Compatibility: call Brainstorm’s auto-reroll via multiple possible APIs, or fall back to Ctrl+A.
local function brainstorm_autoreroll_try_all()
  local tried = {}
  local function try(label, fn)
    if type(fn) == "function" then
      local ok, err = pcall(fn)
      if ok then return true end
      tried[#tried+1] = label .. " -> error: " .. tostring(err)
    else
      tried[#tried+1] = label .. " -> not a function"
    end
    return false
  end
  -- Try common entry points across Brainstorm forks
  if _G.Brainstorm_reroll and _G.Brainstorm_reroll.auto_reroll then
    if try("Brainstorm_reroll.auto_reroll", _G.Brainstorm_reroll.auto_reroll) then return true end
  end
  if _G.Brainstorm_keyhandler and _G.Brainstorm_keyhandler.auto_reroll then
    if try("Brainstorm_keyhandler.auto_reroll", _G.Brainstorm_keyhandler.auto_reroll) then return true end
  end
  if _G.Brainstorm and _G.Brainstorm.auto_reroll then
    if try("Brainstorm.auto_reroll", _G.Brainstorm.auto_reroll) then return true end
  end
  if _G.Brainstorm and _G.Brainstorm.begin_autoreroll then
    if try("Brainstorm.begin_autoreroll", _G.Brainstorm.begin_autoreroll) then return true end
  end
  if _G.Brainstorm and type(_G.Brainstorm.reroll) == "table" then
    local r = _G.Brainstorm.reroll
    if r.autostart and try("Brainstorm.reroll.autostart", r.autostart) then return true end
    if r.auto and try("Brainstorm.reroll.auto", r.auto) then return true end
  end
  -- Deep search any function containing "auto" and "reroll" in name
  local function deep_find(tbl, seen, out)
    if type(tbl) ~= "table" or seen[tbl] then return end
    seen[tbl] = true
    for k,v in pairs(tbl) do
      local ks = tostring(k):lower()
      if type(v) == "function" and ks:find("auto") and ks:find("reroll") then
        out[#out+1] = v
      elseif type(v) == "table" then
        deep_find(v, seen, out)
      end
    end
  end
  if _G.Brainstorm then
    local cands = {}
    deep_find(_G.Brainstorm, {}, cands)
    for _,fn in ipairs(cands) do
      if try("deep_find(cand)", fn) then return true end
    end
  end
  -- Last resort: synthesize Ctrl+A (Brainstorm’s default hotkey)
  if love and love.keypressed and love.keyboard and love.keyboard.isDown then
    local lk = love.keyboard
    local old = lk.isDown
    lk.isDown = function(...)
      for i=1,select("#", ...) do
        local key = select(i, ...)
        if key == "lctrl" or key == "rctrl" or key == "lcmd" or key == "rgui" or key == "lgui" then
          return true
        end
      end
      return old(...)
    end
    pcall(function() love.keypressed("a") end)
    lk.isDown = old
    return true
  end
  return false
end

-- Click handler: always triggers compatibility logic and unpauses.
function G.FUNCS.brainstorm_reroll_button(_)
  local ok = brainstorm_autoreroll_try_all()
  if not ok and G and G.FUNCS and G.FUNCS.overlay_message then
    G.FUNCS.overlay_message({text="Auto‑Reroll: no API detected. Sent Ctrl+A.", colour=G.C.RED})
  end
  G.SETTINGS.paused = false
end

-- Helpers to construct buttons
local function make_small_button(label, button_id, colour_hex)
  return UIBox_button({
    minw = 5, button = button_id,
    label = {label}, colour = HEX(colour_hex or '00A0A0')
  })
end
local function make_big_button(label, button_id, colour_hex)
  return {
    n=G.UIT.R, config={align="cm", minw=5, padding=0.1, r=0.1, hover=true,
      colour=HEX(colour_hex or '00A0A0'), button=button_id, shadow=true,
      focus_args={nav='wide', snap_to=true}},
    nodes={
      {n=G.UIT.R, config={align="cm", padding=0, no_fill=true, maxw=4.8}, nodes={
        {n=G.UIT.T, config={text=label, scale=0.5, colour=G.C.UI.TEXT_LIGHT}}
      }}
    }
  }
end

-- Inject into the ESC/options menu (same hook used by RestartRunButton)
local orig_create_options = create_UIBox_options
function create_UIBox_options(...)
  local contents = orig_create_options(...)
  if G.STATE ~= G.STATES.MENU then
    local btn = make_small_button("Auto Reroll (Brainstorm)", "brainstorm_reroll_button", '00A0A0')
    local list = contents.nodes[1].nodes[1].nodes[1].nodes
    table.insert(list, 2, btn)
  end
  return contents
end

-- Inject into the Game Over menu (similar layout to RestartRunButton)
local orig_create_game_over = create_UIBox_game_over
function create_UIBox_game_over(...)
  local contents = orig_create_game_over(...)
  if G.STATE ~= G.STATES.MENU then
    -- replicate spacing tweak from RestartRunButton (failsafe call)
    pcall(function()
      contents.nodes[1].nodes[2].nodes[1].nodes[1].nodes[1].nodes[2].nodes[1].nodes[2].nodes[1].config.focus_args.snap_to = false
    end)
    local btn = make_big_button("Auto Reroll (Brainstorm)", "brainstorm_reroll_button", '00A0A0')
    local list = contents.nodes[1].nodes[2].nodes[1].nodes[1].nodes[1].nodes[2].nodes[1].nodes[2].nodes
    table.insert(list, 2, btn)
  end
  return contents
end

----------------------------------------------
------------ MOD CODE END --------------------