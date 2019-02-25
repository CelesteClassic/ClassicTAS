local TAS={}

TAS.states={}
TAS.state_flags={}
TAS.current_frame=0
TAS.practice_time=0

TAS.advance_frame=false
TAS.keypresses={}
TAS.keypresses[1]={}
TAS.keypress_frame=1

TAS.reproduce=false

local function get_state()
	local state={}
	local state_flags={}

	state={}
	state_flags={}
	state_flags.practice_time=TAS.practice_time
	state_flags.spawn={}
	state_flags.spawn.x=pico8.cart.spawn.x
	state_flags.spawn.y=pico8.cart.spawn.y
	state_flags.orbs=pico8.cart.orbs
	state_flags.will_restart=pico8.cart.will_restart
	state_flags.delay_restart=pico8.cart.delay_restart
	state_flags.has_penguin=pico8.cart.has_penguin
	state_flags.saved_penguin=pico8.cart.saved_penguin
	state_flags.fruits=pico8.cart.fruits
	state_flags.deaths=pico8.cart.deaths
	state_flags.max_djump=pico8.cart.max_djump
	state_flags.new_bg=pico8.cart.new_bg
	state_flags.frames=pico8.cart.frames
	state_flags.centiseconds=pico8.cart.centiseconds
	state_flags.seconds=pico8.cart.seconds
	state_flags.minutes=pico8.cart.minutes
	state_flags.deaths=pico8.cart.deaths
	state_flags.camx=pico8.cart.cam_p.x
	state_flags.camy=pico8.cart.cam_p.y
	state_flags.show_keys=pico8.cart.show_keys
	state_flags.freeze=pico8.cart.freeze
	state_flags.roomid=pico8.cart.roomid
	local chunks=pico8.cart.chunks
	local playerobj=pico8.cart.playerobj
	local summitobj=pico8.cart.summitobj
	if pico8.cart.roomid==1 then
		for y=1,#chunks do
			for x=1,#chunks[y] do
				local c=chunks[y][x]
				for i,o in pairs(c) do
					local id=o.type.id
					local s={}
					local insert=false
					
					if id=="spring" then
						s.id=id
						s.x=o.x
						s.y=o.y
						s.spr=o.spr
						s.hide_in=o.hide_in
						s.hide_for=o.hide_for
						s.delay=o.delay
						s.rem={}
						s.rem.x=o.rem.x
						s.rem.y=o.rem.y
						
						insert=true
					elseif id=="springl" then
						s.id=id
						s.x=o.x
						s.y=o.y
						s.spr=o.spr
						s.hide_in=o.hide_in
						s.hide_for=o.hide_for
						s.delay=o.delay
					
						insert=true
					elseif id=="springr" then
						s.id=id
						s.x=o.x
						s.y=o.y
						s.spr=o.spr
						s.hide_in=o.hide_in
						s.hide_for=o.hide_for
						s.delay=o.delay
					
						insert=true
					elseif id=="balloon" then
						s.id=id
						s.x=o.x
						s.y=o.y
						s.spr=o.spr
						s.offset=o.offset
						s.start=o.start
						s.timer=o.timer
						s.rem={}
						s.rem.x=o.rem.x
						s.rem.y=o.rem.y
						
						insert=true
					elseif id=="fall_floor" then
						s.id=id
						s.x=o.x
						s.y=o.y
						s.spr=o.spr
						s.delay=o.delay
						s.state=o.state
						s.collideable=o.collideable
						s.rem={}
						s.rem.x=o.rem.x
						s.rem.y=o.rem.y
						
						insert=true
					elseif id=="smoke" then
						s.id=id
						s.x=o.x
						s.y=o.y
						s.spr=o.spr
						s.spd={}
						s.spd.x=o.spd.x
						s.spd.y=o.spd.y
						s.flip={}
						s.flip.x=o.flip.x
						s.flip.y=o.flip.y
						s.rem={}
						s.rem.x=o.rem.x
						s.rem.y=o.rem.y
						
						insert=true
					elseif id=="fruit" then
						s.id=id
						s.x=o.x
						s.y=o.y
						s.spr=o.spr
						s.start=o.start
						s.off=o.off
						s.rem={}
						s.rem.x=o.rem.x
						s.rem.y=o.rem.y
						
						insert=true
					elseif id=="fly_fruit" then
						s.id=id
						s.x=o.x
						s.y=o.y
						s.spr=o.spr
						s.start=o.start
						s.fly=o.fly
						s.step=o.step
						s.sfx_delay=o.sfx_delay
						s.spdy=o.spd.y
						s.rem={}
						s.rem.x=o.rem.x
						s.rem.y=o.rem.y
					
						insert=true
					elseif id=="fake_wall" then
						s.id=id
						s.x=o.x
						s.y=o.y
						s.spr=o.spr
						s.rem={}
						s.rem.x=o.rem.x
						s.rem.y=o.rem.y
					
						insert=true
					elseif id=="shooterl" then
						s.id=id
						s.x=o.x
						s.y=o.y
						s.spr=o.spr
						s.clock=o.clock
					
						insert=true
					elseif id=="shooterr" then
						s.id=id
						s.x=o.x
						s.y=o.y
						s.spr=o.spr
						s.clock=o.clock
					
						insert=true
					elseif id=="projectile" then
						s.id=id
						s.x=o.x
						s.y=o.y
						s.spr=o.spr
						s.start=o.start
						s.vel=o.vel
						s.dir=o.dir
					
						insert=true
					elseif id=="key" then
						s.id=id
						s.x=o.x
						s.y=o.y
						s.spr=o.spr
						s.flipx=o.flip.x
						s.rem={}
						s.rem.x=o.rem.x
						s.rem.y=o.rem.y
						
						insert=true
					elseif id=="chest" then
						s.id=id
						s.x=o.x
						s.y=o.y
						s.spr=o.spr
						s.start=o.start
						s.timer=o.timer
						s.opened=o.opened
						s.rem={}
						s.rem.x=o.rem.x
						s.rem.y=o.rem.y
						
						insert=true
					elseif id=="checkpt" then
						s.id=id
						s.x=o.x
						s.y=o.y
						s.spr=o.spr
						s.active=o.active
						
						insert=true
					elseif id=="platform" then
						s.id=id
						s.x=o.x
						s.y=o.y
						s.spr=o.spr
						s.dir=o.dir
						s.rem={}
						s.rem.x=o.rem.x
						s.rem.y=o.rem.y
					
						insert=true
					elseif id=="big_chest" then
						s.id=id
						s.x=o.x
						s.y=o.y
						s.spr=o.spr
						s.state=o.state
						s.timer=o.timer
					
						insert=true
					elseif id=="orb" then
						s.id=id
						s.x=o.x
						s.y=o.y
						s.spr=o.spr
						s.spdy=o.spd.y
						s.rem={}
						s.rem.x=o.rem.x
						s.rem.y=o.rem.y
						
						insert=true
					elseif id=="babypenguin" then
						s.id=id
						s.x=o.x
						s.y=o.y
						s.spr=o.spr
						s.dir=o.dir
						s.flipx=o.flip.x
						s.state=o.state
						s.timer=o.timer
						s.rem={}
						s.rem.x=o.rem.x
						s.rem.y=o.rem.y
					
						insert=true
					elseif id=="momguin" then
						s.id=id
						s.x=o.x
						s.y=o.y
						s.spr=o.spr
						s.timer=o.timer
						s.flipx=o.flip.x
					
						insert=true
					elseif id=="penguin" then
						s.id=id
						s.x=o.x
						s.y=o.y
						s.spr=o.spr
						s.dir=o.dir
						s.flipx=o.flip.x
						s.state=o.state
						s.timer=o.timer
						s.rem={}
						s.rem.x=o.rem.x
						s.rem.y=o.rem.y
					
						insert=true
					end
					
					if insert then
						table.insert(state,s)
					end
				end
			end
		end
	else
		for i,o in pairs(summitobj) do
			local id=o.type.id
			local s={}
			local insert=false
			if id=="flag" then
				s.id=id
				s.x=o.x
				s.y=o.y
				s.spr=o.spr
				s.show=o.show
				
				insert=true
			elseif id=="babypenguin" then
				s.id=id
				s.x=o.x
				s.y=o.y
				s.spr=o.spr
				s.dir=o.dir
				s.flipx=o.flip.x
				s.state=o.state
				s.timer=o.timer
				s.rem={}
				s.rem.x=o.rem.x
				s.rem.y=o.rem.y
				
				insert=true
			elseif id=="momguin" then
				s.id=id
				s.x=o.x
				s.y=o.y
				s.spr=o.spr
				s.timer=o.timer
				s.flipx=o.flip.x
				
				insert=true
			elseif id=="penguin" then
				s.id=id
				s.x=o.x
				s.y=o.y
				s.spr=o.spr
				s.dir=o.dir
				s.flipx=o.flip.x
				s.state=o.state
				s.timer=o.timer
				s.rem={}
				s.rem.x=o.rem.x
				s.rem.y=o.rem.y
				
				insert=true
			end
			
			if insert then
				table.insert(state,s)
			end
		end
	end
	for i,o in pairs(playerobj) do
		local id=o.type.id
		local s={}
		local insert=false
		if id=="player" then
			s.id=id
			s.x=o.x
			s.y=o.y
			s.spr=o.spr
			s.flipx=o.flip.x
			s.p_jump=o.p_jump
			s.p_dash=o.p_dash
			s.grace=o.grace
			s.jbuffer=o.jbuffer
			s.djump=o.djump
			s.dash_time=o.dash_time
			s.dash_effect_time=o.dash_effect_time
			s.dash_target={}
			s.dash_target.x=o.dash_target.x
			s.dash_target.y=o.dash_target.y
			s.dash_accel={}
			s.dash_accel.x=o.dash_accel.x
			s.dash_accel.y=o.dash_accel.y
			s.spr_off=o.spr_off
			s.was_on_ground=o.was_on_ground
			s.spd={}
			s.spd.x=o.spd.x
			s.spd.y=o.spd.y
			s.rem={}
			s.rem.x=o.rem.x
			s.rem.y=o.rem.y
			
			insert=true
		elseif id=="player_spawn" then
			s.id=id
			s.x=o.x
			s.y=o.y
			s.spr=o.spr
			s.target={}
			s.target.x=o.target.x
			s.target.y=o.target.y
			s.state=o.state
			s.delay=o.delay
			s.spdy=o.spd.y
			s.rem={}
			s.rem.x=o.rem.x
			s.rem.y=o.rem.y
			
			insert=true
		end
		
		if insert then
			table.insert(state,s)
		end
	end
	
	return state, state_flags
