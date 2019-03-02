local TAS={}

TAS.practice_timing=false
TAS.practice_time=0

TAS.advance_frame=false
TAS.keypresses={}
TAS.keypresses[1]={}
TAS.states={}
TAS.states_flags={}
TAS.current_frame=0
TAS.keypress_frame=1

TAS.balloon_mode=false
TAS.balloon_selection=0
TAS.up_time=0
TAS.down_time=0

TAS.showdebug=true

TAS.balloon_seeds={}

TAS.reproduce=false
TAS.final_reproduce=false

local function get_state()
	local state={}
	local state_flag={}
	
	state_flag.state_practice_time=TAS.practice_time
	state_flag.got_fruit=pico8.cart.got_fruit[pico8.cart.level_index()+1]
	state_flag.has_dashed=pico8.cart.has_dashed
	state_flag.frames=pico8.cart.frames
	state_flag.seconds=pico8.cart.seconds
	state_flag.minutes=pico8.cart.minutes
	state_flag.has_key=pico8.cart.has_key
	state_flag.new_bg=pico8.cart.new_bg
	state_flag.flash_bg=pico8.cart.flash_bg
	state_flag.pause_player=pico8.cart.pause_player
	state_flag.max_djump=pico8.cart.max_djump
	state_flag.practice_timing=TAS.practice_timing
	state_flag.will_restart=pico8.cart.will_restart
	state_flag.delay_restart=pico8.cart.delay_restart
	state_flag.start=pico8.cart.start
	state_flag.practice_timing=TAS.practice_timing
	state_flag.show_keys=pico8.cart.show_keys
	state_flag.freeze=pico8.cart.freeze
	local objects=pico8.cart.objects
	for i,o in pairs(objects) do
		local id = o.type.id
		local s = {}
		local insert = false
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
		elseif id=="spring" then
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
		elseif id=="balloon" then
			s.id=id
			s.x=o.x
			s.y=o.y
			s.spr=o.spr
			s.offset=o.offset
			s.initial_offset=o.initial_offset
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
			s.offset=o.offset
			s.timer=o.timer
			s.rem={}
			s.rem.x=o.rem.x
			s.rem.y=o.rem.y
			
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
		elseif id=="flag" then
			s.id=id
			s.x=o.x
			s.y=o.y
			s.spr=o.spr
			s.score=o.score
			s.show=o.show
			
			insert=true
		end
		
		if insert then
			table.insert(state,s)
		end
	end
	
	return state, state_flag
end
TAS.get_state=get_state

local function set_state(state, state_flag)
	pico8.cart.got_fruit[pico8.cart.level_index()+1]=state_flag.got_fruit
	pico8.cart.has_dashed=state_flag.has_dashed
	pico8.cart.frames=state_flag.frames
	pico8.cart.seconds=state_flag.seconds
	pico8.cart.minutes=state_flag.minutes
	pico8.cart.has_key=state_flag.has_key
	pico8.cart.new_bg=state_flag.new_bg
	pico8.cart.flash_bg=state_flag.flash_bg
	pico8.cart.pause_player=state_flag.pause_player
	pico8.cart.max_djump=state_flag.max_djump
	pico8.cart.will_restart=state_flag.will_restart
	pico8.cart.delay_restart=state_flag.delay_restart
	TAS.practice_timing=state_flag.practice_timing
	pico8.cart.show_keys=state_flag.show_keys
	pico8.cart.freeze=state_flag.freeze
	pico8.cart.objects={}
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
		elseif o.id=="balloon" then
			local e=pico8.cart.init_object(pico8.cart.balloon,o.x,o.y)
			e.spr=o.spr
			e.offset=o.offset
			e.initial_offset=o.initial_offset
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
		elseif o.id=="key" then
			local e=pico8.cart.init_object(pico8.cart.key,o.x,o.y)
			e.spr=o.spr
			e.flip.x=o.flipx
			e.rem.x=o.rem.x
			e.rem.y=o.rem.y
		elseif o.id=="chest" then
			local e=pico8.cart.init_object(pico8.cart.chest,o.x+4,o.y)
			e.spr=o.spr
			e.start=o.start
			e.offset=o.offset
			e.timer=o.timer
			e.rem.x=o.rem.x
			e.rem.y=o.rem.y
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
			local e=pico8.cart.init_object(pico8.cart.flag,o.x-5,o.y)
			e.spr=o.spr
			e.score=o.score
			e.show=o.show
		end
	end
	pico8.cart.start=state_flag.start
end
TAS.set_state=set_state

