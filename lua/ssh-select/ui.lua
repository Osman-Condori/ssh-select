-- lua/ssh-select/ui.lua
local UI = {}

-- ANSI Escape Sequences for terminal control
local CLEAR_SCREEN = "\27[2J"
local CURSOR_HOME  = "\27[H"
local HIDE_CURSOR  = "\27[?25l"
local SHOW_CURSOR  = "\27[?25h"
local TEXT_RESET   = "\27[0m"
local BG_HIGHLIGHT = "\27[44m\27[37m" -- Blue background with white text
local TEXT_BOLD    = "\27[1m"
local TEXT_CYAN    = "\27[36m"

--- Configures the terminal raw mode using stty
local function set_raw_mode(enable)
    if enable then
        -- Disable echo and enter raw mode so keystrokes are read immediately
        os.execute("stty -echo cbreak")
    else
        -- Restore default terminal settings
        os.execute("stty echo -cbreak")
    end
end

--- Renders the menu on the terminal screen
-- @param hosts Table containing the parsed list of hosts
-- @param selected_index Integer representing the currently highlighted host
local function render_menu(hosts, selected_index)
    -- Clear screen and move cursor to top-left
    io.write(CLEAR_SCREEN .. CURSOR_HOME)
    
    -- Print header
    io.write(TEXT_BOLD .. TEXT_CYAN .. "=========================================\n")
    io.write("       SSH-SELECT - Interactive Menu     \n")
    io.write("=========================================\n" .. TEXT_RESET)
    io.write(" Use Up/Down arrows to select, Enter to connect, 'q' to quit.\n\n")

    if #hosts == 0 then
        io.write(" No hosts found in ~/.ssh/config\n")
        return
    end

    -- Print host list with consistent formatting
    for i, host in ipairs(hosts) do
        if i == selected_index then
            -- Highlighted row: Includes the blue background and an active arrow indicator '>'
            io.write(string.format("%s > [%d] %s (%s@%s:%s) %s\n", 
                BG_HIGHLIGHT, i, host.alias, host.user, host.hostname, host.port, TEXT_RESET))
        else
            -- Normal row: Clean indentation to align perfectly with the highlighted row
            io.write(string.format("   [%d] %s (%s@%s:%s)\n", 
                i, host.alias, host.user, host.hostname, host.port))
        end
    end
end

--- Starts the interactive TUI loop
-- @param hosts Table with the parsed hosts to display
-- @return The selected host table, or nil if aborted
function UI.show_menu(hosts)
    if #hosts == 0 then
        print("Error: No hosts available to display.")
        return nil
    end

    local selected_index = 1
    local running = true
    local chosen_host = nil

    -- Setup terminal environment
    io.write(HIDE_CURSOR)
    set_raw_mode(true)

    while running do
        render_menu(hosts, selected_index)
        
        -- Read a single byte from stdin
        local char = io.read(1)

        if char == "q" or char == "Q" then
            running = false
        elseif char == "\n" then
            chosen_host = hosts[selected_index]
            running = false
        -- Detect ANSI arrow key sequences (Esc [ A or Esc [ B)
        elseif char == "\27" then
            local next1 = io.read(1)
            local next2 = io.read(1)
            if next1 == "[" then
                if next2 == "A" then -- Up Arrow
                    selected_index = selected_index - 1
                    if selected_index < 1 then selected_index = #hosts end
                elseif next2 == "B" then -- Down Arrow
                    selected_index = selected_index + 1
                    if selected_index > #hosts then selected_index = 1 end
                end
            end
        end
    end

    -- Restore terminal environment
    set_raw_mode(false)
    io.write(SHOW_CURSOR .. CLEAR_SCREEN .. CURSOR_HOME)

    return chosen_host
end

return UI