end
TAS.get_state=get_state

local function set_state(state, state_flags)
	TAS.practice_time=state_flags.practice_time
	pico8.cart.spawn.x=state_flags.spawn.x
	pico8.cart.spawn.y=state_flags.spawn.y
	pico8.cart.orbs=state_flags.orbs
	pico8.cart.will_restart=state_flags.will_restart
	pico8.cart.delay_restart=state_flags.delay_restart
	pico8.cart.has_penguin=state_flags.has_penguin
	pico8.cart.saved_penguin=state_flags.saved_penguin
	pico8.cart.fruits=state_flags.fruits
	pico8.cart.deaths=state_flags.deaths
	pico8.cart.max_djump=state_flags.max_djump
	pico8.cart.new_bg=state_flags.new_bg
	pico8.cart.frames=state_flags.frames
	pico8.cart.centiseconds=state_flags.centiseconds
	pico8.cart.seconds=state_flags.seconds
	pico8.cart.minutes=state_flags.minutes
	pico8.cart.deaths=state_flags.deaths
	pico8.cart.cam_p={x=state_flags.camx, y=state_flags.camy}
	pico8.cart.freeze=state_flags.freeze
	pico8.cart.roomid=state_flags.roomid
	pico8.cart.chunks={}
	pico8.cart.summitobj={}
	for cy=1,4 do
		table.insert(pico8.cart.chunks,{})
		for cx=1,7 do
		  table.insert(pico8.cart.chunks[cy], {})
		end
	end
	pico8.cart.playerobj={}
	for i,o in pairs(state) do
		if o.id=="player" then
			local e=pico8.cart.init_object(pico8.cart.player,o.x,o.y)
			e.spr=o.spr
			e.flip.x=o.flipx
			e.p_jump=o.p_jump
			e.p_dash=o.p_dash
			e.grace=o.grace
			e.jbuffer=o.jbuffer
			e.djump=o.djump
			e.dash_time=o.dash_time
			e.dash_effect_time=o.dash_effect_time
			e.dash_target.x=o.dash_target.x
			e.dash_target.y=o.dash_target.y
			e.dash_accel.x=o.dash_accel.x
			e.dash_accel.y=o.dash_accel.y
			e.spr_off=o.spr_off
			e.was_on_ground=o.was_on_ground
			e.spd.x=o.spd.x
			e.spd.y=o.spd.y
			e.rem.x=o.rem.x
			e.rem.y=o.rem.y
		elseif o.id=="player_spawn" then
			local e=pico8.cart.init_object(pico8.cart.player_spawn,o.target.x,o.target.y)
			e.spr=o.spr
			e.x=o.x
			e.y=o.y
			e.state=o.state
			e.delay=o.delay
			e.spd.y=o.spdy
			e.rem.x=o.rem.x
			e.rem.y=o.rem.y
		elseif o.id=="spring" then
			local e=pico8.cart.init_object(pico8.cart.spring,o.x,o.y)
			e.spr=o.spr
			e.hide_in=o.hide_in
			e.hide_for=o.hide_for
			e.delay=o.delay
			e.rem.x=o.rem.x
			e.rem.y=o.rem.y
		elseif o.id=="springl" then
			local e=pico8.cart.init_object(pico8.cart.springl,o.x,o.y)
			e.spr=o.spr
			e.hide_in=o.hide_in
			e.hide_for=o.hide_for
			e.delay=o.delay
		elseif o.id=="springr" then
			local e=pico8.cart.init_object(pico8.cart.springr,o.x,o.y)
			e.spr=o.spr
			e.hide_in=o.hide_in
			e.hide_for=o.hide_for
			e.delay=o.delay
		elseif o.id=="balloon" then
			local e=pico8.cart.init_object(pico8.cart.balloon,o.x,o.y)
			e.spr=o.spr
			e.offset=o.offset
			e.start=o.start
			e.timer=o.timer
			e.rem.x=o.rem.x
			e.rem.y=o.rem.y
		elseif o.id=="fall_floor" then
			local e=pico8.cart.init_object(pico8.cart.fall_floor,o.x,o.y)
			e.spr=o.spr
			e.delay=o.delay
			e.state=o.state
			e.collideable=o.collideable
			e.rem.x=o.rem.x
			e.rem.y=o.rem.y
		elseif o.id=="smoke" then
			local e=pico8.cart.init_object(pico8.cart.smoke,o.x,o.y)
			e.spr=o.spr
			e.x=o.x
			e.y=o.y
			e.spd.x=o.spd.x
			e.spd.y=o.spd.y
			e.flip.x=o.flip.x
			e.flip.y=o.flip.y
			e.rem.x=o.rem.x
			e.rem.y=o.rem.y
		elseif o.id=="fruit" then
			local e=pico8.cart.init_object(pico8.cart.fruit,o.x,o.y)
			e.spr=o.spr
			e.start=o.start
			e.off=o.off
			e.rem.x=o.rem.x
			e.rem.y=o.rem.y
		elseif o.id=="fly_fruit" then
			local e=pico8.cart.init_object(pico8.cart.fly_fruit,o.x,o.y)
			e.spr=o.spr
			e.start=o.start
			e.fly=o.fly
			e.step=o.step
			e.sfx_delay=o.sfx_delay
			e.spd.y=o.spdy
			e.rem.x=o.rem.x
			e.rem.y=o.rem.y
		elseif o.id=="fake_wall" then
			local e=pico8.cart.init_object(pico8.cart.fake_wall,o.x,o.y)
			e.rem.x=o.rem.x
			e.rem.y=o.rem.y
		elseif o.id=="shooterl" then
			local e=pico8.cart.init_object(pico8.cart.shooterl,o.x,o.y)
			e.spr=o.spr
			e.clock=o.clock
		elseif o.id=="shooterr" then
			local e=pico8.cart.init_object(pico8.cart.shooterr,o.x,o.y)
			e.spr=o.spr
			e.clock=o.clock
		elseif o.id=="projectile" then
			local e=pico8.cart.init_object(pico8.cart.projectile,o.start,o.y)
			e.x=o.x
			e.spr=o.spr
			e.dir=o.dir
			e.flip.x= e.dir==-1
		elseif o.id=="key" then
			local e=pico8.cart.init_object(pico8.cart.key,o.x,o.y)
			e.spr=o.spr
			e.flip.x=o.flipx
			e.rem.x=o.rem.x
			e.rem.y=o.rem.y
		elseif o.id=="chest" then
			local e=pico8.cart.init_object(pico8.cart.chest,o.x,o.y)
			e.spr=o.spr
			e.start=o.start
			e.timer=o.timer
			e.opened=o.opened
			e.rem.x=o.rem.x
			e.rem.y=o.rem.y
		elseif o.id=="checkpt" then
			local e=pico8.cart.init_object(pico8.cart.checkpt,o.x,o.y)
			e.spr=o.spr
			e.active=o.active
		elseif o.id=="platform" then
			local e=pico8.cart.init_object(pico8.cart.platform,o.x+4,o.y)
			e.spr=o.spr
			e.dir=o.dir
			e.rem.x=o.rem.x
			e.rem.y=o.rem.y
		elseif o.id=="big_chest" then
			local e=pico8.cart.init_object(pico8.cart.big_chest,o.x,o.y)
			e.spr=o.spr
			e.state=o.state
			e.timer=o.timer
		elseif o.id=="orb" then
			local e=pico8.cart.init_object(pico8.cart.orb,o.x,o.y)
			e.spr=o.spr
			e.spd.y=o.spdy
			e.rem.x=o.rem.x
			e.rem.y=o.rem.y
		elseif o.id=="flag" then
			local e=pico8.cart.init_object(pico8.cart.flag,o.x+2,o.y)
			e.spr=o.spr
			e.show=o.show
		elseif o.id=="babypenguin" then
			local e=pico8.cart.init_object(pico8.cart.babypenguin,o.x,o.y)
			e.spr=o.spr
			e.dir=o.dir
			e.flip.x=o.flipx
			e.state=o.state
			e.timer=o.timer
			e.rem.x=o.rem.x
			e.rem.y=o.rem.y
		elseif o.id=="momguin" then
			local e=pico8.cart.init_object(pico8.cart.momguin,o.x,o.y-8)
			e.spr=o.spr
			e.timer=o.timer
			e.flip.x=o.flipx
		elseif o.id=="penguin" then
			local e=pico8.cart.init_object(pico8.cart.penguin,o.x,o.y)
			e.spr=o.spr
			e.dir=o.dir
			e.flip.x=o.flipx
			e.state=o.state
			e.timer=o.timer
			e.rem.x=o.rem.x
			e.rem.y=o.rem.y
		end
	end
	pico8.cart.show_keys=state_flags.show_keys