local function update_balloon(initial_offset, iterator)
	TAS.balloon_seeds[iterator]=initial_offset
	for i=0,#TAS.states do
		local _iterator=0
		for _,o in pairs(TAS.states[i]) do
			if o.id=="balloon" then
				if _iterator==iterator then
					o.offset=o.offset - (o.initial_offset - initial_offset)
					o.initial_offset=initial_offset
					o.y=o.start+math.sin(-o.offset*2*math.pi)*2
				end
				_iterator=_iterator+1
			elseif o.id=="chest" then
				if _iterator==iterator then
					o.offset=initial_offset
				end
				_iterator=_iterator+1
			end
		end
	end
end

local function update()
	if TAS.balloon_mode then
		local iterator=0
		for _,o in pairs(pico8.cart.objects) do
			if o.type.id=="balloon" then
				if iterator==TAS.balloon_selection then
					if love.keyboard.isDown("up") then
						TAS.up_time=TAS.up_time+1
						local delta=0.0001*TAS.up_time/2
						update_balloon((o.initial_offset+delta)%1,iterator)
						o.initial_offset=(o.initial_offset+delta)%1
						o.offset=(o.offset+delta)%1
						o.y=o.start+math.sin(-o.offset*2*math.pi)*2
					else
						if love.keyboard.isDown("down") then
							TAS.down_time=TAS.down_time+1
							local delta=0.0001*TAS.down_time/2
							update_balloon((o.initial_offset-delta)%1,iterator)
							o.initial_offset=(o.initial_offset-delta)%1
							o.offset=(o.offset-delta)%1
							o.y=o.start+math.sin(-o.offset*2*math.pi)*2
						else
							TAS.down_time=0
						end
						TAS.up_time=0
					end
				end
				iterator=iterator+1
			elseif o.type.id=="chest" then
				if iterator==TAS.balloon_selection then
					if love.keyboard.isDown("up") then
						if TAS.up_time==0 then
							TAS.up_time=1
							o.offset=o.offset+1
							if o.offset==2 then
								o.offset=-1
							end
							update_balloon(o.offset,iterator)
						end
					else
						if love.keyboard.isDown("down") then
							if TAS.down_time==0 then
								TAS.down_time=1
								o.offset=o.offset-1
								if o.offset==-2 then
									o.offset=1
								end
								update_balloon(o.offset,iterator)
							end
						else
							TAS.down_time=0
						end
						TAS.up_time=0
					end
				end
				iterator=iterator+1
			end
		end
	end

	if TAS.advance_frame then
		TAS.advance_frame=false
		
		pico8.cart.update=true
		
		if pico8.cart.start then
			pico8.cart.start=false
			TAS.current_frame=0
			TAS.practice_time=0
			TAS.keypress_frame=1
		end
		
		TAS.current_frame=TAS.current_frame+1
		
		if pico8.cart.died then
			pico8.cart.died=false
			pico8.cart.show_keys=false
		end
		
		if pico8.cart.show_keys then
			TAS.keypress_frame=TAS.keypress_frame+1
		end
		
		if pico8.cart.beat_level then
			if not TAS.final_reproduce then
				if pico8.cart.level_index()<=21 then
					pico8.cart.max_djump=1
					pico8.cart.new_bg=nil
				end
				
				pico8.cart.beat_level=false
				TAS.practice_timing=false
				pico8.cart.got_fruit[1+pico8.cart.level_index()]=false
				pico8.cart.load_room(pico8.cart.room.x,pico8.cart.room.y)
				pico8.cart.show_keys=false
				TAS.keypress_frame=1
				TAS.current_frame=0
				local iterator2=0
				for _,o in pairs(pico8.cart.objects) do
					if o.type.id=="balloon" then
						o.initial_offset=TAS.balloon_seeds[iterator2]
						o.offset=o.initial_offset
						iterator2=iterator2+1
					end
				end
			else
				pico8.cart.beat_level=false
				pico8.cart.next_room()
				TAS.load_file(love.filesystem.newFile("TAS/TAS"..tostring(pico8.cart.level_index()+1)..".tas"))
				TAS.reproduce=true
				if pico8.cart.level_index()==30 then
					log(tostring(pico8.cart.minutes<10 and "0"..pico8.cart.minutes or pico8.cart.minutes)..":"..tostring(pico8.cart.seconds<10 and "0"..pico8.cart.seconds or pico8.cart.seconds)..tostring(pico8.cart.frames/30):sub(2))
					TAS.final_reproduce=false
					TAS.showdebug=true
					pico8.cart.show_time=false
				end
			end
		end
		
		if not TAS.keypresses[TAS.keypress_frame+1] then
			TAS.keypresses[TAS.keypress_frame+1]={}
		end
		
		if pico8.cart.start_practice_time then
			if not TAS.practice_timing then
				TAS.practice_timing=true
				TAS.practice_time=0
			end
		else
			TAS.practice_timing=false
		end
		
		if TAS.practice_timing then
			TAS.practice_time=TAS.practice_time+1
		end
	else
		pico8.cart.update=false
	end
	
	if TAS.reproduce then
		TAS.advance_frame=true
		local state, state_flag=get_state()
		TAS.states[TAS.current_frame]=state
		TAS.states_flags[TAS.current_frame]=state_flag
	end
