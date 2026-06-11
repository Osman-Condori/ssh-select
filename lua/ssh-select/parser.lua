-- lua/ssh-select/parser.lua
local Parser = {}

--- Removes leading and trailing whitespace from a string
local function trim(s)
    return s:match("^%s*(.-)%s*$")
end

--- Retrieves the current system user as a fallback default value
local function get_default_user()
    return os.getenv("USER") or os.getenv("LOGNAME") or "root"
end

--- Parses the SSH configuration file
-- @param filepath Optional. Path to the ssh config file (defaults to ~/.ssh/config)
-- @return An indexed table containing all the parsed hosts
function Parser.parsear(filepath)
    if not filepath then
        local home = os.getenv("HOME") or "/root"
        filepath = home .. "/.ssh/config"
    end

    local hosts = {}
    local current_host = nil
    local default_user = get_default_user()

    local file, err = io.open(filepath, "r")
    if not file then
        -- If the config file does not exist, return an empty list safely
        return hosts
    end

    for line in file:lines() do
        line = trim(line)

        -- Ignore empty lines and comments starting with '#'
        if line ~= "" and not line:match("^#") then
            
            -- Detect "Host <alias>" directive (Case Insensitive)
            local host_alias = line:match("^[Hh][Oo][Ss][Tt]%s+(.+)$")
            
            if host_alias then
                -- Ignore the global wildcard '*' to prevent it from showing up in the TUI
                if host_alias ~= "*" then
                    -- If a host block was already being processed, save it first
                    if current_host then
                        table.insert(hosts, current_host)
                    end
                    -- Initialize a new container with safe default values
                    current_host = {
                        alias = host_alias,
                        hostname = "Unknown",
                        user = default_user,
                        port = "22",
                        identity_file = "None"
                    }
                else
                    -- If it's a global "Host *" block, close the current container
                    -- to prevent global directives from polluting the last valid host
                    if current_host then
                        table.insert(hosts, current_host)
                        current_host = nil
                    end
                end
            
            -- If we are inside a valid Host block, collect its properties
            elseif current_host then
                
                -- Capture HostName
                local h_name = line:match("^[Hh][Oo][Ss][Tt][Nn][Aa][Mm][Ee]%s+(.+)$")
                if h_name then current_host.hostname = trim(h_name) end

                -- Capture User
                local u_name = line:match("^[Uu][Ss][Ee][Rr]%s+(.+)$")
                if u_name then current_host.user = trim(u_name) end

                -- Capture Port
                local port = line:match("^[Pp][Oo][Rr][Tt]%s+(.+)$")
                if port then current_host.port = trim(port) end

                -- Capture IdentityFile (Private key)
                local id_file = line:match("^[Ii][Dd][Ee][Nn][Tt][Ii][Tt][Yy][Ff][Ii][Ll][Ee]%s+(.+)$")
                if id_file then current_host.identity_file = trim(id_file) end
            end
        end
    end

    -- After the loop ends, save the last processed host if any
    if current_host then
        table.insert(hosts, current_host)
    end

    file:close()
    return hosts
end

return Parser
