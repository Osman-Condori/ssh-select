-- lua/ssh-select/ui.lua
local UI = {}

-- ANSI Escape Sequences for terminal control
local CLEAR_SCREEN = "\27[2J"
local CURSOR_HOME  = "\27[H"
local HIDE_CURSOR  = "\27[?25l"
local SHOW_CURSOR  = "\27[?25h"
local TEXT_RESET   = "\27[0m"
local TEXT_BOLD    = "\27[1m"
local TEXT_CYAN    = "\27[36m"
local TEXT_YELLOW  = "\27[33m"  -- Muted yellow/brown for labels
local BG_HIGHLIGHT = "\27[44m\27[37m" -- Blue background, white text

-- Strict Internal Content Widths (Excluding borders)
local LEFT_WIDTH  = 33
local RIGHT_WIDTH = 50

--- Pads or truncates clean text to an exact length.
local function fit_text(text, max_width, truncate_smart)
    text = tostring(text or "")
    if #text > max_width then
        if truncate_smart then
            return text:sub(1, 15) .. "..." .. text:sub(#text - (max_width - 19))
        else
            return text:sub(1, max_width - 3) .. "..."
        end
    end
    return text .. string.rep(" ", max_width - #text)
end

--- Centers clean text within a given maximum width safely.
local function center_text(text, max_width)
    text = tostring(text or "")
    if #text >= max_width then
        return text:sub(1, max_width)
    end
    local total_spaces = max_width - #text
    local left_spaces = math.floor(total_spaces / 2)
    local right_spaces = total_spaces - left_spaces
    return string.rep(" ", left_spaces) .. text .. string.rep(" ", right_spaces)
end

--- Configures the terminal raw mode using stty
local function set_raw_mode(enable)
    if enable then
        os.execute("stty -echo cbreak")
    else
        os.execute("stty echo -cbreak")
    end
end

--- Renders an elegant and indestructible dual-box layout using independent panels
local function render_menu(hosts, selected_index)
    io.write(CLEAR_SCREEN .. CURSOR_HOME)
    
    -- 1. Top Borders (Two independent boxes separated by a space)
    io.write("┌" .. string.rep("─", LEFT_WIDTH + 2) .. "┐ ┌" .. string.rep("─", RIGHT_WIDTH + 2) .. "┐\n")
    
    -- 2. Header Line (Centered Titles)
    local left_title  = center_text("SELECT SSH SERVER", LEFT_WIDTH + 2)
    local right_title = center_text("CONNECTION DETAILS", RIGHT_WIDTH + 2)
    io.write("│" .. TEXT_BOLD .. TEXT_CYAN .. left_title .. TEXT_RESET .. "│ │" .. TEXT_BOLD .. TEXT_CYAN .. right_title .. TEXT_RESET .. "│\n")
    
    -- 3. Header Dividers
    io.write("├" .. string.rep("─", LEFT_WIDTH + 2) .. "┤ ├" .. string.rep("─", RIGHT_WIDTH + 2) .. "┤\n")

    -- Fixed target to 14 maximum rows to ensure extra vertical spacing
    local max_rows = math.max(#hosts, 14)
    local active_host = hosts[selected_index] or { alias = "[None]", hostname = "[Unknown]", user = "[None]", port = "[default]", identity_file = "None" }

    -- Validar de forma segura si el puerto viene vacío, nulo o 22 para forzar el [default] visual
    local port_display = active_host.port
    if not port_display or port_display == "" or port_display == "22" then
        port_display = "[default]"
    end

    -- 4. Content Loop
    for i = 1, max_rows do
        -- --- LEFT PANEL ---
        local left_raw = ""
        local is_selected = (i == selected_index)
        
        if i <= #hosts then
            left_raw = string.format(" [%d] %s", i, hosts[i].alias)
        end
        
        local left_padded = fit_text(left_raw, LEFT_WIDTH)
        local left_content = ""
        if is_selected and i <= #hosts then
            left_content = BG_HIGHLIGHT .. " >" .. left_padded .. TEXT_RESET
        else
            left_content = "  " .. left_padded
        end

        -- --- RIGHT PANEL ---
        -- Print the left box first
        io.write("│" .. left_content .. "│ ")

        -- Process and render the right box independently
        if i == 8 or i == 10 then
            io.write("├" .. string.rep("─", RIGHT_WIDTH + 2) .. "┤\n")
        else
            io.write("│") -- Open right box wall
            
            if i == 1 then
                io.write("  " .. TEXT_YELLOW .. "Host Alias:  " .. TEXT_RESET .. fit_text(active_host.alias, RIGHT_WIDTH - 13))
            elseif i == 2 then
                io.write("  " .. TEXT_YELLOW .. "Hostname:    " .. TEXT_RESET .. fit_text(active_host.hostname, RIGHT_WIDTH - 13))
            elseif i == 3 then
                io.write("  " .. TEXT_YELLOW .. "User:        " .. TEXT_RESET .. fit_text(active_host.user, RIGHT_WIDTH - 13))
            elseif i == 4 then
                io.write("  " .. TEXT_YELLOW .. "Port:        " .. TEXT_RESET .. fit_text(port_display, RIGHT_WIDTH - 13))
            elseif i == 5 then
                local key_display = active_host.identity_file
                if key_display == "None" then key_display = "[None]" end
                io.write("  " .. TEXT_YELLOW .. "SSH Key:     " .. TEXT_RESET .. fit_text(key_display, RIGHT_WIDTH - 13, true))
            elseif i == 6 or i == 7 then
                io.write(string.rep(" ", RIGHT_WIDTH + 2))
            elseif i == 9 then
                local kb_title = center_text("KEYBINDINGS", RIGHT_WIDTH + 2)
                io.write(TEXT_BOLD .. TEXT_CYAN .. kb_title .. TEXT_RESET)
            elseif i == 11 then
                local part1 = "[Arrows/j/k] Move"
                local part2 = "[Enter/Ctrl+J] Run"
                io.write("  " .. TEXT_BOLD .. TEXT_CYAN .. "[Arrows/j/k]" .. TEXT_RESET .. " Move       " .. TEXT_BOLD .. TEXT_CYAN .. "[Enter/Ctrl+J]" .. TEXT_RESET .. " Run")
                io.write(string.rep(" ", (RIGHT_WIDTH + 2) - (2 + #part1 + 7 + #part2)))
            elseif i == 12 then
                local part1 = "[n]          New"
                local part2 = "[e]            Edit"
                io.write("  " .. TEXT_BOLD .. TEXT_CYAN .. "[n]" .. TEXT_RESET .. "          New        " .. TEXT_BOLD .. TEXT_CYAN .. "[e]" .. TEXT_RESET .. "            Edit")
                io.write(string.rep(" ", (RIGHT_WIDTH + 2) - (2 + #part1 + 8 + #part2)))
            elseif i == 13 then
                local part1 = "[d]          Delete"
                local part2 = "[q]            Quit"
                io.write("  " .. TEXT_BOLD .. TEXT_CYAN .. "[d]" .. TEXT_RESET .. "          Delete     " .. TEXT_BOLD .. TEXT_CYAN .. "[q]" .. TEXT_RESET .. "            Quit")
                io.write(string.rep(" ", (RIGHT_WIDTH + 2) - (2 + #part1 + 5 + #part2)))
            else
                io.write(string.rep(" ", RIGHT_WIDTH + 2))
            end
            
            io.write("│\n") -- Close right box wall cleanly
        end
    end

    -- 5. Bottom Borders
    io.write("└" .. string.rep("─", LEFT_WIDTH + 2) .. "┘ └" .. string.rep("─", RIGHT_WIDTH + 2) .. "┘\n")
end

--- Starts the interactive TUI loop
function UI.show_menu(hosts)
    if #hosts == 0 then
        print("Error: No hosts available to display.")
        return nil, "quit"
    end

    local selected_index = 1
    local running = true
    local chosen_host = nil
    local action = "connect"

    io.write(HIDE_CURSOR)
    set_raw_mode(true)

    while running do
        render_menu(hosts, selected_index)
        
        local char = io.read(1)

        if char == "q" or char == "Q" then
            action = "quit"
            running = false
        elseif char == "\n" then
            chosen_host = hosts[selected_index]
            action = "connect"
            running = false
        -- CAPTURA DE BOTONES DE CONTROL (Retornan la acción al archivo principal)
        elseif char == "n" or char == "N" then
            chosen_host = nil
            action = "new"
            running = false
        elseif char == "e" or char == "E" then
            chosen_host = hosts[selected_index]
            action = "edit"
            running = false
        elseif char == "d" or char == "D" then
            chosen_host = hosts[selected_index]
            action = "delete"
            running = false
        elseif char == "j" then
            selected_index = selected_index + 1
            if selected_index > #hosts then selected_index = 1 end
        elseif char == "k" then
            selected_index = selected_index - 1
            if selected_index < 1 then selected_index = #hosts end
        elseif char == "\27" then
            local next1 = io.read(1)
            local next2 = io.read(1)
            if next1 == "[" then
                if next2 == "A" then
                    selected_index = selected_index - 1
                    if selected_index < 1 then selected_index = #hosts end
                elseif next2 == "B" then
                    selected_index = selected_index + 1
                    if selected_index > #hosts then selected_index = 1 end
                end
            end
        end
    end

    set_raw_mode(false)
    io.write(SHOW_CURSOR .. CLEAR_SCREEN .. CURSOR_HOME)

    -- Retorna dos valores: El host seleccionado (si aplica) y la acción que se debe ejecutar
    return chosen_host, action
end

return UI