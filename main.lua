local run_service = game:GetService("RunService");

pcall(function()
  if hum then 
    sethiddenproperty(hum,
      "InternalBodyScale",
      Vector3.new(9e99,9e99,9e99)
    )
  end

  sethiddenproperty(workspace,
    "InterpolationThrottling", 
    Enum.InterpolationThrottlingMode.Disabled
  )
  
  sethiddenproperty(workspace,
    "PhysicsSimulationRate", 
    Enum.PhysicsSimulationRate.Fixed240Hz
  )

  sethiddenproperty(workspace,
    "PhysicsSteppingMethod", 
    Enum.PhysicsSteppingMethod.Fixed
  )

  settings().Physics.PhysicsEnvironmentalThrottle = Enum.EnviromentalPhysicsThrottle.Disabled
  settings().Physics.AllowSleep = false
  settings().Rendering.EagerBulkExecution = true
  settings().Physics.ForceCSGv2 = false
  settings().Physics.DisableCSGv2 = true
  settings().Physics.UseCSGv2 = false
end)

pcall(function() setscriptable(plr, "SimulationRadius", true) end)
	
run_service["Heartbeat"]:Connect(function()
		plr.SimulationRadius = 1e+10
		plr.MaximumSimulationRadius = 1e+10
end)

--!strict

local debounce_tick: number = 0 

local function do_options(tabl, options)
	if type(tabl) ~= "table" then
		tabl = options
	else
		for i,v in pairs(options) do
			local val do
				if type(tabl[i]) ~= "nil" then
					val = tabl[i]
				else
					val = options[i]
				end
			end
	
			tabl[i] = val
		end
	end

	return tabl
end

net_module.calculate_vel = function(hum: Humanoid?, model: Model?, options: table?): Vector3
	options = do_options(options,
		{
			st_vel = Vector3.new(0,50,0), --Stational Velocity
			dv_debounce = .05, --Dynamic Velocity debounce
			dv_multiplier = 50, --Dynamic Velocity apmplifier
			rv_multiplier = 5,  --Rotational Velocity apmplifier
			dynamic_vel = false, --If dynamic velocity is enabled
      jum_vel = Vector3.new(0,0,0),
			calc_rotvel = true --If rotvel calculation is enabled(otherwise 0,0,0)
		}
	)

	local vel, rotvel: Vector3 do
		local debounce_tick: number = 0 

		if not options.dynamic_vel or hum.MoveDirection.Magnitude == 0 then
			if tick() - debounce_tick < options.dv_debounce then
				vel = (hum.MoveDirection * options.dv_multiplier) + options.st_vel / 2
			else
				vel = options.st_vel + (options.jum_vel and Vector3.new(0, model.PrimaryPart.AssemblyLinearVelocity.Y, 0) or Vector3.zero)
			end
		else
			vel = (hum.MoveDirection * options.dv_multiplier)
            vel += (options.jum_vel and Vector3.new(0, model.PrimaryPart.AssemblyLinearVelocity.Y, 0) or Vector3.zero)

			debounce_tick = tick()
		end

		if options.calc_rotvel then
			rotvel = rotvel or Vector3.one * options.rv_multiplier
		else
			rotvel = Vector3.zero
		end
	end

	return vel,rotvel
end

net_module.stabilize = function(part: BasePart, part_to: BasePart, hum: Humanoid, model: Model, options: table?): RBXScriptConnection
	options = do_options(options,
		{
			st_vel = Vector3.new(0,50,0), --Stational Velocity
			dv_debounce = .05, --Dynamic Velocity debounce
			dv_multiplier = 50, --Dynamic Velocity apmplifier
			rv_multiplier = 5,  --Rotational Velocity apmplifier
			dynamic_vel = false, --If dynamic velocity is enabled
      jum_vel = Vector3.new(0,0,0),
			calc_rotvel = true --If rotvel calculation is enabled(otherwise 0,0,0)
		}
	)

	local rs_con,hb_con: RBXScriptConnection do
		rs_con = run_service["Heartbeat"]:Connect(function()
			part.CFrame = part_to.CFrame * options.cf_offset
		end)

		if options.apply_vel then
			hb_con = run_service["Heartbeat"]:Connect(function()
				part.CFrame = part_to.CFrame * options.cf_offset

				local vel, rotvel: Vector3 = net_module.calculate_vel(
					options.dynamic_vel and hum,
					options.calc_rotvel and part_to.AssemblyAngularVelocity,
                    model,
					options
				)

				part:ApplyImpulse(vel)
				part:ApplyAngularImpulse(rotvel)

				part.AssemblyLinearVelocity = vel
				part.RotVelocity = rotvel --RotVelocity is built different

				part.CFrame = part_to.CFrame * options.cf_offset
			end)
		end
	end

	return rs_con, hb_con
end

return net_module
