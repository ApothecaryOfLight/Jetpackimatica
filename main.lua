local jetpack_timer_step = 0.01
local jetpack_timer = 0

local player_jetpack = nil

modlib.log.create_channel( "jetpackimatica" );
modlib.log.write( "jetpackimatica", "test" );

local old_print = print;

local function print_replace( inMessage )
	old_print( inMessage )
	modlib.log.write( "jetpackimatica", inMessage );
end

local lag_detected = false;

print = print_replace;

--code instrumentation to determine why server performance seems so bad
local lastTime = nil;

local function jetpack_step(player,jetpack_time)
	--print( "JETPACK_TIME:"..jetpack_time )
	local timeLag = jetpack_time/jetpack_timer_step;
	--print( "multiplier:"..timeLag )
	local myMeta = player:get_meta()
	local player_jetpack_level = myMeta:get_int( 'player_jetpack_level' )
	if player_jetpack_level == nil then
		player_jetpack_level = 0
		myMeta:set_int( 'player_jetpack_level', 0 )		
	end
	if player_jetpack_level > 0 then
		local playerControl = player:get_player_control()
		if playerControl.jump == true then
			local velocity = player:get_player_velocity()
			local lookDir = player:get_look_dir()
			local velocity_max = 6
			local velocity_incremenent = 1
			if player_jetpack_level == 1 then
				velocity_max = 2
				velocity_incremenent = 1
			elseif player_jetpack_level == 2 then
				velocity_max = 5
				velocity_increment = 3
			elseif player_jetpack_level == 3 then
				velocity_max = 10
				velocity_increment = 4
			end
			local velocity_calc = velocity_incremenent*timeLag;
			velocity_calc = math.min( velocity_calc, velocity_max )
			print( "Adding velocity "..velocity_calc.."." )
			if velocity.y < velocity_max then
				player:add_player_velocity(
					{
						x=lookDir.x,
						y=velocity_calc,
						z=lookDir.z
					}
				)
			end
		end
	end
end

minetest.register_on_player_hpchange( function(player, hp_change, reason)
	if player_jetpack ~= nil and reason.type == 'fall' then
		return 0
	else
		return hp_change
	end
end, true )

minetest.register_globalstep( function(dtime)
	jetpack_timer = jetpack_timer + dtime
	if jetpack_timer >= jetpack_timer_step then
		for _, player in ipairs( minetest.get_connected_players() ) do
			jetpack_step( player, jetpack_timer )
		end
		jetpack_timer = 0
	end
end)

minetest.register_on_leaveplayer( function( ObjectRef, timed_out )
	print( "[JETPACKS] On Leaveplayer" )
	if player_jetpack ~= nil then
		print( "[JETPACKS] Removing Jetpack on player leave." );
		player_jetpack:remove()
		player_jetpack = nil
	end
	print( "[JETPACKS] Player left" )
end)

minetest.register_on_shutdown( function()
	print( "[JETPACKS] Shutting down!" )
	if player_jetpack ~= nil then
		print( "[JETPACKS] Removing Jetpack on shutdown." );
		--print( dump( player_jetpack ) )
		player_jetpack:remove()
		player_jetpack = nil
	end
	print( "[JETPACKS] Shut down." )
end)

local function doRegisterJetpack( inSystemName, inUserName, inJetpackLevel, inTextureName )
	local modname = "jetpackimatica:"..inSystemName;
	local inventory_image_name = "jetpacks_"..inSystemName..".png";
	local inventory_worn = "jetpackimatica:"..inSystemName.."_worn";

	minetest.register_tool(modname, {
		description = inUserName,
		inventory_image = inventory_image_name,
		groups = {armor_torso=1, armor_heal=0, armor_use=1000},
		armor_groups = {fleshy=20},
		damage_groups = {cracky=3, snappy=3, choppy=2, crumbly=2, level=1},
		stack_max = 1,
		on_equip = function( player, index, itemstack )
			print( "[JETPACKS] on_equip "..inSystemName )
			if player_jetpack ~= nil then
				print( "equip: jetpack exists!" );
			else
				print ( "equip: jetpack doesn't exist!" );
				local myMeta = player:get_meta()
				local player_jetpack_level = myMeta:get_int( 'player_jetpack_level' )
				local playerPos = player:get_pos()
		
				player_jetpack = minetest.add_entity(
					playerPos,
					"jetpackimatica:basic_jetpack_worn"
				)
	
				local attach = player_jetpack:set_attach(
						player,
						"",
						{ x=0, y=5.5, z=-3.0 },
						{ x=0, y=0, z=0 }
				)
		
				myMeta:set_int( 'player_jetpack_level', inJetpackLevel )
				print( "[JETPACKS] Equipped!")
			end
	
		end,
		on_unequip = function( player, index, stack )
			print( "[JETPACKS] on_unequip "..inSystemName )
			if player_jetpack ~= nil then
				print( "equip: jetpack exists!" );
				local myMeta = player:get_meta()
				myMeta:set_int( "player_jetpack_level", 0 )
		
				player_jetpack:remove()
				player_jetpack = nil;
				print( "[JETPACKS] Unequipped "..inSystemName )
			else
				print ( "equip: jetpack doesn't exist!" );
			end
		end,
		on_punch = function( pos, node, puncher, pointed_thing )
			print( "[JETPACKS] on_punch!")
			print( dump( getmetatable( pointed_thing ) ) )
		end,
		on_detach = function (self, parent)
			print( "[JETPACKS] on_detach!" )
		end,
	})
	minetest.register_entity(inventory_worn, {
		initial_properties = {
			visual = "mesh",
			mesh = "jetpacks_basic.b3d",
			phyiscal = false,
			collisionbox = { -0.2, -0.3, -0.2, 0.2, 0.3, 0.2 },
			visual_size = { x=6, y=6 },
			textures = {
				"blown-up-jetpack_"..inTextureName.."_map_wraparound.png"
			},
		},
	})
	default.player_register_model("jetpacks_testing_a.b3d", {
		animation_speed = 30,
		textures = {
			"blown-up-jetpack_"..inTextureName.."_map_wraparound.png"
		},
		animations = {
			stand = {x=0, y=1},
			lay = {x=0, y=0},
			walk = {x=0, y=0},
			mine = {x=0, y=0},
			walk_mine = {x=0, y=0},
			sit = {x=0, y=0},
		},
	})
end

doRegisterJetpack( "basic_jetpack", "Basic Jetpack", 1, "basic" );
doRegisterJetpack( "advanced_jetpack", "Advanced Jetpack", 2, "advanced" );
doRegisterJetpack( "super_jetpack", "Super Jetpack", 3, "super" );

minetest.register_craft({
	output = "jetpackimatica:basic_jetpack",
	recipe = {
		{"group:wood", "group:wood", "group:wood"},
		{"group:wood", "group:stone", "group:wood"},
		{"group:wood", "group:wood", "group:wood"}
	}
})
minetest.register_craft({
	output = "jetpackimatica:super_jetpack",
	recipe = {
		{"default:gold", "default:gold", "default:gold"},
		{"default:gold", "group:stone", "default:gold"},
		{"default:gold", "default:gold", "default:gold"}
	}
})

print("[JETPACKS] Done loading.")