end
TAS.set_state=set_state

local function update()
	if TAS.advance_frame then
		TAS.advance_frame=false
		TAS.current_frame=TAS.current_frame+1
		if pico8.cart.roomid==1 then
			TAS.practice_time=TAS.practice_time+1
		end
		if pico8.cart.loaded_summit then
			TAS.practice_time=TAS.practice_time+1
			pico8.cart.loaded_summit=false
		end
		
		if pico8.cart.died then
			pico8.cart.died=false
			pico8.cart.show_keys=false
		end
		
		if pico8.cart.show_keys then
			TAS.keypress_frame=TAS.keypress_frame+1
		end
		
		if not TAS.keypresses[TAS.keypress_frame+1] then
			TAS.keypresses[TAS.keypress_frame+1]={}
		end
	end
	
	if TAS.reproduce then
		TAS.advance_frame=true
		local state, state_flag=get_state()
		TAS.states[TAS.current_frame]=state
		TAS.state_flags[TAS.current_frame]=state_flag
	end
end
TAS.update=update

local function clamp(val,low,up)
	if low>val then
		return low
	elseif up<val then
		return up
	else
		return val
	end
end

local function draw()
	pico8.cart.camera(0,0)

	pico8.cart.rectfill(1,1,33,7,0)
	local m=math.floor(TAS.practice_time/(30*60))
	local s=math.floor(TAS.practice_time/30)%60
	local cs=math.floor(100*(TAS.practice_time%30)/30)
	pico8.cart.print((m<10 and "0"..m or m)..":"..(s<10 and "0"..s or s).."."..(cs<10 and "0"..cs or cs),2,2,7)

	local inputs_x=36
	local camx=pico8.cart.cam_p.x
	local camy=pico8.cart.cam_p.y
	pico8.cart.rectfill(inputs_x,1,inputs_x+24,11,0)
	if pico8.cart.show_keys then
		pico8.cart.rectfill(inputs_x + 12, 7, inputs_x + 14, 9, TAS.keypresses[TAS.keypress_frame][0] and 7 or 1) -- l
		pico8.cart.rectfill(inputs_x + 20, 7, inputs_x + 22, 9, TAS.keypresses[TAS.keypress_frame][1] and 7 or 1) -- r
		pico8.cart.rectfill(inputs_x + 16, 3, inputs_x + 18, 5, TAS.keypresses[TAS.keypress_frame][2] and 7 or 1) -- u
		pico8.cart.rectfill(inputs_x + 16, 7, inputs_x + 18, 9, TAS.keypresses[TAS.keypress_frame][3] and 7 or 1) -- d
		pico8.cart.rectfill(inputs_x + 2, 7, inputs_x + 4, 9, TAS.keypresses[TAS.keypress_frame][4] and 7 or 1) -- z
		pico8.cart.rectfill(inputs_x + 6, 7, inputs_x + 8, 9, TAS.keypresses[TAS.keypress_frame][5] and 7 or 1) -- x
	end
	pico8.cart.camera(camx,camy)
