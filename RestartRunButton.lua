--- STEAMODDED HEADER
--- MOD_NAME: Restart Run Button
--- MOD_ID: RestartRunButton
--- MOD_AUTHOR: [Jdbye]
--- MOD_DESCRIPTION: Adds a button to restart run (using the same seed if seeded) to the escape menu and the game over screen. Does the same thing as holding R.
----------------------------------------------
------------MOD CODE -------------------------

function G.FUNCS.restart_run_button(arg_736_0)
	if not G.GAME.won and not G.GAME.seeded and not G.GAME.challenge then 
		G.PROFILES[G.SETTINGS.profile].high_scores.current_streak.amt = 0
	end
	G:save_settings()
	G.SETTINGS.current_setup = 'New Run'
	G.GAME.viewed_back = nil
	G.run_setup_seed = G.GAME.seeded
	G.challenge_tab = G.GAME and G.GAME.challenge and G.GAME.challenge_tab or nil
	G.forced_seed, G.setup_seed = nil, nil
	if G.GAME.seeded then G.forced_seed = G.GAME.pseudorandom.seed end
	G.forced_stake = G.GAME.stake
	if G.STAGE == G.STAGES.RUN then G.FUNCS.start_setup_run() end
	G.forced_stake = nil
	G.challenge_tab = nil
	G.forced_seed = nil
    G.SETTINGS.paused = false
end

local createOptionsRef = create_UIBox_options
function create_UIBox_options()
  contents = createOptionsRef()

  if G.STATE ~= G.STATES.MENU then
    local restart_run_button = UIBox_button({
      minw = 5,
      button = "restart_run_button",
      label = {
        "Restart Run"
      },
      colour = HEX('00A000')
    })
    table.insert(contents.nodes[1].nodes[1].nodes[1].nodes, 2, restart_run_button)
  end
  return contents
end

local createGameOverRef = create_UIBox_game_over
function create_UIBox_game_over()
  contents = createGameOverRef()

  if G.STATE ~= G.STATES.MENU then
    -- create the button
    local restart_run_button = {
	    n=G.UIT.R, config={align = "cm", minw = 5, padding = 0.1, r = 0.1, hover = true, colour = HEX('00A000'), button = "restart_run_button", shadow = true, focus_args = {nav = 'wide', snap_to = true}}, nodes={
            {n=G.UIT.R, config={align = "cm", padding = 0, no_fill = true, maxw = 4.8}, nodes={
              {n=G.UIT.T, config={text = "Restart Run", scale = 0.5, colour = G.C.UI.TEXT_LIGHT}}
            }}
        }
    }
	
	-- set snap_to = false on New Run button (unsuccessful attempt to fix inconsistent spacing)
	contents.nodes[1].nodes[2].nodes[1].nodes[1].nodes[1].nodes[2].nodes[1].nodes[2].nodes[1].config.focus_args.snap_to = false
	
	-- insert the button
    table.insert(contents.nodes[1].nodes[2].nodes[1].nodes[1].nodes[1].nodes[2].nodes[1].nodes[2].nodes, 1, restart_run_button)
  end
  return contents
end


----------------------------------------------
------------MOD CODE END----------------------
