local ServerScriptService = game:GetService("ServerScriptService")

local Cmdr = require(ServerScriptService.Packages.Cmdr)

-- ── Admin whitelist ────────────────────────────────────────────────────
-- Add your Roblox UserId(s) here.
-- Find yours at: roblox.com/users/profile  (the number in the URL)
local ADMIN_IDS: { number } = {
    -- 123456789,  -- example
}

-- ── Register commands ──────────────────────────────────────────────────
Cmdr:RegisterDefaultCommands()
Cmdr:RegisterCommandsIn(script.Parent.Commands)

-- ── Admin gate ────────────────────────────────────────────────────────
Cmdr:BeforeRun(function(context)
    if context.Group == "Admin" then
        if not table.find(ADMIN_IDS, context.Executor.UserId) then
            return "⛔ Sin permiso."
        end
    end
end)