end
TAS.update=update

local function draw()
	if TAS.balloon_mode then
		local iterator=0
		for _,o in pairs(pico8.cart.objects) do
			if o.type.id=="balloon" then
				if iterator==TAS.balloon_selection then
					love.graphics.setColor(1,0,1)
					love.graphics.rectangle("line",o.x,o.y-1,9,9)
					local offset=tostring(math.floor(o.initial_offset*10000))
					if #offset==1 then
						offset="000"..offset
					elseif #offset==2 then
						offset="00"..offset
					elseif #offset==3 then
						offset="0"..offset
					end
					pico8.cart.print(offset,o.x+5-#offset*2,o.y+10,9)
				end
				iterator=iterator+1
			elseif o.type.id=="chest" then
				if iterator==TAS.balloon_selection then
					love.graphics.setColor(1,0,1)
					love.graphics.rectangle("line",o.x,o.y-1,9,9)
					pico8.cart.print(o.offset,o.x+3,o.y+10,9)
				end
				iterator=iterator+1
			end
		end
	end

	if TAS.showdebug and pico8.cart.level_index()<30 then
		pico8.cart.rectfill(1,1,13,7,0)
		pico8.cart.print(tostring(TAS.practice_time),2,2,7)
		
		local inputs_x=15
		pico8.cart.rectfill(inputs_x,1,inputs_x+24,11,0)
		if pico8.cart.show_keys then
			pico8.cart.rectfill(inputs_x + 12, 7, inputs_x + 14, 9, TAS.keypresses[TAS.keypress_frame][0] and 7 or 1) -- l
			pico8.cart.rectfill(inputs_x + 20, 7, inputs_x + 22, 9, TAS.keypresses[TAS.keypress_frame][1] and 7 or 1) -- r
			pico8.cart.rectfill(inputs_x + 16, 3, inputs_x + 18, 5, TAS.keypresses[TAS.keypress_frame][2] and 7 or 1) -- u
			pico8.cart.rectfill(inputs_x + 16, 7, inputs_x + 18, 9, TAS.keypresses[TAS.keypress_frame][3] and 7 or 1) -- d
			pico8.cart.rectfill(inputs_x + 2, 7, inputs_x + 4, 9, TAS.keypresses[TAS.keypress_frame][4] and 7 or 1) -- z
			pico8.cart.rectfill(inputs_x + 6, 7, inputs_x + 8, 9, TAS.keypresses[TAS.keypress_frame][5] and 7 or 1) -- x
		end
	end
end
TAS.draw=draw

local function save_file()
	local file=love.filesystem.newFile("TAS"..tostring(pico8.cart.level_index()+1)..".tas")
	file:open("w")
	
	file:write("[")
	for _,o in pairs(TAS.balloon_seeds) do
		file:write(tostring(o)..",")
	end
	file:write("]")
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
TAS.save_file=save_file

local function load_file(file)
	TAS.keypresses={}
	local data=file:read()
	local iterator=2
	local h=0
	for x in data:gmatch("([^]]+)") do
		if h==0 then
			local i=0
			for s in x:sub(2):gmatch("([^,]+)") do
				TAS.balloon_seeds[i]=tostring(s)
				i=i+1
			end
			h=1
		else
			for s in x:gmatch("([^,]+)") do
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
	end
	
	TAS.reproduce=false
	TAS.practice_timing=false
	pico8.cart.got_fruit[1+pico8.cart.level_index()]=false
	pico8.cart.load_room(pico8.cart.room.x,pico8.cart.room.y)
	pico8.cart.show_keys=false
	TAS.current_frame=0
	TAS.keypress_frame=1
	TAS.states={}
	TAS.states_flags={}
	local iterator2=0
	for _,o in pairs(pico8.cart.objects) do
		if o.type.id=="balloon" then
			o.initial_offset=TAS.balloon_seeds[iterator2]
			o.offset=o.initial_offset
			iterator2=iterator2+1
		elseif o.type.id=="chest" then
			o.offset=TAS.balloon_seeds[iterator2]
			iterator2=iterator2+1
		end
	end
end
TAS.load_file=load_file

local function ready_level()
	TAS.states={}
	TAS.state_flags={}
	TAS.keypresses={}
	TAS.keypresses[1]={}
	TAS.current_frame=0
	TAS.practice_timing=false
	TAS.practice_time=0
	pico8.cart.show_keys=false
	TAS.balloon_mode=false
	TAS.balloon_selection=0
	TAS.balloon_seeds={}
	pico8.cart.freeze=0
end

local function keypress(key)
	if key=='p' then
		TAS.reproduce=not TAS.reproduce
	elseif key=='e' then
		if not TAS.final_reproduce then
			TAS.showdebug=not TAS.showdebug
		end
	elseif key=='b' then
		if not TAS.final_reproduce then
			if TAS.current_frame>0 then
				TAS.balloon_mode=not TAS.balloon_mode
			end
		end
	elseif key=='n' then
		TAS.final_reproduce=not TAS.final_reproduce
		if TAS.final_reproduce then
			ready_level()
			pico8.cart.load_room(0,0)
			TAS.load_file(love.filesystem.newFile("TAS/TAS1.tas"))
			pico8.cart.max_djump=1
			pico8.cart.new_bg=nil
			pico8.cart.music(0,0,7)
		end
		TAS.reproduce=TAS.final_reproduce
		TAS.showdebug=not TAS.final_reproduce
		TAS.balloon_mode=false
		pico8.cart.show_time=TAS.final_reproduce
		pico8.cart.frames=0
		pico8.cart.seconds=0
		pico8.cart.minutes=0
	elseif key=='y' then
		for _,o in pairs(pico8.cart.objects) do
			if o.type.id=="player" then
				log("----------------------------------")
				log("position: "..tostring(o.x)..", "..tostring(o.y))
				log("rem values: "..tostring(o.rem.x)..", "..tostring(o.rem.y))
				log("speed: "..tostring(o.spd.x)..", "..tostring(o.spd.y))
			end
		end
	elseif key=='f' then
		if not TAS.final_reproduce then
			if not pico8.cart.pause_player then
				ready_level()
				if pico8.cart.level_index()<29 then
					pico8.cart.got_fruit[2+pico8.cart.level_index()]=false
					pico8.cart.next_room()
					TAS.practice_time=0
					pico8.cart.start_practice_time=false
					if pico8.cart.level_index()>21 then
						pico8.cart.max_djump=2
						pico8.cart.new_bg=true
					end
					local i=0
					for _,o in pairs(pico8.cart.objects) do
						if o.type.id=="balloon" then
							TAS.balloon_seeds[i]=0
							o.initial_offset=0
							o.offset=0
							i=i+1
						elseif o.type.id=="chest" then
							TAS.balloon_seeds[i]=0
							o.offset=0
							i=i+1
						end
					end
				else
					pico8.cart.got_fruit[1+pico8.cart.level_index()]=false
					pico8.cart.load_room(pico8.cart.room.x,pico8.cart.room.y)
					pico8.cart.start_practice_time=false
					local i=0
					for _,o in pairs(pico8.cart.objects) do
						if o.type.id=="balloon" then
							TAS.balloon_seeds[i]=0
							o.initial_offset=0
							o.offset=0
							i=i+1
						elseif o.type.id=="chest" then
							TAS.balloon_seeds[i]=0
							o.offset=0
							i=i+1
						end
					end
				end
			end
		end
	elseif key=='s' then
		if not TAS.final_reproduce then
			if not pico8.cart.pause_player then
				ready_level()
				if pico8.cart.level_index()>0 then
					if pico8.cart.room.x==0 then
						pico8.cart.room.x=7
						pico8.cart.room.y=pico8.cart.room.y-1
					else
						pico8.cart.room.x=pico8.cart.room.x-1
					end
					pico8.cart.got_fruit[1+pico8.cart.level_index()]=false
					pico8.cart.load_room(pico8.cart.room.x,pico8.cart.room.y)
					if pico8.cart.level_index()<=21 then
						pico8.cart.max_djump=1
						pico8.cart.new_bg=nil
					end
					local i=0
					for _,o in pairs(pico8.cart.objects) do
						if o.type.id=="balloon" then
							TAS.balloon_seeds[i]=0
							o.initial_offset=0
							o.offset=0
							i=i+1
						end
					end
				else
					pico8.cart.got_fruit[1+pico8.cart.level_index()]=false
					pico8.cart.load_room(pico8.cart.room.x,pico8.cart.room.y)
					pico8.cart.start_practice_time=false
					local i=0
					for _,o in pairs(pico8.cart.objects) do
						if o.type.id=="balloon" then
							TAS.balloon_seeds[i]=0
							o.initial_offset=0
							o.offset=0
							i=i+1
						end
					end
				end
			end
		end
	elseif key=='d' then
		if not TAS.final_reproduce then
			TAS.reproduce=false
			TAS.practice_timing=false
			pico8.cart.got_fruit[1+pico8.cart.level_index()]=false
			pico8.cart.load_room(pico8.cart.room.x,pico8.cart.room.y)
			pico8.cart.show_keys=false
			pico8.cart.will_restart=false
			TAS.current_frame=0
			TAS.keypress_frame=1
			TAS.states={}
			TAS.states_flags={}
			local iterator2=0
			for _,o in pairs(pico8.cart.objects) do
				if o.type.id=="balloon" then
					o.initial_offset=TAS.balloon_seeds[iterator2]
					o.offset=o.initial_offset
					iterator2=iterator2+1
				elseif o.type.id=="chest" then
					o.offset=TAS.balloon_seeds[iterator2]
					iterator2=iterator2+1
				end
			end
		end
	elseif key=='r' then
		if not TAS.final_reproduce then
			ready_level()
			pico8.cart.got_fruit[1+pico8.cart.level_index()]=false
			pico8.cart.load_room(pico8.cart.room.x,pico8.cart.room.y)
			TAS.keypress_frame=1
		end
	elseif key=='l' then
		if not TAS.final_reproduce then
			TAS.advance_frame=true
			local state, state_flag=get_state()
			TAS.states[TAS.current_frame]=state
			TAS.states_flags[TAS.current_frame]=state_flag
		end
	elseif key=='k' then
		if not TAS.final_reproduce then
			if TAS.current_frame>0 then
				TAS.current_frame=TAS.current_frame-1
				if pico8.cart.show_keys then
					TAS.keypress_frame=TAS.keypress_frame-1
				end
				set_state(TAS.states[TAS.current_frame], TAS.states_flags[TAS.current_frame])
				TAS.practice_time=math.max(TAS.practice_time-1,0)
			end
		end
	elseif key=='up' then
		if not TAS.reproduce then
			if not TAS.balloon_mode then
				TAS.keypresses[TAS.keypress_frame][2]=not TAS.keypresses[TAS.keypress_frame][2]
			end
		end
	elseif key=='down' then
		if not TAS.reproduce then
			if not TAS.balloon_mode then
				TAS.keypresses[TAS.keypress_frame][3]=not TAS.keypresses[TAS.keypress_frame][3]
			end
		end
	elseif key=='left' then
		if not TAS.reproduce then
			if TAS.balloon_mode then
				TAS.balloon_selection=TAS.balloon_selection-1
				if TAS.balloon_selection==-1 then
					TAS.balloon_selection=pico8.cart.balloon_count-1
				end
			else
				TAS.keypresses[TAS.keypress_frame][0]=not TAS.keypresses[TAS.keypress_frame][0]
			end
		end
	elseif key=='right' then
		if not TAS.reproduce then
			if TAS.balloon_mode then
				TAS.balloon_selection=TAS.balloon_selection+1
				if TAS.balloon_selection==pico8.cart.balloon_count then
					TAS.balloon_selection=0
				end
			else
				TAS.keypresses[TAS.keypress_frame][1]=not TAS.keypresses[TAS.keypress_frame][1]
			end
		end
	elseif key=='c' or key=='z' then
		if not TAS.reproduce then
			TAS.keypresses[TAS.keypress_frame][4]=not TAS.keypresses[TAS.keypress_frame][4]
		end
	elseif key=='x' then
		if not TAS.reproduce then
			TAS.keypresses[TAS.keypress_frame][5]=not TAS.keypresses[TAS.keypress_frame][5]
		end
	elseif key=='m' then
		TAS.save_file()
	end
end
TAS.keypress=keypress

local function restart()
	TAS.practice_timing=false
	TAS.practice_time=0
	TAS.advance_frame=false
	TAS.keypresses={}
	TAS.keypresses[1]={}
	TAS.states={}
	TAS.states_flags={}
	TAS.current_frame=0
	TAS.keypress_frame=1
	TAS.balloon_mode=false
	TAS.balloon_selection=0
	TAS.up_time=0
	TAS.down_time=0
	TAS.showdebug=true
	TAS.balloon_seeds={}
	TAS.reproduce=false
	TAS.final_reproduce=false
end
TAS.restart=restart

return TAS