local CreateClientConVar = CreateClientConVar
local FrameTime = FrameTime
local GetConVar = GetConVar
local IsValid = IsValid
local Lerp = Lerp
local LocalPlayer = LocalPlayer
local game = game
local game_SinglePlayer = game.SinglePlayer
local hook = hook
local hook_Add = hook.Add
local hook_Run = hook.Run

CreateClientConVar("cl_physgun_claws", 1, true, true, "Enable/Disable the physgun claws animation")
CreateClientConVar("cl_physgun_claws_sound", 1, true, true, "Enable/Disable the physgun claws sound")
CreateClientConVar("cl_physgun_claws_animation", 1, true, true, "Enable/Disable the physgun claws animation")
CreateClientConVar("cl_physgun_claws_smoothness", 10, true, true, "Set the smoothness of the physgun claws animation")

local f1, f2 = -Vector(4,4,4), Vector(4,4,4)

local function CheckForTargets(owner, weapon)
	if weapon:GetNW2Float("PhysgunClawDebounce", 0) > CurTime() then
		return
	end

	local startPos = owner:GetShootPos()
	local endPos = owner:GetShootPos()+owner:GetAimVector()*(2^15)

	
	owner:LagCompensation( true )
	local tr = util.TraceHull( {
		start = startPos,
		endpos = endPos,
		filter = owner,
		mins = f1,
		maxs = f2,
		mask = MASK_SHOT+CONTENTS_GRATE,
		collisiongroup = COLLISION_GROUP_NONE,
	} )
	owner:LagCompensation( false )

	local ent = tr.Entity
	local result = IsValid(ent)--!( ( IsValid(ent) and hook_Run("PhysgunPickup", owner, ent) != true ) or hook_Run("GetPreferredCarryAngles", owner) != nil )

	--print(ent)

	if SERVER and owner:KeyPressed(IN_ATTACK) and ( IsValid(ent) and hook_Run("PhysgunPickup", owner, ent) != true ) then
		weapon:EmitSound("fesiug/physgun_claws/physcannon_decline.wav")
		--weapon:SetNW2Float("PhysgunClawDebounce", CurTime() + 0.5)
		return
	end

	local oldstate = weapon:GetNW2Int("PhysgunClawState", 0)
	local newstate = result and 1 or 0

	if weapon:GetNW2Int("PhysgunClawState", 0) == 2 then
	else
		if (newstate==0) and (oldstate>=1) then
			weapon:EmitSound(false and "fesiug/physgun_claws/physgun_off.wav" or "Weapon_PhysCannon.CloseClaws")

			weapon:SetNW2Float("PhysgunClawTimeStart", CurTime())
		elseif (newstate>=1) and (oldstate==0) then
			weapon:EmitSound(false and "fesiug/physgun_claws/physgun_on.wav" or "Weapon_PhysCannon.OpenClaws")

			weapon:SetNW2Float("PhysgunClawTimeStart", CurTime())
		end
		if result then
			weapon:SetNW2Float("PhysgunClawDebounce", CurTime()+0.75)
		end
		weapon:SetNW2Int("PhysgunClawState", result and 1 or 0)
	end

end

if SERVER then
	hook_Add("PhysgunDrop", "PhysgunClawsPhysgunDrop", function(ply, ent)
		if ply:IsValid() and ent:IsValid() then
			local weapon = ply:GetWeapon("weapon_physgun")
			if weapon:IsValid() then
				weapon:SetNW2Int("PhysgunClawState", 1)
			end
		end
	end)
	hook_Add("OnPhysgunPickup", "PhysgunClawsOnPhysgunPickup", function(ply, ent)
		if ply:IsValid() and ent:IsValid() then
			local weapon = ply:GetWeapon("weapon_physgun")
			if weapon:IsValid() then
				weapon:SetNW2Int("PhysgunClawState", 2)
			end
		end
	end)
end

