-- ~/.config/hypr/helpers.lua
-- Native Hyprland Helper Utilities for CachyOS / Arch Linux
-- Provides metadata-driven bindings, focus-or-launch (launch_sole), and dynamic window routing.

local helpers = {}

--- Check if the currently focused window is a terminal emulator
-- @return boolean
function helpers.is_terminal()
    local win = hl.get_active_window()
    if not win then
        return false
    end
    local cls = tostring(win.class or ""):lower()
    local initial_cls = tostring(win.initial_class or ""):lower()
    return cls:match("kitty") ~= nil
        or cls:match("ghostty") ~= nil
        or cls:match("alacritty") ~= nil
        or cls:match("foot") ~= nil
        or cls:match("wezterm") ~= nil
        or cls:match("xterm") ~= nil
        or initial_cls:match("kitty") ~= nil
        or initial_cls:match("ghostty") ~= nil
        or initial_cls:match("alacritty") ~= nil
end

--- Metadata-driven bind helper
-- @param keys string Key combination (e.g. "SUPER + Q")
-- @param description string|nil Human-readable description for cheatsheets & IPC
-- @param action string|function|userdata Command string, Lua callback, or Hyprland dispatcher
-- @param opts table|nil Additional options (e.g. { repeating = true, locked = true })
function helpers.bind(keys, description, action, opts)
    local options = opts or {}
    if description and description ~= "" then
        options.description = description
    end

    local final_action = action
    if type(action) == "string" then
        -- Automatically wrap bare shell command in UWSM and exec dispatcher
        local cmd = action
        if not cmd:match("^uwsm") then
            cmd = "uwsm-app -- " .. cmd
        end
        final_action = hl.dsp.exec_cmd(cmd)
    end

    hl.bind(keys, final_action, options)
end

--- Native Focus-or-Launch (launch_sole) with multi-instance cycling
-- If the application window exists, focus it (or cycle if already active).
-- If absent, launch it cleanly through UWSM.
-- @param window_class string Pattern matching the window class or title
-- @param exec_command string Command to launch if window is not found
-- @return function Lua callback for hl.bind
function helpers.launch_or_focus(window_class, exec_command)
    return function()
        local clients = hl.get_windows() or {}
        local target = window_class:lower()
        local matches = {}

        for _, client in ipairs(clients) do
            local cls = tostring(client.class or ""):lower()
            local initial_cls = tostring(client.initial_class or ""):lower()
            local title = tostring(client.title or ""):lower()
            if cls:match(target) or initial_cls:match(target) or title:match(target) then
                table.insert(matches, client)
            end
        end

        if #matches == 0 then
            local cmd = exec_command
            if not cmd:match("^uwsm") then
                cmd = "uwsm-app -- " .. cmd
            end
            hl.exec_cmd(cmd)
            return
        end

        local active = hl.get_active_window()
        local active_addr = active and tostring(active.address) or ""

        -- If current window already matches, cycle to the next matching instance
        for i, client in ipairs(matches) do
            if tostring(client.address) == active_addr then
                local next_client = matches[(i % #matches) + 1]
                hl.dispatch(hl.dsp.focus({ window = "address:" .. tostring(next_client.address) }))
                return
            end
        end

        -- Otherwise focus the first matching window
        hl.dispatch(hl.dsp.focus({ window = "address:" .. tostring(matches[1].address) }))
    end
end

--- Dynamic context-aware key dispatcher
-- @param terminal_fn function|userdata Dispatcher or callback to run in terminals
-- @param gui_fn function|userdata Dispatcher or callback to run in GUI applications
-- @return function Lua callback for hl.bind
function helpers.route_key(terminal_fn, gui_fn)
    return function()
        local action = helpers.is_terminal() and terminal_fn or gui_fn
        if type(action) == "function" then
            action()
        else
            hl.dispatch(action)
        end
    end
end

return helpers
