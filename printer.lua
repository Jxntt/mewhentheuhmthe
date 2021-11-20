--[[
    Author: Jxl
    Description: A block printer module
]]

local Printer = {}

do
    local remotePath = game.ReplicatedStorage.rbxts_include.node_modules.net.out:FindFirstChild('_NetManaged')
    local PLACE_BLOCK = remotePath.CLIENT_BLOCK_PLACE_REQUEST
    local HIT_BLOCK = remotePath.CLIENT_BLOCK_HIT_REQUEST
    local HEARTBEAT = game:GetService("RunService").Heartbeat
    local UNBREAKABLE_GRASS_POSITION = Vector3.new(6, -6, -141)
    game.Workspace:WaitForChild("Islands")
    function getIsland()
        for i,v in pairs(game.Workspace.Islands:GetChildren()) do 
            if v:FindFirstChild("Root") and math.abs(v.PrimaryPart.Position.X - game.Players.LocalPlayer.Character:WaitForChild("HumanoidRootPart").Position.X) <= 1000 and math.abs(v.PrimaryPart.Position.Z - game.Players.LocalPlayer.Character:WaitForChild("HumanoidRootPart").Position.Z) <= 1000 then 
                if v.Owners:FindFirstChild(""..game.Players.LocalPlayer.UserId) then
                    return v
                end
            elseif v:FindFirstChild("Root") and math.abs(v.PrimaryPart.Position.X - game.Players.LocalPlayer.Character:WaitForChild("HumanoidRootPart").Position.X) > 1000 and math.abs(v.PrimaryPart.Position.Z - game.Players.LocalPlayer.Character:WaitForChild("HumanoidRootPart").Position.Z) > 1000 and v.Owners:FindFirstChild(""..game.Players.LocalPlayer.UserId) then
                return v
            end 
        end 
    end

    Printer.__index = Printer

    setmetatable(Printer, {
        __tostring = function()
            return "Printer"
        end
    })
    
    function Printer.new(Start, End, Block)
        return setmetatable({
            Start = Start,
            End = End,
            Block = Block,
            Abort = false
        }, Printer)
    end

    function Printer:SetStart(Start)
        self.Start = Start
    end

    function Printer:SetEnd(End)
        self.End = End
    end

    function Printer:SetBlock(Block)
        self.Block = Block
    end

    function Printer:IsTaken(Position)
        local Parts = workspace:FindPartsInRegion3(Region3.new(Position, Position), nil, math.huge)
        for i, v in next, Parts do
            if v.Parent and v.Parent.Name == "Blocks" then
                return true
            end
        end
        return false
    end

    function Printer:Build(Callback)
        Callback.Start()
        local Start, End = Vector3.new(math.min(self.Start.X, self.End.X), math.min(self.Start.Y, self.End.Y), math.min(self.Start.Z, self.End.Z)), Vector3.new(math.max(self.Start.X, self.End.X), math.max(self.Start.Y, self.End.Y), math.max(self.Start.Z, self.End.Z))
        for X = Start.X, End.X, 3 do
            for Y = Start.Y, End.Y, 3 do
                for Z = Start.Z, End.Z, 3 do
                    if self.Abort then return end

                    local Position = Vector3.new(X, Y, Z)
                    Callback.Build(Position)

                    if not self:IsTaken(Position) then
                        local placed = false					
                        local newBlocksConnection = getIsland().Blocks.ChildAdded:connect(function(partAdded)
                            if partAdded:IsA("BasePart") and partAdded.CFrame == CFrame.new(Position) then
                                placed = true
                            end
                        end)
                        repeat game.RunService.RenderStepped:wait()
                            placed = false
                            local isSuccess = PLACE_BLOCK:InvokeServer({cframe = CFrame.new(Position), blockType = self.Block}).success
                            if placed and isSuccess then
                                break
                            end
                        until placed
                        game.RunService.RenderStepped:wait()
                        if newBlocksConnection then newBlocksConnection:Disconnect(); newBlocksConnection = nil; end;
                    end
                end
            end
        end

        Callback.End()
    end

    function Printer:Reverse(Callback)
        Callback.Start()
        local Start, End = Vector3.new(math.min(self.Start.X, self.End.X), math.min(self.Start.Y, self.End.Y), math.min(self.Start.Z, self.End.Z)), Vector3.new(math.max(self.Start.X, self.End.X), math.max(self.Start.Y, self.End.Y), math.max(self.Start.Z, self.End.Z))
        local Region = Region3.new(Start, End)

        for i, v in next, workspace:FindPartsInRegion3(Region, nil, math.huge) do
            if self.Abort then 
                self.Abort = false 
                Callback.End()
                break 
            end
            if v:FindFirstChild("Health") and v.Name ~= "bedrock" and not v:FindFirstChild("portal-to-spawn") then
            repeat game.RunService.Heartbeat:wait()
                    if v then
                        Callback.Build(v.Position)
                        HIT_BLOCK:InvokeServer({
                            player_tracking_category = "join_from_web";
                            part = v;
                            block = v;
                            norm = v.Position;
                            pos = Vector3.new(-1, 0, 0)
                        })
                    end
                until not v or not v:IsDescendantOf(workspace) or self.Abort == true
            end
        end
        Callback.End()
    end
end

return Printer
