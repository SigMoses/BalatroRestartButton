--- STEAMODDED HEADER
--- MOD_NAME: Brainstorm Reroll Button
--- MOD_ID: BrainstormRerollButton
--- MOD_AUTHOR: [Jdbye]
--- MOD_DESCRIPTION: Adds an Auto Reroll button to ESC and Game Over menus.

----------------------------------------------
------------ MOD CODE ------------------------

-- Utility: detect mobile to avoid keyboard injection
local function is_mobile_os()
  if love and love.system and love.system.getOS then
    local os = love.system.getOS()
    return os == 'Android' or os == 'iOS'
  end
  -- Lovely exposes love._os in some builds
  if love and love._os then
    return love._os == 'Android' or love._os == 'iOS'
  end
  return false
end

-- Try to call Brainstorm’s auto-reroll via multiple possible APIs.
-- On mobile, we do NOT synthesize keypresses; we only use APIs / function hooks.
local function brainstorm_autoreroll_try_all(opts)
  opts = opts or {}
  local allow_keyboard_synth = not is_mobile_os() and (opts.allow_keyboard_synth ~= false)
  local tried = {}

  local function try(label, fn, ...)
    if type(fn) == "function" then
      local ok, err = pcall(fn, ...)
      if ok then return true end
      tried[#tried+1] = label .. " -> error: " .. tostring(err)
    else
      tried[#tried+1] = label .. " -> not a function"
    end
    return false
  end

  -- Known entry points across forks
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
  if _G.Brainstorm and _G.Brainstorm.begin_autoroll then
    if try("Brainstorm.begin_autoroll", _G.Brainstorm.begin_autoroll) then return true end
  end
  if _G.Brainstorm and _G.Brainstorm.start_autoroll then
    if try("Brainstorm.start_autoroll", _G.Brainstorm.start_autoroll) then return true end
  end
  if _G.Brainstorm and _G.Brainstorm.toggle_autoroll then
    if try("Brainstorm.toggle_autoroll", _G.Brainstorm.toggle_autoroll, true) then return true end
  end
  if _G.Brainstorm and type(_G.Brainstorm.reroll) == "table" then
    local r = _G.Brainstorm.reroll
    if r.autostart and try("Brainstorm.reroll.autostart", r.autostart) then return true end
    if r.auto and try("Brainstorm.reroll.auto", r.auto) then return true end
  end
  -- Try ABGamma fork namespaces if exposed
  if _G.BrainstormRerolled and _G.BrainstormRerolled.auto_reroll then
    if try("BrainstormRerolled.auto_reroll", _G.BrainstormRerolled.auto_reroll) then return true end
  end
  if _G.Brainstorm_Rerolled and _G.Brainstorm_Rerolled.auto_reroll then
    if try("Brainstorm_Rerolled.auto_reroll", _G.Brainstorm_Rerolled.auto_reroll) then return true end
  end

  -- Deep search for any function named like "*auto*roll*"
  local function deep_find(tbl, seen, out)
    if type(tbl) ~= "table" or seen[tbl] then return end
    seen[tbl] = true
    for k,v in pairs(tbl) do
      local ks = tostring(k):lower()
      if type(v) == "function" and ks:find("auto") and (ks:find("roll") or ks:find("reroll")) then
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

  -- Last resort: synthesize Ctrl+A (Brainstorm’s default hotkey) on desktop only
  if allow_keyboard_synth and love and love.keypressed and love.keyboard and love.keyboard.isDown then
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

  -- If nothing fired, optionally schedule a gentle delayed poll to catch late-loading mods.
  if G and G.E_MANAGER and type(G.E_MANAGER.add_event) == 'function' then
    G.E_MANAGER:add_event(Event({
      trigger = 'after', delay = 0.2, -- wait a couple ticks for Android mod init lag
      func = function()
        -- try again without keyboard synth (safe for mobile/desktop)
        brainstorm_autoreroll_try_all({allow_keyboard_synth = false})
        return true
      end
    }))
  end

  return false
end

-- Click handler: triggers compatibility logic and unpauses.
function G.FUNCS.brainstorm_reroll_button(_)
  local ok = brainstorm_autoreroll_try_all()
  if not ok and G and G.FUNCS and G.FUNCS.overlay_message then
    G.FUNCS.overlay_message({text="Auto-Reroll: no API detected", colour=G.C.RED})
  end
  if G and G.SETTINGS then G.SETTINGS.paused = false end
end

-- Safe UI helpers (avoid nil index chains on mobile where layouts vary)
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

-- Helper: try to push a node into a list if it exists
local function safe_insert(list, index, node)
  if type(list) == 'table' then
    table.insert(list, math.max(1, math.min(index or (#list+1), #list+1)), node)
  end
end

-- Inject into the ESC/options menu
local orig_create_options = create_UIBox_options
function create_UIBox_options(...)
  local contents = orig_create_options(...)
  if G.STATE ~= G.STATES.MENU then
    local btn = make_small_button("Auto Reroll (Brainstorm)", "brainstorm_reroll_button", '00A0A0')
    -- Walk defensively to the vertical button list
    local list = contents and contents.nodes and contents.nodes[1]
      and contents.nodes[1].nodes and contents.nodes[1].nodes[1]
      and contents.nodes[1].nodes[1].nodes and contents.nodes[1].nodes[1].nodes[1]
      and contents.nodes[1].nodes[1].nodes[1].nodes
    safe_insert(list, 2, btn)
  end
  return contents
end

-- Inject into the Game Over menu
local orig_create_game_over = create_UIBox_game_over
function create_UIBox_game_over(...)
  local contents = orig_create_game_over(...)
  if G.STATE ~= G.STATES.MENU then
    pcall(function()
      -- replicate spacing tweak from RestartRunButton when path exists
      local tgt = contents.nodes[1].nodes[2].nodes[1].nodes[1].nodes[1].nodes[2].nodes[1].nodes[2].nodes[1]
      if tgt and tgt.config and tgt.config.focus_args then
        tgt.config.focus_args.snap_to = false
      end
    end)
    local btn = make_big_button("Auto Reroll (Brainstorm)", "brainstorm_reroll_button", '00A0A0')
    local list = contents and contents.nodes and contents.nodes[1]
      and contents.nodes[1].nodes and contents.nodes[1].nodes[2]
      and contents.nodes[1].nodes[2].nodes and contents.nodes[1].nodes[2].nodes[1]
      and contents.nodes[1].nodes[2].nodes[1].nodes and contents.nodes[1].nodes[2].nodes[1].nodes[1]
      and contents.nodes[1].nodes[2].nodes[1].nodes[1].nodes and contents.nodes[1].nodes[2].nodes[1].nodes[1].nodes[1]
      and contents.nodes[1].nodes[2].nodes[1].nodes[1].nodes[1].nodes and contents.nodes[1].nodes[2].nodes[1].nodes[1].nodes[1].nodes[2]
      and contents.nodes[1].nodes[2].nodes[1].nodes[1].nodes[1].nodes[2].nodes and contents.nodes[1].nodes[2].nodes[1].nodes[1].nodes[1].nodes[2].nodes[1]
      and contents.nodes[1].nodes[2].nodes[1].nodes[1].nodes[1].nodes[2].nodes[1].nodes and contents.nodes[1].nodes[2].nodes[1].nodes[1].nodes[1].nodes[2].nodes[1].nodes[2]
      and contents.nodes[1].nodes[2].nodes[1].nodes[1].nodes[1].nodes[2].nodes[1].nodes[2].nodes
    safe_insert(list, 2, btn)
  end
  return contents
end

----------------------------------------------
------------ MOD CODE END --------------------