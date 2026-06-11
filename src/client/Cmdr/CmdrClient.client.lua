-- Activates the Cmdr console.
-- Press F2 (or add your UserId to ADMIN_IDS in CmdrSetup) to open.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CmdrClient = require(ReplicatedStorage:WaitForChild("CmdrClient", 10))
if CmdrClient then
    CmdrClient:SetActivationKeys({ Enum.KeyCode.F2 })
end