end
TAS.draw=draw

local function save_file()
	local file=love.filesystem.newFile("adelie.tas")
	file:open("w")
	
	for _=2,#TAS.keypresses do
		local i=TAS.keypresses[_]
		local line=0
		for x=0,5 do
			if i[x] then
				if x==0 then
					line=line+1
				elseif x==1 then
					line=line+2
				elseif x==2 then
					line=line+4
				elseif x==3 then
					line=line+8
				elseif x==4 then
					line=line+16
				else
					line=line+32
				end
			end
		end
		file:write(tostring(line)..",")
	end
	
	file:close()
end

local function load_file(file)
	local data=file:read()
	local iterator=2
	for s in data:gmatch("([^,]+)") do
		TAS.keypresses[iterator]={}
		for i=0,5 do
			TAS.keypresses[iterator][i]=false
		end
		local c=tonumber(s)
		for i=0,5 do
			if math.floor(c/math.pow(2,i))%2==1 then
				TAS.keypresses[iterator][i]=true
			end
		end
		iterator=iterator+1
	end
end
TAS.load_file=load_file

local function keypress(key)
	if key=='l' then
		TAS.advance_frame=true
		local state, state_flag=get_state()
		TAS.states[TAS.current_frame]=state
		TAS.state_flags[TAS.current_frame]=state_flag
	elseif key=='k' then
		if TAS.current_frame>0 then
			TAS.current_frame=TAS.current_frame-1
			if pico8.cart.roomid==1 then
				TAS.practice_time=TAS.practice_time-1
			end
			if pico8.cart.show_keys then
				TAS.keypress_frame=TAS.keypress_frame-1
			end
			set_state(TAS.states[TAS.current_frame], TAS.state_flags[TAS.current_frame])
		end
	elseif key=='d' then
		TAS.current_frame=0
		TAS.practice_time=0
		TAS.keypress_frame=1
		_load()
	elseif key=='p' then
		TAS.reproduce=not TAS.reproduce
	elseif key=='y' then
		for _,o in pairs(pico8.cart.playerobj) do
			if o.type.id=="player" then
				log("----------------------------------")
				log("position: "..tostring(o.x)..", "..tostring(o.y))
				log("rem values: "..tostring(o.rem.x)..", "..tostring(o.rem.y))
				log("speed: "..tostring(o.spd.x)..", "..tostring(o.spd.y))
			end
		end
	elseif key=='m' then
		save_file()
	elseif key=='up' then
		if not TAS.reproduce then
			TAS.keypresses[TAS.keypress_frame][2]=not TAS.keypresses[TAS.keypress_frame][2]
		end
	elseif key=='down' then
		if not TAS.reproduce then
			TAS.keypresses[TAS.keypress_frame][3]=not TAS.keypresses[TAS.keypress_frame][3]
		end
	elseif key=='left' then
		if not TAS.reproduce then
			TAS.keypresses[TAS.keypress_frame][0]=not TAS.keypresses[TAS.keypress_frame][0]
		end
	elseif key=='right' then
		if not TAS.reproduce then
			TAS.keypresses[TAS.keypress_frame][1]=not TAS.keypresses[TAS.keypress_frame][1]
		end
	elseif key=='c' or key=='z' then
		if not TAS.reproduce then
			TAS.keypresses[TAS.keypress_frame][4]=not TAS.keypresses[TAS.keypress_frame][4]
		end
	elseif key=='x' then
		if not TAS.reproduce then
			TAS.keypresses[TAS.keypress_frame][5]=not TAS.keypresses[TAS.keypress_frame][5]
		end
	end
end
TAS.keypress=keypress

local function restart()
	TAS.states={}
	TAS.state_flags={}
	TAS.current_frame=0
	TAS.practice_time=0
	TAS.advance_frame=false
	TAS.keypresses={}
	TAS.keypresses[1]={}
	TAS.keypress_frame=1
	TAS.reproduce=false
end
TAS.restart=restart

return TAS