local jetpack_timer_step = 0.001
local jetpack_timer = 0

local player_jetpack = {}

--[[minetest.register_on_player_hpchange( function(player, hp_change, reason)
	if player_jetpack ~= nil and reason.type == 'fall' then
		return 0
	else
		return hp_change
	end
end, true )]]

local function jetpack_step(player,jetpack_time)
	local myMeta = player:get_meta()
	local player_jetpack_level = myMeta:get_int( 'player_jetpack_level' )
	if player_jetpack_level == nil then
		player_jetpack_level = 0
		myMeta:set_int( 'player_jetpack_level', 0 )		
	end
	if player_jetpack_level > 0 then
		local ctrl = player:get_player_control()
		if ctrl.jump == true then
			local wasSpacedown = myMeta:get_int( 'isSpacedown' )
			if wasSpacedown == nil then wasSpacedown = false end
			myMeta:set_int( 'isSpacedown', 1 )
			if wasSpacedown == 1 then
				local lastPosition = myMeta:get_int('lastPosition')
				if lastPosition == 0 then
					lastPosition = player:get_pos()
					--print( dump( lastPosition ))
				end
				local currPosition = player:get_pos()
				if lastPosition.y < currPosition.y then
					print( ">>>>>>>>>>>> Uncontrolled falling!" )
					player:add_player_velocity( 20 )
				end
			end
			--print( "[JETPACKS] jetpacking going up" )
			local velocity = player:get_player_velocity()
			local lookDir = player:get_look_dir()
			local velocity_max = 6
			local velocity_incremenent = 1
			if player_jetpack_level == 1 then
				velocity_max = 6
				velocity_incremenent = 1
			elseif player_jetpack_level == 2 then
				velocity_max = 18
				velocity_increment = 5
			elseif player_jetpack_level == 3 then
				velocity_max = 60
				velocity_increment = 15
			end
			if velocity.y < velocity_max then
				player:add_player_velocity(
					{
						x=lookDir.x,
						y=velocity_incremenent,
						z=lookDir.z
					}
				)
			end
			if velocity.y < -2 then
				local meta = minetest:get_meta( player:get_pos() )
				local lastVelocity = meta:get_int("last_velocity")
				if lastVelocity ~= nil then
					if
						lastVelocity == math.floor(velocity.y) or
						lastVelocity == math.ceil(velocity.y)
					then
						return
					else
						print( "Correcting "..velocity.y.." with last_velocity of "..lastVelocity )
						player:add_player_velocity({
							x=0,
							y=math.abs(velocity.y),
							z=0}
						)
						meta:set_int( "last_velocity",velocity.y )
					end
				end
			end
		end
	end
end

minetest.register_globalstep( function(dtime)
	jetpack_timer = jetpack_timer + dtime
	if jetpack_timer >= jetpack_timer_step then
		for _, player in ipairs( minetest.get_connected_players() ) do
			jetpack_step( player, jetpack_timer )
		end
		jetpack_timer = 0
	end
end)

minetest.register_on_leaveplayer( function( ObjectRed, timed_out )
	print( "[JETPACKS] On Leaveplayer" )
	if player_jetpack ~= nil then
		player_jetpack:set_detach();
		player_jetpack:remove()
		player_jetpack = nil
	end
	print( "[JETPACKS] Player left" )
end)

minetest.register_on_shutdown( function()
	print( "[JETPACKS] Shutting down!" )
	if player_jetpack ~= nil then
		player_jetpack:set_detach();
		player_jetpack:remove()
		player_jetpack = nil
	end
	print( "[JETPACKS] Shut down." )
end)