if CLIENT then
	local STARTED = false
	local PREVRELOAD = false
	hook_Add("DrawPhysgunBeam", "PhysgunClawsDrawPhysgunBeam", function(ply, physgun, enabled, target, physbone, hitpos)
		if ply:IsValid() and physgun:IsValid() then
			if !physgun.S1 then
				physgun.S1 = CreateSound(physgun, "fesiug/physgun_claws/physgun_loop1.wav")
			end
			if !physgun.S2 then
				physgun.S2 = CreateSound(physgun, "fesiug/physgun_claws/physgun_loop2.wav")
			end
			if !physgun.S3 then
				physgun.S3 = CreateSound(physgun, "fesiug/physgun_claws/physgun_loop3.wav")
			end
			if !physgun.S4 then
				physgun.S4 = CreateSound(physgun, "fesiug/physgun_claws/physgun_loop4.wav")
			end

			local RELOAD = ply:KeyDown( IN_USE )

			if target:IsValid() then

				if !STARTED then
					physgun.S1:PlayEx( 0, 50 )
					physgun.S2:PlayEx( 0, 50 )
					physgun.S3:PlayEx( 0, 50 )
					physgun.S4:PlayEx( 0, 50 )

					physgun.S1:ChangeVolume( 0.8, 0.5 )
					physgun.S1:ChangePitch( 100, 0.5 )

					physgun.S2:ChangeVolume( 0.8, 0.5 )
					physgun.S2:ChangePitch( 100, 0.5 )
					STARTED = true
				end

				if RELOAD then
					if !PREVRELOAD then
						physgun.S3:ChangeVolume( 0.8, 0.5 )
						physgun.S3:ChangePitch( 100, 0.25 )
						
						physgun.S4:ChangeVolume( 0.8, 0.5 )
						physgun.S4:ChangePitch( 100, 0.5 )
					end
					PREVRELOAD = true
				else
					physgun.S3:ChangeVolume( 0, 0.5 )
					physgun.S3:ChangePitch( 50, 0.5 )

					physgun.S4:ChangeVolume( 0, 0.5 )
					physgun.S4:ChangePitch( 50, 0.5 )

					PREVRELOAD = false
				end
			else
				physgun.S1:ChangeVolume( 0, 1 )
				physgun.S1:ChangePitch( 50, 1 )

				physgun.S2:ChangeVolume( 0, 1 )
				physgun.S2:ChangePitch( 50, 1 )

				physgun.S3:ChangeVolume( 0, 1 )
				physgun.S3:ChangePitch( 50, 1 )

				physgun.S4:ChangeVolume( 0, 1 )
				physgun.S4:ChangePitch( 50, 1 )

				PREVRELOAD = false
				STARTED = false
			end
		end
	end)
end


function SimpleSpline( value )
	local valueSquared = value * value

	// Nice little ease-in, ease-out spline-like curve
	return (3 * valueSquared - 2 * valueSquared * value)
end

function SimpleSplineRemapValClamped( val, A, B, C, D )
	if ( A == B ) then
		return val >= B and D or C
	end
	local cVal = (val - A) / (B - A)
	cVal = math.Clamp( cVal, 0, 1 )
	return C + (D - C) * SimpleSpline( cVal )
end

hook_Add("Think", "PhysgunClaws", function()
	if CLIENT then
		--print("Yea", IsFirstTimePredicted())
	end
	for _, physgun in ipairs( ents.FindByClass("weapon_physgun") ) do
		if ( !IsValid(physgun) ) then continue end
		local owner = physgun:GetOwner()
		local open = physgun:GetNW2Int( "PhysgunClawState", 0 )
		if ( !IsValid(owner) or !owner:Alive() or owner:InVehicle() ) or owner:GetActiveWeapon()!=physgun or physgun:IsEffectActive(EF_NODRAW) then
			if CLIENT then
				if physgun.S1 then
					physgun.S1:Stop()
				else
					physgun.S1 = CreateSound(physgun, "fesiug/physgun_claws/physgun_loop1.wav")
					physgun.S1:Play()
					physgun.S1:Stop()
				end
				if physgun.S2 then
					physgun.S2:Stop()
				else
					physgun.S2 = CreateSound(physgun, "fesiug/physgun_claws/physgun_loop2.wav")
					physgun.S2:Play()
					physgun.S2:Stop()
				end
				if physgun.S3 then
					physgun.S3:Stop()
				else
					physgun.S3 = CreateSound(physgun, "fesiug/physgun_claws/physgun_loop3.wav")
					physgun.S3:Play()
					physgun.S3:Stop()
				end
				if physgun.S4 then
					physgun.S4:Stop()
				else
					physgun.S4 = CreateSound(physgun, "fesiug/physgun_claws/physgun_loop4.wav")
					physgun.S4:Play()
					physgun.S4:Stop()
				end
			end

			if open>=1 then
				physgun:SetNW2Int("PhysgunClawState", 0)
				physgun:EmitSound(false and "fesiug/physgun_claws/physgun_off.wav" or "Weapon_PhysCannon.CloseClaws")
				physgun:SetNW2Float("PhysgunClawTimeStart", CurTime())
				physgun:SetNW2Float("PhysgunClawDebounce", CurTime())
			end
			continue
		end

		CheckForTargets(owner, physgun)

		open = (open == 1 or open == 2) -- 1 is hovering, 2 is selecting

		local viewmodel = owner:GetViewModel()
		if ( IsValid(viewmodel) ) then

			local result
			local timestart = physgun:GetNW2Float("PhysgunClawTimeStart", 0)
			result = SimpleSplineRemapValClamped( CurTime(), timestart, timestart + (open and 0.2 or 0.5), open and 0 or 1, open and 1 or 0 )

			viewmodel:SetPoseParameter("active", result)
			if CLIENT then
				--viewmodel:InvalidateBoneCache()
			end
		end

	end
end)