--basic jetpack
minetest.register_tool("jetpackimatica:basic_jetpack", {
	description = "Basic Jetpack",
	inventory_image = "jetpacks_basic_jetpack.png",
	groups = {armor_torso=1, armor_heal=0, armor_use=1000},
	armor_groups = {fleshy=20},
	damage_groups = {cracky=3, snappy=3, choppy=2, crumbly=2, level=1},
	stack_max = 1,
	on_equip = function( player, index, itemstack )
		print( "[JETPACKS] on_equip")

		--local myMeta = minetest.get_meta( player.get_pos() )
		local myMeta = player:get_meta()
		local player_jetpack_level = myMeta:get_int( 'player_jetpack_level' )
		local playerPos = player:get_pos()

		player_jetpack = minetest.add_entity( playerPos, "jetpackimatica:basic_jetpack_worn" )
		minetest.after( 1, function()
			local attach = player_jetpack:set_attach(
					player,
					"",
					{ x=0, y=5.5, z=-3.0 },
					{ x=0, y=0, z=0 }
			)
		end)

		myMeta:set_int( 'player_jetpack_level', 1 )
		print( "[JETPACKS] Equipped!")
	end,
	on_unequip = function( player, index, stack )
		print( "[JETPACKS] on_unequip!")
		local myMeta = player:get_meta()
		myMeta:set_int( "player_jetpack_level", 0 )
		player_jetpack:set_detach();

		minetest.after( 0.1, function()
			player_jetpack:remove()
			player_jetpack = nil;
		end)
		print( "[JETPACKS] Unequipped!")
	end,
	on_punch = function( pos, node, puncher, pointed_thing )
		print( "[JETPACKS] on_punch!")
		print( dump( getmetatable( pointed_thing ) ) )
	end
})
--[[minetest.register_entity("jetpackimatica:basic_jetpack_worn", {
	initial_properties = {
		visual = "mesh",
		mesh = "jetpacks_test_002.b3d",
		phyiscal = false,
		collisionbox = { -0.2, -0.3, -0.2, 0.2, 0.3, 0.2 },
		visual_size = { x=6, y=6 },
		textures = {
			"color_red.png",
			"color_yellow.png"
		}
	},
})]]
minetest.register_entity("jetpackimatica:basic_jetpack_worn", {
	initial_properties = {
		visual = "mesh",
		mesh = "jetpacks_basic.b3d",
		phyiscal = false,
		collisionbox = { -0.2, -0.3, -0.2, 0.2, 0.3, 0.2 },
		visual_size = { x=6, y=6 },
		textures = {
			"blown-up-jetpack_basic_map_wraparound.png"
		},
	},
})
default.player_register_model("jetpacks_basic.b3d", {
	animation_speed = 30,
	textures = {
		"blown-up-jetpack_basic_map_wraparound.png"
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

--advanced jetpack
minetest.register_tool("jetpackimatica:advanced_jetpack", {
	description = "Advanced Jetpack",
	inventory_image = "jetpacks_advanced_jetpack.png",
	groups = {armor_torso=1, armor_heal=0, armor_use=1000},
	armor_groups = {fleshy=20},
	damage_groups = {cracky=3, snappy=3, choppy=2, crumbly=2, level=1},
	stack_max = 1,
	on_equip = function( player, index, itemstack )
		print( "[JETPACKS] on_equip")

		--local myMeta = minetest.get_meta( player.get_pos() )
		local myMeta = player:get_meta()
		local player_jetpack_level = myMeta:get_int( 'player_jetpack_level' )
		local playerPos = player:get_pos()

		player_jetpack = minetest.add_entity( playerPos, "jetpackimatica:basic_jetpack_worn" )
		minetest.after( 1, function()
			local attach = player_jetpack:set_attach(
					player,
					"",
					{ x=0, y=5.5, z=-3.0 },
					{ x=0, y=0, z=0 }
			)
		end)

		myMeta:set_int( 'player_jetpack_level', 2 )
		print( "[JETPACKS] Equipped!")
	end,
	on_unequip = function( player, index, stack )
		print( "[JETPACKS] on_unequip!")
		local myMeta = player:get_meta()
		myMeta:set_int( "player_jetpack_level", 0 )
		player_jetpack:set_detach();

		minetest.after( 0.1, function()
			player_jetpack:remove()
			player_jetpack = nil;
		end)
		print( "[JETPACKS] Unequipped!")
	end,
	on_punch = function( pos, node, puncher, pointed_thing )
		print( "[JETPACKS] on_punch!")
		print( dump( getmetatable( pointed_thing ) ) )
	end
})
--[[minetest.register_entity("jetpackimatica:advanced_jetpack_worn", {
	initial_properties = {
		visual = "mesh",
		mesh = "jetpacks_test_002.b3d",
		phyiscal = false,
		collisionbox = { -0.2, -0.3, -0.2, 0.2, 0.3, 0.2 },
		visual_size = { x=6, y=6 },
		textures = {
			"color_green.png",
			"color_tan.png"
		}
	},
})]]
minetest.register_entity("jetpackimatica:advanced_jetpack_worn", {
	initial_properties = {
		visual = "mesh",
		mesh = "jetpacks_advanced.b3d",
		phyiscal = false,
		collisionbox = { -0.2, -0.3, -0.2, 0.2, 0.3, 0.2 },
		visual_size = { x=6, y=6 },
		textures = {
			"blown-up-jetpack_advanced_map_wraparound.png"
		},
	},
})
default.player_register_model("jetpacks_advanced.b3d", {
	animation_speed = 30,
	textures = {
		"blown-up-jetpack_advanced_map_wraparound.png"
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

--super jetpack
minetest.register_tool("jetpackimatica:super_jetpack", {
	description = "Super Jetpack",
	inventory_image = "jetpacks_super_jetpack.png",
	groups = {armor_torso=1, armor_heal=0, armor_use=1000},
	armor_groups = {fleshy=20},
	damage_groups = {cracky=3, snappy=3, choppy=2, crumbly=2, level=1},
	stack_max = 1,
	on_equip = function( player, index, itemstack )
		print( "[JETPACKS] on_equip super")
		--local myMeta = minetest.get_meta( player.get_pos() )
		local myMeta = player:get_meta()
		local player_jetpack_level = myMeta:get_int( 'player_jetpack_level' )
		local playerPos = player:get_pos()
		player_jetpack = minetest.env:add_entity(
			playerPos,
			"jetpackimatica:super_jetpack_worn"
		)
		player_jetpack:set_attach(
			player,
			"",
			{ x=0, y=5.5, z=-3.0 },
			{ x=0, y=0, z=0 }
		)

		myMeta:set_int( 'player_jetpack_level', 3 )
	end,
	on_unequip = function( player, index, stack )
		print( "[JETPACKS] on_unequip!")
		local myMeta = player:get_meta()
		myMeta:set_int( "player_jetpack_level", 0 )
		player_jetpack:set_detach();

		minetest.after( 0.1, function()
			player_jetpack:remove()
			player_jetpack = nil;
		end)
	end,
	on_punch = function( pos, node, puncher, pointed_thing )
		print( "[JETPACKS] on_punch!")
		print( dump( getmetatable( pointed_thing ) ) )
	end
})
--[[minetest.register_entity("jetpackimatica:super_jetpack_worn", {
	initial_properties = {
		visual = "mesh",
		mesh = "jetpacks_test_002.b3d",
		phyiscal = false,
		collisionbox = { -0.2, -0.3, -0.2, 0.2, 0.3, 0.2 },
		visual_size = { x=6, y=6 },
		textures = {
			"color_purple.png",
			"color_blue.png"
		}
	},
})]]
minetest.register_entity("jetpackimatica:super_jetpack_worn", {
	initial_properties = {
		visual = "mesh",
		mesh = "jetpacks_super.b3d",
		phyiscal = false,
		collisionbox = { -0.2, -0.3, -0.2, 0.2, 0.3, 0.2 },
		visual_size = { x=6, y=6 },
		textures = {
			"blown-up-jetpack_super_map_wraparound.png"
		},
	},
})
default.player_register_model("jetpacks_super.b3d", {
	animation_speed = 30,
	textures = {
		"blown-up-jetpack_super_map_wraparound.png"
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




--UV Jetpack
minetest.register_tool("jetpackimatica:uv_jetpack", {
	description = "UV Jetpack",
	inventory_image = "jetpacks_super_jetpack.png",
	groups = {armor_torso=1, armor_heal=0, armor_use=1000},
	armor_groups = {fleshy=20},
	damage_groups = {cracky=3, snappy=3, choppy=2, crumbly=2, level=1},
	stack_max = 1,
	on_equip = function( player, index, itemstack )
		print( "[JETPACKS] on_equip super")
		--local myMeta = minetest.get_meta( player.get_pos() )
		local myMeta = player:get_meta()
		local player_jetpack_level = myMeta:get_int( 'player_jetpack_level' )
		local playerPos = player:get_pos()
		player_jetpack = minetest.env:add_entity(
			playerPos,
			"jetpackimatica:jetpacks_uv"
		)
		player_jetpack:set_attach(
			player,
			"",
			{ x=0, y=5.5, z=-3.0 },
			{ x=0, y=0, z=0 }
		)

		myMeta:set_int( 'player_jetpack_level', 3 )
	end,
	on_unequip = function( player, index, stack )
		print( "[JETPACKS] on_unequip!")
		local myMeta = player:get_meta()
		myMeta:set_int( "player_jetpack_level", 0 )
		player_jetpack:set_detach();

		minetest.after( 0.1, function()
			player_jetpack:remove()
			player_jetpack = nil;
		end)
	end,
	on_punch = function( pos, node, puncher, pointed_thing )
		print( "[JETPACKS] on_punch!")
		print( dump( getmetatable( pointed_thing ) ) )
	end
})
minetest.register_entity("jetpackimatica:jetpacks_uv", {
	initial_properties = {
		visual = "mesh",
		mesh = "jetpacks_uv.b3d",
		phyiscal = false,
		collisionbox = { -0.2, -0.3, -0.2, 0.2, 0.3, 0.2 },
		visual_size = { x=6, y=6 },
		textures = {
			"blown-up-jetpack_uvmap_wraparound.png"
		},
	},
})
default.player_register_model("jetpacks_uv.b3d", {
	animation_speed = 30,
	textures = {
		"blown-up-jetpack_uvmap_wraparound.png"
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

print("[JETPACKS] Done loading.")
