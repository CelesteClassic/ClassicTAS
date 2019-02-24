pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
-- matt thorson + noel berry
-- mod by kris de asis

-- globals --
-------------

roomid = 0
map_w = 7
map_h = 4
cam_p = {x=45*8+4, y=61*8+64}
cam_v = {x=0, y=0}
cam_g = 0.25
playerobj = {}
spawn = {x=45*8, y=61*8}
chunks = {}
summitobj = {}
types = {}
freeze=0
will_restart=false
delay_restart=0
has_dashed=false
sfx_timer=0
pause_player=false
flash_bg=false
music_timer=0
has_penguin=false
saved_penguin=false

k_left=0
k_right=1
k_up=2
k_down=3
k_jump=4
k_dash=5

show_keys=false
died=false
loaded_summit=false

-- entry point --
-----------------

function _init()
  for cy=1,map_h do
    add(chunks,{})
    for cx=1,map_w do
      add(chunks[cy], {})
    end
  end
  load_room()
  title_screen()
end

function title_screen()
  frames=0
  deaths=0
  max_djump=1
  orbs=0
  fruits=0
  start_game=false
  start_game_flash=0
  music(40,0,7)

  roomid=0

  begin_game()
  
  for tx=0,15 do
    for ty=0,15 do
      local tile = mget(7*16+tx,3*16+ty)
      foreach(types, 
      function(type) 
        if type.tile == tile then
          init_object(type,tx*8,ty*8) 
        end
      end)
    end
  end
end

function begin_game()
  frames=0
  centiseconds=0
  seconds=0
  minutes=0
  music_timer=0
  start_game=false
  music(0,0,7)

  has_dashed=false

  roomid=1
  load_room()
  --roomid=2
  --load_summit()
end

function is_title()
  return roomid==0
end

function is_summit()
  return roomid==2
end

-- effects --
-------------

clouds = {}
for i=0,16 do
  add(clouds,{
    x=rnd(128),
    y=rnd(128),
    spd=1+rnd(4),
    w=32+rnd(32)
  })
end

particles = {}
for i=0,24 do
  add(particles,{
    x=rnd(128),
    y=rnd(128),
    s=0+flr(rnd(5)/4),
    spd=0.25+rnd(5),
    off=rnd(1),
    c=6+flr(0.5+rnd(1))
  })
end

dead_particles = {}

-- player entity --
-------------------

player = 
{
  id="player",
  init=function(this) 
    this.p_jump=false
    this.p_dash=false
    this.grace=0
    this.jbuffer=0
    this.djump=max_djump
    this.dash_time=0
    this.dash_effect_time=0
    this.dash_target={x=0,y=0}
    this.dash_accel={x=0,y=0}
    this.hitbox = {x=1,y=3,w=6,h=5}
    this.spr_off=0
    this.was_on_ground=false
    create_hair(this)
  end,
  update=function(this)
    if (pause_player) return
    
    local input = btn(k_right) and 1 or (btn(k_left) and -1 or 0)
    
    -- spikes collide
    if spikes_at(this.x+this.hitbox.x,this.y+this.hitbox.y,this.hitbox.w,this.hitbox.h,this.spd.x,this.spd.y) then
      kill_player(this)
	end
     
    -- bottom death
    if this.y>map_h*16*8 then
      kill_player(this) end

    local on_ground=this.is_solid(0,1)
    local on_ice=this.is_ice(0,1)
    
    -- smoke particles
    if on_ground and not this.was_on_ground then
     init_object(smoke,this.x,this.y+4)
    end

    local jump = btn(k_jump) and not this.p_jump
    this.p_jump = btn(k_jump)
    if (jump) then
      this.jbuffer=4
    elseif this.jbuffer>0 then
     this.jbuffer-=1
    end
    
    local dash = btn(k_dash) and not this.p_dash
    this.p_dash = btn(k_dash)
    
    if on_ground then
      this.grace=6
      if this.djump<max_djump then
       psfx(54)
       this.djump=max_djump
      end
    elseif this.grace > 0 then
     this.grace-=1
    end

    this.dash_effect_time -=1
    if this.dash_time > 0 then
      init_object(smoke,this.x,this.y)
      this.dash_time-=1
      this.spd.x=appr(this.spd.x,this.dash_target.x,this.dash_accel.x)
      this.spd.y=appr(this.spd.y,this.dash_target.y,this.dash_accel.y)  
    else

      -- move
      local maxrun=1
      local accel=0.6
      local deccel=0.15
      
      if not on_ground then
        accel=0.4
      elseif on_ice then
        accel=0.05
        if input==(this.flip.x and -1 or 1) then
          accel=0.05
        end
      end
    
      if abs(this.spd.x) > maxrun then
      this.spd.x=appr(this.spd.x,sign(this.spd.x)*maxrun,deccel)
      else
        this.spd.x=appr(this.spd.x,input*maxrun,accel)
      end
      
      --facing
      if this.spd.x!=0 then
        this.flip.x=(this.spd.x<0)
      end

      -- gravity
      local maxfall=2
      local gravity=0.21

    if abs(this.spd.y) <= 0.15 then
    gravity*=0.5
      end
    
      -- wall slide
      if input!=0 and this.is_solid(input,0) and not this.is_ice(input,0) then
      maxfall=0.4
      if rnd(10)<2 then
        init_object(smoke,this.x+input*6,this.y)
        end
      end

      if not on_ground then
        this.spd.y=appr(this.spd.y,maxfall,gravity)
      end

      -- jump
      if this.jbuffer>0 then
      if this.grace>0 then
        -- normal jump
        psfx(1)
        this.jbuffer=0
        this.grace=0
          this.spd.y=-2
          init_object(smoke,this.x,this.y+4)
        else
          -- wall jump
          local wall_dir=(this.is_solid(-3,0) and -1 or this.is_solid(3,0) and 1 or 0)
          if wall_dir!=0 then
          psfx(2)
          this.jbuffer=0
          this.spd.y=-2
          this.spd.x=-wall_dir*(maxrun+1)
          if not this.is_ice(wall_dir*3,0) then
            init_object(smoke,this.x+wall_dir*6,this.y)
            end
          end
        end
      end
    
      -- dash
      local d_full=5
      local d_half=d_full*0.70710678118
    
      if this.djump>0 and dash then
      init_object(smoke,this.x,this.y)
      this.djump-=1   
      this.dash_time=4
      has_dashed=true
      this.dash_effect_time=10
      local v_input=(btn(k_up) and -1 or (btn(k_down) and 1 or 0))
      if input!=0 then
        if v_input!=0 then
        this.spd.x=input*d_half
        this.spd.y=v_input*d_half
        else
        this.spd.x=input*d_full
        this.spd.y=0
        end
      elseif v_input!=0 then
        this.spd.x=0
        this.spd.y=v_input*d_full
      else
        this.spd.x=(this.flip.x and -1 or 1)
        this.spd.y=0
      end
      
      psfx(3)
      freeze=2
      shake=6
      this.dash_target.x=2*sign(this.spd.x)
      this.dash_target.y=2*sign(this.spd.y)
      this.dash_accel.x=1.5
      this.dash_accel.y=1.5
      
      if this.spd.y<0 then
       this.dash_target.y*=.75
      end
      
      if this.spd.y!=0 then
       this.dash_accel.x*=0.70710678118
      end
      if this.spd.x!=0 then
       this.dash_accel.y*=0.70710678118
      end    
      elseif dash and this.djump<=0 then
       psfx(9)
       init_object(smoke,this.x,this.y)
      end
    end
    
    -- animation
    this.spr_off+=0.25
    if not on_ground then
      if this.is_solid(input,0) then
        this.spr=5
      else
        this.spr=3
      end
    elseif btn(k_down) then
      this.spr=6
    elseif btn(k_up) then
      this.spr=7
    elseif (this.spd.x==0) or (not btn(k_left) and not btn(k_right)) then
      this.spr=1
    else
      this.spr=1+this.spr_off%4
    end
    
    -- next level
    if this.y<-4 and roomid==1 then
      roomid=2
	  loaded_summit=true
      load_summit()
      destroy_object(this)
    end
    
    -- was on the ground
    this.was_on_ground=on_ground
    
  end, --<end update loop
  
  draw=function(this)
    -- clamp in screen
    if is_summit() then
      if this.x<-1 or this.x>121 then 
        this.x=clamp(this.x,-1,121)
        this.spd.x=0
      end
    else
      if this.x<-1 or this.x>map_w*16*8-7 then 
        this.x=clamp(this.x,-1,map_w*16*8-7)
        this.spd.x=0
      end
    end
    
    set_hair_color(this.djump)
    draw_hair(this,this.flip.x and -1 or 1)
    spr(this.spr,this.x,this.y,1,1,this.flip.x,this.flip.y)   
    unset_hair_color()
  end
}

psfx=function(num)
 if sfx_timer<=0 then
  sfx(num)
 end
end

create_hair=function(obj)
  obj.hair={}
  for i=0,4 do
    add(obj.hair,{x=obj.x,y=obj.y,size=max(1,min(2,3-i))})
  end
end

set_hair_color=function(djump)
  pal(8,(djump==1 and 8 or djump==2 and (7+flr((frames/3)%2)*4) or 12))
end

draw_hair=function(obj,facing)
  local last={x=obj.x+4-facing*2,y=obj.y+(btn(k_down) and 4 or 3)}
  foreach(obj.hair,function(h)
    h.x+=(last.x-h.x)/1.5
    h.y+=(last.y+0.5-h.y)/1.5
    circfill(h.x,h.y,h.size,8)
    last=h
  end)
end

unset_hair_color=function()
  pal(8,8)
end

player_spawn = {
  id="player_spawn",
  tile=1,
  init=function(this)
   sfx(4)
    this.spr=3
    this.target= {x=this.x,y=this.y}
    this.y=this.y+64
    this.spd.y=-4
    this.state=0
    this.delay=0
    this.solids=false
	show_keys=false
    create_hair(this)
  end,
  update=function(this)
    -- jumping up
    if this.state==0 then
      if this.y < this.target.y+16 then
        this.state=1
        this.delay=3
      end
    -- falling
    elseif this.state==1 then
      this.spd.y+=0.5
      if this.spd.y>0 and this.delay>0 then
        this.spd.y=0
        this.delay-=1
      end
      if this.spd.y>0 and this.y > this.target.y then
        this.y=this.target.y
        this.spd = {x=0,y=0}
        this.state=2
        this.delay=5
        shake=5
        init_object(smoke,this.x,this.y+4)
        sfx(5)
      end
    -- landing
    elseif this.state==2 then
      this.delay-=1
      this.spr=6
      if this.delay==0 then
		show_keys=true
	  elseif this.delay<0 then
		destroy_object(this)
		init_object(player,this.x,this.y)
	  end
    end
  end,
  draw=function(this)
    set_hair_color(max_djump)
    draw_hair(this,1)
    spr(this.spr,this.x,this.y,1,1,this.flip.x,this.flip.y)
    unset_hair_color()
    if not is_summit() then
      --draw_time(flr(clamp(cam_p.x,64,128*map_w-64)+0.5)-60,flr(clamp(cam_p.y,64,128*map_h-64)+0.5)-60)
    end
  end
}
add(types,player_spawn)

spring = {
  id="spring",
  tile=18,
  init=function(this)
    this.hide_in=0
    this.hide_for=0
  end,
  update=function(this)
    if this.hide_for>0 then
      this.hide_for-=1
      if this.hide_for<=0 then
        this.spr=18
        this.delay=0
      end
    elseif this.spr==18 then
      local hit = this.collide(player,0,0)
      if hit ~=nil and hit.spd.y>=0 then
        this.spr=19
        hit.y=this.y-4
        hit.spd.x*=0.2
        hit.spd.y=-3
        hit.djump=max_djump
        this.delay=10
        init_object(smoke,this.x,this.y)
        -- breakable below us
        local below=this.collide(fall_floor,0,1)
        if below~=nil then
          break_fall_floor(below)
        end
        psfx(8)
      end
    elseif this.delay>0 then
      this.delay-=1
      if this.delay<=0 then 
        this.spr=18 
      end
    end
    -- begin hiding
    if this.hide_in>0 then
      this.hide_in-=1
      if this.hide_in<=0 then
        this.hide_for=60
        this.spr=0
      end
    end
  end
}
add(types,spring)

springl = {
  id="springl",
  tile=45,
  init=function(this)
    this.hide_in=0
    this.hide_for=0
  end,
  update=function(this)
    if this.hide_for>0 then
      this.hide_for-=1
      if this.hide_for<=0 then
        this.spr=45
        this.delay=0
      end
    elseif this.spr==45 then
      local hit = this.collide(player,0,0)
      if hit ~=nil and hit.spd.x<=0 then
        this.spr=46
        hit.x=this.x+4
        hit.spd.x=3
        hit.spd.y=-1
        hit.djump=max_djump
        hit.dash_time=0
        hit.dash_effect_time=0
        this.delay=10
        init_object(smoke,this.x,this.y)
        local left=this.collide(fall_floor,-1,0)
        if left~=nil then
          break_fall_floor(left)
        end
        psfx(8)
      end
    elseif this.delay>0 then
      this.delay-=1
      if this.delay<=0 then 
        this.spr=45
      end
    end
    -- begin hiding
    if this.hide_in>0 then
      this.hide_in-=1
      if this.hide_in<=0 then
        this.hide_for=60
        this.spr=0
      end
    end
  end
}
add(types,springl)

springr = {
  id="springr",
  tile=28,
  init=function(this)
    this.hide_in=0
    this.hide_for=0
  end,
  update=function(this)
    if this.hide_for>0 then
      this.hide_for-=1
      if this.hide_for<=0 then
        this.spr=28
        this.delay=0
      end
    elseif this.spr==28 then
      local hit = this.collide(player,0,0)
      if hit ~=nil and hit.spd.x>=0 then
        this.spr=47
        hit.x=this.x-4
        hit.spd.x=-3
        hit.spd.y=-1
        hit.djump=max_djump
        hit.dash_time=0
        hit.dash_effect_time=0
        this.delay=10
        init_object(smoke,this.x,this.y)
        local right=this.collide(fall_floor,1,0)
        if right~=nil then
          break_fall_floor(right)
        end
        psfx(8)
      end
    elseif this.delay>0 then
      this.delay-=1
      if this.delay<=0 then 
        this.spr=28
      end
    end
    -- begin hiding
    if this.hide_in>0 then
      this.hide_in-=1
      if this.hide_in<=0 then
        this.hide_for=60
        this.spr=0
      end
    end
  end
}
add(types,springr)

function break_spring(obj)
  obj.hide_in=15
end

balloon = {
  id="balloon",
  tile=22,
  init=function(this) 
    this.offset=rnd(1)
    this.start=this.y
    this.timer=0
    this.hitbox={x=-1,y=-1,w=10,h=10}
  end,
  update=function(this) 
    if this.spr==22 then
      this.offset+=0.01
      this.y=this.start+sin(this.offset)*2
      local hit = this.collide(player,0,0)
      if hit~=nil and hit.djump<max_djump then
        psfx(6)
        init_object(smoke,this.x,this.y)
        hit.djump=max_djump
        this.spr=0
        this.timer=60
      end
    elseif this.timer>0 then
      this.timer-=1
    else 
     psfx(7)
     init_object(smoke,this.x,this.y)
      this.spr=22 
    end
  end,
  draw=function(this)
    if this.spr==22 then
      spr(13+(this.offset*8)%3,this.x,this.y+6)
      spr(this.spr,this.x,this.y)
    end
  end
}
add(types,balloon)

fall_floor = {
  id="fall_floor",
  tile=23,
  init=function(this)
    this.state=0
    this.solid=true
  end,
  update=function(this)
    -- idling
    if this.state == 0 then
      if this.check(player,0,-1) or this.check(player,-1,0) or this.check(player,1,0) then
        break_fall_floor(this)
      end
    -- shaking
    elseif this.state==1 then
      this.delay-=1
      if this.delay<=0 then
        this.state=2
        this.delay=60--how long it hides for
        this.collideable=false
      end
    -- invisible, waiting to reset
    elseif this.state==2 then
      this.delay-=1
      if this.delay<=0 and not this.check(player,0,0) then
        psfx(7)
        this.state=0
        this.collideable=true
        init_object(smoke,this.x,this.y)
      end
    end
  end,
  draw=function(this)
    if this.state!=2 then
      if this.state!=1 then
        spr(23,this.x,this.y)
      else
        spr(23+(15-this.delay)/5,this.x,this.y)
      end
    end
  end
}
add(types,fall_floor)

function break_fall_floor(obj)
 if obj.state==0 then
  psfx(15)
    obj.state=1
    obj.delay=15--how long until it falls
    init_object(smoke,obj.x,obj.y)
    local hit=obj.collide(spring,0,-1)
    if hit~=nil then
      break_spring(hit)
    end
    hit=obj.collide(springl,1,0)
    if hit~=nil then
      break_spring(hit)
    end
    hit=obj.collide(springr,-1,0)
    if hit~=nil then
      break_spring(hit)
    end
  end
end

smoke={
  id="smoke",
  init=function(this)
    this.spr=29
    this.spd.y=-0.1
    this.spd.x=0.3+rnd(0.2)
    this.x+=-1+rnd(2)
    this.y+=-1+rnd(2)
    this.flip.x=maybe()
    this.flip.y=maybe()
    this.solids=false
  end,
  update=function(this)
    this.spr+=0.2
    if this.spr>=32 then
      destroy_object(this)
    end
  end
}

fruit={
  id="fruit",
  tile=26,
  if_not_fruit=true,
  init=function(this) 
    this.start=this.y
    this.off=0
  end,
  update=function(this)
   local hit=this.collide(player,0,0)
    if hit~=nil then
      fruits+=1
      hit.djump=max_djump
      sfx_timer=20
      sfx(13)
      init_object(lifeup,this.x,this.y)
      destroy_object(this)
    end
    this.off+=1
    this.y=this.start+sin(this.off/40)*2.5
  end
}
add(types,fruit)

lifeup = {
  init=function(this)
    this.spd.y=-0.25
    this.duration=30
    this.x-=2
    this.y-=4
    this.flash=0
    this.solids=false
  end,
  update=function(this)
    this.duration-=1
    if this.duration<= 0 then
      destroy_object(this)
    end
  end,
  draw=function(this)
    this.flash+=0.5

    print("1000",this.x-2,this.y,7+this.flash%2)
  end
}

orbup = {
  id="orbup",
  init=function(this)
    this.spd.y=-0.25
    this.duration=30
    this.x-=2
    this.y-=4
    this.flash=0
    this.solids=false
  end,
  update=function(this)
    this.duration-=1
    if this.duration<= 0 then
      destroy_object(this)
    end
  end,
  draw=function(this)
    this.flash+=0.5
    print(orbs.."/4",this.x-2,this.y,7+this.flash%2)
  end
}

nootnoot = {
  id="nootnoot",
  init=function(this)
    this.spd.y=-0.25
    this.duration=30
    this.x-=2
    this.y-=4
    this.flash=0
    this.solids=false
  end,
  update=function(this)
    this.duration-=1
    if this.duration<= 0 then
      destroy_object(this)
    end
  end,
  draw=function(this)
    this.flash+=0.5
    print("noot",this.x-2,this.y,7+this.flash%2)
  end
}

fake_wall = {
  id="fake_wall",
  tile=64,
  if_not_fruit=true,
  update=function(this)
    this.hitbox={x=-1,y=-1,w=18,h=18}
    local hit = this.collide(player,0,0)
    if hit~=nil and hit.dash_effect_time>0 then
      hit.spd.x=-sign(hit.spd.x)*1.5
      hit.spd.y=-1.5
      hit.dash_time=-1
      sfx_timer=20
      sfx(16)
      destroy_object(this)
      init_object(smoke,this.x,this.y)
      init_object(smoke,this.x+8,this.y)
      init_object(smoke,this.x,this.y+8)
      init_object(smoke,this.x+8,this.y+8)
      init_object(fruit,this.x+4,this.y+4)
    end
    this.hitbox={x=0,y=0,w=16,h=16}
  end,
  draw=function(this)
    spr(64,this.x,this.y)
    spr(65,this.x+8,this.y)
    spr(80,this.x,this.y+8)
    spr(81,this.x+8,this.y+8)
  end
}
add(types,fake_wall)

shooterl={
  id="shooterl",
  tile=12,
  init=function(this)
    this.clock=0
    --this.hitbox.x+=2
    --this.hitbox.w=6
  end,
  update=function(this)
    this.clock+=1
    if this.clock==50 then
      p=init_object(projectile,this.x,this.y)
      p.dir=-1
      this.clock=0
    end
  end
}
add(types,shooterl)

shooterr={
  id="shooterr",
  tile=11,
  init=function(this)
    this.clock=0
  end,
  update=function(this)
    this.clock+=1
    if this.clock==50 then
      p=init_object(projectile,this.x,this.y)
      p.dir=1
      this.clock=0
    end
  end
}
add(types,shooterr)

projectile={
  id="projectile",
  init=function(this)
    this.start=this.x
    this.vel=1.5
  end,
  update=function(this)
    this.x+=this.dir*this.vel
    this.flip.x=this.dir==-1
    this.spr=8+(frames/4)%3
    hit=this.collide(player,0,0)
    if hit~=nil then
      kill_player(hit)
    end
    if abs(this.x-this.start)>16*8 then
      destroy_object(this)
    end
  end
}
add(types,projectile)

chest={
  id="chest",
  tile=20,
  init=function(this)
    this.start=this.x
    this.opened=false
    this.timer=20
  end,
  update=function(this)
    if not this.opened then
      if this.check(player,0,0) then
        this.opened=true
        sfx_timer=10
        sfx(23)
      end
    end
    if this.opened and this.timer>=0 then
      this.timer-=1
      this.x=this.start-1+rnd(3)
      if this.timer==0 then
        sfx_timer=20
        sfx(16)
        this.x=this.start
        init_object(orb,this.x,this.y-4)
        this.spr=21
        this.timer=-1
      end
    end
  end
}
add(types,chest)

checkpt = {
  id="checkpt",
  tile=118,
  init=function(this)
    this.hitbox.x=-4
    this.hitbox.w=16
    this.hitbox.y=-4
    this.hitbox.h=16
    this.active=this.x==spawn.x and this.y==spawn.y
  end,
  draw=function(this)
    this.active=this.x==spawn.x and this.y==spawn.y
    local hit=this.collide(player,0,0)
    if not this.active and hit~=nil then
      spawn.x=this.x
      spawn.y=this.y
      this.active=true
      sfx(55)
      sfx_timer=30
    end
    this.spr=118+(frames/5)%3
    pal(11,this.active and 14 or 7)
    spr(this.spr,this.x+4,this.y)
    pal(11,11)
  end
}
add(types,checkpt)

orb={
  id="orb",
  init=function(this)
    this.spd.y=-3
    this.solids=false
    this.particles={}
  end,
  draw=function(this)
    this.spd.y=appr(this.spd.y,0,0.5)
    local hit=this.collide(player,0,0)
    if this.spd.y==0 and hit~=nil then
      sfx_timer=45
      sfx(51)
      orbs+=1
      if orbs==4 then
        music_timer=20
        freeze=20
        max_djump+=1
        hit.djump+=1
        new_bg=true
      else
        init_object(orbup,this.x,this.y)
      end
      destroy_object(this)
    end
    
    spr(102,this.x,this.y)
    local off=frames/30
    for i=0,7 do
      circfill(this.x+4+cos(off+i/8)*8,this.y+4+sin(off+i/8)*8,1,7)
    end
  end
}

flag = {
  id="flag",
  tile=120,
  init=function(this)
    this.x-=2
    this.show=false
    this.offx=1
    this.offy=51
  end,
  draw=function(this)
    this.spr=118+(frames/5)%3
    spr(this.spr,this.x,this.y)
    if this.show then
      rectfill(32+this.offx,2+this.offy,96-this.offx - 1,33+this.offy,0)
      spr(26,49,6+this.offy)
      print(":"..fruits.."/10",58,8+this.offy,7)
      draw_time(42,15+this.offy)
      print("deaths:"..deaths,48,24+this.offy,7)
    elseif this.check(player,0,0) then
      sfx(55)
    sfx_timer=30
      this.show=true
    end
  end
}
add(types,flag)

babypenguin = {
  id="babypenguin",
  tile=113,
  init=function(this)
    this.dir=2*flr(rnd(2))-1
    this.flip.x=this.dir==-1
    this.state=0
    this.timer=0
    this.h=this.y
    this.vel=1
  end,
  update=function(this)
    if not saved_penguin then
      if this.state==0 then
        this.y=this.h
      end
      if this.state==0 and rnd(1)<0.05 then
        this.state=1
        this.dir=2*flr(rnd(2))-1
        this.flip.x=this.dir==-1
        this.timer=5+2*flr(rnd(12))
      end
      if this.state==1 then
        this.spd.x=0.2*this.dir
        if (this.timer/2)%2==0 then
          this.y=this.h-1
        else
          this.y=this.h
        end
        this.timer-=1
        if this.timer==0 then
          this.state=0
          this.spd.x=0
        end
      end
      local hit = this.collide(player,0,0)
      if hit ~= nil then
        has_penguin=true
        sfx_timer=20
        sfx(63)
        destroy_object(this)
      end
    else
      this.flip.x=true
      if this.h==this.y and rnd(1)<0.05 then
        this.timer=2
        this.y=this.h-1
      end
      this.timer-=1
      if this.timer==0 then
        this.y=this.h
      end
    end
    if is_summit() and not saved_penguin then
      destroy_object(this)
    end
  end,
}
add(types,babypenguin)

momguin = {
  id="momguin",
  tile=96,
  init=function(this)
    this.timer=0
    this.y+=8
    this.h=this.y
  end,
  update=function(this)
    local hit = this.collide(player,0,0)
    if has_penguin and hit ~= nil then
      has_penguin=false
      saved_penguin=true
      init_object(babypenguin,this.x+8,this.y)
      sfx_timer=20
      sfx(63)
      init_object(nootnoot,this.x,this.y)
    end
    if saved_penguin then
      this.spr=97
      this.flip.x=true
      if this.h==this.y and rnd(1)<0.05 then
        this.timer=2
        this.y=this.h-1
      end
      this.timer-=1
      if this.timer==0 then
        this.y=this.h
      end
    end
    if is_summit() and not saved_penguin then
      destroy_object(this)
    end
  end,
}
add(types,momguin)

penguin = {
  id="penguin",
  tile=112,
  init=function(this)
    this.dir=2*flr(rnd(2))-1
    this.flip.x=this.dir==-1
    this.state=0
    this.timer=0
    this.bounce=2
    this.h=this.y
    this.vel=1
  end,
  update=function(this)
    if this.state==0 then
      this.y=this.h
    end
    if this.state==0 and rnd(1)<0.05 then
      this.state=1
      this.dir=2*flr(rnd(2))-1
      this.flip.x=this.dir==-1
      this.timer=5+2*flr(rnd(12))
    end
    if this.state==1 then
      this.spd.x=0.2*this.dir
      if (this.timer/2)%2==0 then
        this.y=this.h-1
      else
        this.y=this.h
      end
      this.timer-=1
      if this.timer==0 then
        this.state=0
        this.spd.x=0
      end
    end
    local hit = this.collide(penguin,0,0)
    if hit ~= nil then
      sgn = (hit.x > this.x) and 1 or -1
      this.spd.x = -0.05*sgn
      hit.spd.x = 0.05*sgn
    end
    if is_summit() then
      if not saved_penguin then
        destroy_object(this)
      end
      if this.x<-1 or this.x>121 then 
        this.x=clamp(this.x,-1,121)
        this.spd.x=0
      end
    end
  end,

}
add(types,penguin)

-- object functions --
-----------------------

function init_object(type,x,y)
  local obj = {}
  obj.type = type
  obj.collideable=true
  obj.solids=true

  obj.spr = type.tile
  obj.flip = {x=false,y=false}

  obj.x = x
  obj.y = y
  obj.hitbox = { x=0,y=0,w=8,h=8 }

  obj.cx = chunk_x(x)
  obj.cy = chunk_y(y)

  obj.spd = {x=0,y=0}
  obj.rem = {x=0,y=0}

  obj.is_solid=function(ox,oy)
    return solid_at(obj.x+obj.hitbox.x+ox,obj.y+obj.hitbox.y+oy,obj.hitbox.w,obj.hitbox.h)
     or obj.check(fall_floor,ox,oy)
     or obj.check(fake_wall,ox,oy)
     or obj.check(shooterl,ox,oy)
     or obj.check(shooterr,ox,oy)
  end
  
  obj.is_ice=function(ox,oy)
    return ice_at(obj.x+obj.hitbox.x+ox,obj.y+obj.hitbox.y+oy,obj.hitbox.w,obj.hitbox.h)
  end
  
  obj.collide=function(type,ox,oy)
    local other
    local chunk
    if type==player then
      chunk=playerobj
      for i=1,count(chunk) do
        other=chunk[i]
        if other ~=nil and other.type == type and other != obj and other.collideable and
          other.x+other.hitbox.x+other.hitbox.w > obj.x+obj.hitbox.x+ox and 
          other.y+other.hitbox.y+other.hitbox.h > obj.y+obj.hitbox.y+oy and
          other.x+other.hitbox.x < obj.x+obj.hitbox.x+obj.hitbox.w+ox and 
          other.y+other.hitbox.y < obj.y+obj.hitbox.y+obj.hitbox.h+oy then
          return other
        end
      end
    else
      local cx0=chunk_x(obj.x-64)
      local cy0=chunk_y(obj.y-64)
      for cx=max(1,cx0),min(map_w,cx0+1) do
        for cy=max(1,cy0),min(map_h,cy0+1) do
          chunk=chunks[cy][cx]
          for i=1,count(chunk) do
            other=chunk[i]
            if other ~=nil and other.type == type and other != obj and other.collideable and
              other.x+other.hitbox.x+other.hitbox.w > obj.x+obj.hitbox.x+ox and 
              other.y+other.hitbox.y+other.hitbox.h > obj.y+obj.hitbox.y+oy and
              other.x+other.hitbox.x < obj.x+obj.hitbox.x+obj.hitbox.w+ox and 
              other.y+other.hitbox.y < obj.y+obj.hitbox.y+obj.hitbox.h+oy then
              return other
            end
          end
        end
      end
    end
    return nil
  end
  
  obj.check=function(type,ox,oy)
    return obj.collide(type,ox,oy) ~=nil
  end
  
  obj.move=function(ox,oy)
    local amount
    -- [x] get move amount
  obj.rem.x += ox
    amount = flr(obj.rem.x + 0.5)
    obj.rem.x -= amount
    obj.move_x(amount,0)
    
    -- [y] get move amount
    obj.rem.y += oy
    amount = flr(obj.rem.y + 0.5)
    obj.rem.y -= amount
    obj.move_y(amount)
  end
  
  obj.move_x=function(amount,start)
    if obj.solids then
      local step = sign(amount)
      for i=start,abs(amount) do
        if not obj.is_solid(step,0) then
          obj.x += step
        else
          obj.spd.x = 0
          obj.rem.x = 0
          break
        end
      end
    else
      obj.x += amount
    end
  end
  
  obj.move_y=function(amount)
    if obj.solids then
      local step = sign(amount)
      for i=0,abs(amount) do
      if not obj.is_solid(0,step) then
          obj.y += step
        else
          obj.spd.y = 0
          obj.rem.y = 0
          break
        end
      end
    else
      obj.y += amount
    end
  end

  if obj.type==player or obj.type==player_spawn then
    add(playerobj,obj)
  elseif is_summit() then
    add(summitobj,obj)
  else
    add(chunks[obj.cy][obj.cx],obj)
  end
  if obj.type.init~=nil then
    obj.type.init(obj)
  end
  return obj
end

function destroy_object(obj)
  if obj.type==player or obj.type==player_spawn then
    del(playerobj,obj)
  elseif is_summit() then
    del(summitobj,obj)
  else
    del(chunks[obj.cy][obj.cx],obj)
  end
end

function kill_player(obj)
  died=true
  sfx_timer=12
  sfx(0)
  deaths+=1
  shake=10
  destroy_object(obj)
  dead_particles={}
  for dir=0,7 do
    local angle=(dir/8)
    add(dead_particles,{
      x=obj.x+4,
      y=obj.y+4,
      t=10,
      spd={
        x=sin(angle)*3,
        y=cos(angle)*3
      }
    })
    restart_room()
  end
end

-- room functions --
--------------------

function restart_room()
  will_restart=true
  delay_restart=15
end

preload=true
function load_room()
  if preload then
    preload=false
    foreach(chunks,function(chunky)
      foreach(chunky,function(chunk)
        foreach(chunk, destroy_object)
      end)
    end)
    for tx=0,16*map_w-1 do
      for ty=0,16*map_h-1 do
        local tile = mget(tx,ty)
        foreach(types,function(type) 
          if type.tile==tile then
            init_object(type,tx*8,ty*8) 
          end
        end)
      end
    end
  else
    foreach(playerobj,destroy_object)
    init_object(player_spawn,spawn.x,spawn.y)
  end
end

function load_summit()
  music(30,500,7)
  foreach(chunks,function(chunky)
      foreach(chunky,function(chunk)
        foreach(chunk, destroy_object)
      end)
    end)
  for tx=0,15 do
    for ty=0,15 do
      local tile = mget(7*16+tx,2*16+ty)
      foreach(types,
      function(type)
        if type.tile == tile then
          init_object(type,tx*8,ty*8)
        end
      end)
    end
end
  end

function chunk_x(x)
  return clamp(flr(x/128)+1,1,map_w)
end

function chunk_y(y)
  return clamp(flr(y/128)+1,1,map_h)
end

-- update function --
-----------------------

function _update()
  frames=((frames+1)%30)
  if roomid==1 then
    centiseconds=flr(100*frames/30)
    if frames==0 and roomid==1 then
      seconds=((seconds+1)%60)
      if seconds==0 then
        minutes+=1
      end
    end
  end
  
  if music_timer>0 then
   music_timer-=1
   if music_timer<=0 then
    music(10,0,7)
   end
  end
  
  if sfx_timer>0 then
   sfx_timer-=1
  end
  
  -- cancel if freeze
  if freeze>0 then freeze-=1 return end
  
  -- restart (soon)
  if will_restart and delay_restart>0 then
    delay_restart-=1
    if delay_restart<=0 then
      will_restart=false
      load_room()
    end
  end

  -- start game
  if is_title() then
    if not start_game and (btn(k_jump) or btn(k_dash)) then
      camera(0, 0)
      music(-1)
      start_game_flash=50
      start_game=true
      sfx(38)
    end
    if start_game then
      start_game_flash-=1
      if start_game_flash<=-30 then
        camera(flr(clamp(cam_p.x,64,128*map_w-64)+0.5)-64,flr(clamp(cam_p.y,64,128*map_h-64)+0.5)-64)
        begin_game()
      end
    end
  elseif is_summit() then
    camera(0, 0)
    foreach(playerobj,function(obj)
      obj.move(obj.spd.x,obj.spd.y)
      if obj.type.update~=nil then
        obj.type.update(obj)
      end
    end)
    foreach(summitobj,function(obj)
      obj.move(obj.spd.x,obj.spd.y)
      if obj.type.update~=nil then
        obj.type.update(obj)
      end
    end)
  else
  -- update each object
    foreach(playerobj,function(obj)
      obj.move(obj.spd.x,obj.spd.y)
      cam_v.x=cam_g*(4+obj.x+0*obj.spd.x-cam_p.x)
      cam_v.y=cam_g*(4+obj.y+0*obj.spd.y-cam_p.y)
      cam_p.x+=cam_v.x
      cam_p.y+=cam_v.y
      if obj.type.update~=nil then
        obj.type.update(obj)
      end
    end)
    local cx0=chunk_x(cam_p.x-64)
    local cy0=chunk_y(cam_p.y-64)
    for cx=max(1,cx0),min(map_w,cx0+1) do
      for cy=max(1,cy0),min(map_h,cy0+1) do
        foreach(chunks[cy][cx],function(obj)
          obj.move(obj.spd.x,obj.spd.y)
          if obj.type.update~=nil then
            obj.type.update(obj)
          end
        end)
      end
    end
    if cam_p.x < 64 or cam_p.x > 128*map_w-64 then
      cam_v.x=0
    end
    if cam_p.y < 64 or cam_p.y > 128*map_h-64 then
      cam_v.y=0
    end
  end
end

-- drawing functions --
-----------------------
function _draw()
  if freeze>0 then return end
  
  -- reset all palette values
  pal()
  
  -- start game flash
  if start_game then
    local c=10
    if start_game_flash>10 then
      if frames%10<5 then
        c=7
      end
    elseif start_game_flash>5 then
      c=2
    elseif start_game_flash>0 then
      c=1
    else 
      c=0
    end
    if c<10 then
      pal(6,c)
      pal(12,c)
      pal(13,c)
      pal(5,c)
      pal(1,c)
      pal(7,c)
      pal(9,c)
    end
  end

  if is_title() then
    local bg_col = 0
    if flash_bg then
      bg_col=frames/5
    end
    rectfill(0,0,128,128,bg_col)
    map(7*16,3*16,-4,0,16,16,2)
    print("a mod of celeste",34,80,5)
    print("by matt thorson",36,86,5)
    print("and noel berry",38,92,5)
    print("kris de asis",42,108,5)
    foreach(particles, function(p)
      p.x += p.spd
      p.y += sin(p.off)
      p.off+= min(0.05,p.spd/32)
      rectfill(p.x,p.y,p.x+p.s,p.y+p.s,p.c)
      if p.x>128+4 then 
        p.x=-4
        p.y=rnd(128)
      end
    end)
  elseif is_summit() then
    local bg_col = 0
    if flash_bg then
      bg_col=frames/5
    elseif new_bg~=nil then
      bg_col=1
    end
    rectfill(0,0,128,128,bg_col)
    foreach(clouds, function(c)
      c.x += c.spd
      rectfill(c.x,c.y,c.x+c.w,c.y+4+(1-c.w/64)*12,new_bg~=nil and 13 or 1)
      if c.x > 128 then
        c.x = -c.w
        c.y=rnd(128-8)
      end
    end)
    map(7*16,2*16,0,0,16,16,4)
    pal(12,(max_djump == 2) and 14 or 12)
    map(7*16,2*16,0,0,16,16,2)
    pal(12,12)
    foreach(summitobj, function(o)
      draw_object(o)
    end)
    foreach(playerobj, function(o)
      draw_object(o)
    end)
    map(7*16,2*16,0,0,16,16,8)
    foreach(particles, function(p)
      p.x += p.spd
      p.y += sin(p.off)
      p.off+= min(0.05,p.spd/32)
      rectfill(p.x,p.y%128,p.x+p.s,p.y%128+p.s,p.c)
      if p.x>128+4 then 
        p.x=-4
        p.y=rnd(128)
      elseif p.x<-4 then
        p.x=128
        p.y=rnd(128)
      end
    end)
    if roomid==2 then
      local p
      for i=1,count(playerobj) do
        if playerobj[i].type==player then
          p = playerobj[i]
          break
        end
      end
      if p~=nil then
        local diff=min(24,40-abs(p.x+4-64))
        rectfill(0,0,diff,128,0)
        rectfill(128-diff,0,128,128,0)
      end
    end
  else
    -- camera loc
    local camx=flr(clamp(cam_p.x,64,128*map_w-64)+0.5)-64
    local camy=flr(clamp(cam_p.y,64,128*map_h-64)+0.5)-64
	
	camera(flr(clamp(cam_p.x,64,128*map_w-64)+0.5)-64,flr(clamp(cam_p.y,64,128*map_h-64)+0.5)-64)

    -- clear screen
    local bg_col = 0
    if flash_bg then
      bg_col=frames/5
    elseif new_bg~=nil then
      bg_col=1
    end
    rectfill(camx,camy,camx+128,camy+128,bg_col)

    -- clouds
    foreach(clouds, function(c)
      c.x += c.spd-cam_v.x
      rectfill(c.x+camx,c.y+camy,c.x+c.w+camx,c.y+4+(1-c.w/64)*12+camy,new_bg~=nil and 13 or 1)
      if c.x > 128 then
        c.x = -c.w
        c.y=rnd(128-8)
      end
    end)

    -- draw bg terrain
    map(0,0,0,0,16*7,16*4,4)

    local cx0=chunk_x(cam_p.x-63)
    local cy0=chunk_y(cam_p.y-63)

    -- projectiles
    for cx=max(1,cx0),min(map_w,cx0+1) do
      for cy=max(1,cy0),min(map_h,cy0+1) do
        foreach(chunks[cy][cx], function(o)
          if o.type==projectile then
            draw_object(o)
          end
        end)
      end
    end

    -- draw terrain

    pal(12,(max_djump == 2) and 14 or 12)
    map(0,0,0,0,16*7,16*4,2)
    pal(12,12)
    
    -- draw objects
    for cx=max(1,cx0),min(map_w,cx0+1) do
      for cy=max(1,cy0),min(map_h,cy0+1) do
        foreach(chunks[cy][cx], function(o)
          if o.type~=projectile then
            if o.type==fake_wall then
              pal(12,(max_djump == 2) and 14 or 12)
              draw_object(o)
              pal(12,12)
            else
              draw_object(o)
            end
          end
        end)
      end
    end

    foreach(playerobj, function(o)
      draw_object(o)
    end)
    
    -- draw fg terrain
    map(0,0,0,0,16*7,16*4,8)
    
    -- particles
    foreach(particles, function(p)
      p.x += p.spd-cam_v.x
      p.y += sin(p.off)-cam_v.y
      p.off+= min(0.05,p.spd/32)
      rectfill(p.x+camx,p.y%128+camy,p.x+p.s+camx,p.y%128+p.s+camy,p.c)
      if p.x>128+4 then 
        p.x=-4
        p.y=rnd(128)
      elseif p.x<-4 then
        p.x=128
        p.y=rnd(128)
      end
    end)
    
    -- dead particles
    foreach(dead_particles, function(p)
      p.x += p.spd.x
      p.y += p.spd.y
      p.t -=1
      if p.t <= 0 then del(dead_particles,p) end
      rectfill(p.x-p.t/5,p.y-p.t/5,p.x+p.t/5,p.y+p.t/5,14+p.t%2)
    end)
    
    -- draw outside of the screen
    local w=128
    rectfill(-w,-w,-1,w+128*map_h-1,0)
    rectfill(-w,-w,w+128*map_w-1,-1,0)
    rectfill(-w,1+128*map_h-1,w+128*map_w-1,w+128*map_h-1,0)
    rectfill(1+128*map_w-1,-w,w+128*map_w-1,w+128*map_h-1,0)
  end

end

function draw_object(obj)
  if obj.type.draw ~=nil then
    obj.type.draw(obj)
  elseif obj.spr > 0 then
    spr(obj.spr,obj.x,obj.y,1,1,obj.flip.x,obj.flip.y)
  end

end

function draw_time(x,y)

  local cs=centiseconds
  local s=seconds
  local m=minutes%60
  local h=flr(minutes/60)
  
  rectfill(x,y,x+44,y+6,0)
  print((h<10 and "0"..h or h)..":"..(m<10 and "0"..m or m)..":"..(s<10 and "0"..s or s).."."..(cs<10 and "0"..cs or cs),x+1,y+1,7)

end

-- helper functions --
----------------------

function clamp(val,a,b)
  return max(a, min(b, val))
end

function appr(val,target,amount)
 return val > target 
  and max(val - amount, target) 
  or min(val + amount, target)
end

function sign(v)
  return v>0 and 1 or
                v<0 and -1 or 0
end

function maybe()
  return rnd(1)<0.5
end

function solid_at(x,y,w,h)
 return tile_flag_at(x,y,w,h,0)
end

function ice_at(x,y,w,h)
 return tile_flag_at(x,y,w,h,4)
end

function tile_flag_at(x,y,w,h,flag)
 for i=max(0,flr(x/8)),min(16*map_w-1,(x+w-1)/8) do
  for j=max(0,flr(y/8)),min(16*map_h-1,(y+h-1)/8) do
    if fget(tile_at(i,j),flag) then
      return true
    end
  end
 end
  return false
end

function tile_at(x,y)
  if is_summit() then
    return mget(7*16 + x, 2*16 + y)
  else
    return mget(x, y)
  end
end

function spikes_at(x,y,w,h,xspd,yspd)
 for i=max(0,flr(x/8)),min(16*map_w-1,(x+w-1)/8) do
  for j=max(0,flr(y/8)),min(16*map_h-1,(y+h-1)/8) do
   local tile=tile_at(i,j)
   if tile==17 and ((y+h-1)%8>=6 or y+h==j*8+8) and yspd>=0 then
    return true
   elseif tile==27 and y%8<=2 and yspd<=0 then
    return true
    elseif tile==43 and x%8<=2 and xspd<=0 then
     return true
    elseif tile==59 and ((x+w-1)%8>=6 or x+w==i*8+8) and xspd>=0 then
     return true
    end
  end
 end
  return false
end
__gfx__
00000000000000000000000005888880000000000000000000000000000000000000000000000000000000005dddddddddddddd5000060000000600000060000
0000000005888880028888805988888805888880058888000000000005888880080899000888a900800899005d6666d55d6666d5000060000000600000060000
000000005988888829888888588881185988888898888880058888805981111800899aa0009a9aa088899aa0566666d55d666665000600000000600000060000
00000000588881182888811888f11f1858888118881118805988888858f11f18889a9aa008899aa0089a9aa0566666d55d666665000600000000600000060000
0000000088f11f1888f11f1808fffff088f11f1881f11f8058888ff888fffff809899aa08989aaa00989aaa0566666d55d666665000600000006000000006000
0000000008fffff008fffff0002ee20008fffff00fffff8088111118082ee280008a9aa008899aa080899aa0566666d55d666665000600000006000000006000
00000000002ee200002ee20007000070072ee200002ee27008f11f1000222200080899008008990009089a005d6666d55d6666d5000060000006000000006000
000000000070070000700070000000000000070000007000072ee270007007000000000000000000000000005dddddddddddddd5000060000006000000006000
555555550000000000000000000000000000000000000000008888004999999449999994499909940300b0b06665666500000000000000000000000070000000
55555555000000000000000000000000000000000000000008888880911111199111411991140919003b33006765676500040000007700000770070007000007
550000550000000000000000000000000aaaaaa00000000008788880911111199111911949400419028888206770677000095050007770700777000000000000
55000055007000700499994000000000a998888a2222222208888880911111199494041900000044089888800700070000090505077777700770000000000000
55000055007000700050050000000000a988888a4111111408888880911111199114094994000000088889800700070000090505077777700000700000000000
55000055067706770005500000000000aaaaaaaaaaaaaaaa08888880911111199111911991400499088988800000000000095050077777700000077000000000
55555555567656760050050000000000a981188aa981188a00888800911111199114111991404119028888200000000000040000070777000007077007000070
55555555566656660005500004999940a988888aa988888a00000000499999944999999444004994002882000000000000000000000000007000000000000000
5777777557777777777777777777777577cccccccccccccccccccc77577777755555555555555555555555555500000007777770000000000000000000000000
77777777777777777777777777777777777cccccccccccccccccc777777777775555555555555550055555556670000077777777000040004000000000000004
777c77777777ccccc777777ccccc7777777cccccccccccccccccc777777777775555555555555500005555556777700077777777050590009000000000000009
77cccc77777cccccccc77cccccccc7777777cccccccccccccccc7777777cc7775555555555555000000555556660000077773377505090009000000000000009
77cccc7777cccccccccccccccccccc777777cccccccccccccccc777777cccc775555555555550000000055555500000077773377505090009000000000000009
777cc77777cc77ccccccccccccc7cc77777cccccccccccccccccc77777cccc775555555555500000000005556670000073773337050590009000000000000009
7777777777cc77cccccccccccccccc77777cccccccccccccccccc77777c7cc77555555555500000000000055677770007333bb37000040004000000000000004
5777777577cccccccccccccccccccc7777cccccccccccccccccccc7777cccc77555555555000000000000005666000000333bb30000000000000000000000000
77cccc7777cccccccccccccccccccc77577777777777777777777775777ccc775555555550000000000000050000066603333330000000000000000000000000
777ccc7777cccccccccccccccccccc77777777777777777777777777777cc7775055555555000000000000550007777603b333300000000000ee0ee000000000
777ccc7777cc7cccccccccccc77ccc777777ccc7777777777ccc7777777cc77755550055555000000000055500000766033333300000000000eeeee000000030
77ccc77777ccccccccccccccc77ccc77777ccccc7c7777ccccccc77777ccc777555500555555000000005555000000550333b33000000000000e8e00000000b0
77ccc777777cccccccc77cccccccc777777ccccccc7777c7ccccc77777cccc7755555555555550000005555500000666003333000000b00000eeeee000000b30
777cc7777777ccccc777777ccccc77777777ccc7777777777ccc777777cccc775505555555555500005555550007777600044000000b000000ee3ee003000b00
777cc777777777777777777777777777777777777777777777777777777cc7775555555555555550055555550000076600044000030b00300000b00000b0b300
77cccc77577777777777777777777775577777777777777777777775577777755555555555555555555555550000005500999900030330300000b00000303300
5777755777577775077777777777777777777770077777700000000000000000cccccccc00000000000000000000000000000000000000000000000000000000
777777777777777770000777000077700000777770007777000000dddd000000c77ccccc00000000000000000000000000000000000000000000000000000000
7777cc7777cc777770cc777cccc777ccccc7770770c7770700000dd7ddd00000c77cc7cc00000000000000000000000000000000000000000000000000000000
777cccccccccc77770c777cccc777ccccc777c0770777c0700055dddddd00000cccccccc00000000000000000000000000006000000000000000000000000000
77cccccccccccc777077700007770000077700077777000700000dddddd00000cccccccc00000000000000000000000000060600000000000000000000000000
57cc77ccccc7cc7577770000777000007770000777700007000d66666666d000cc7ccccc00000000000000000000000000d00060000000000000000000000000
577c77ccccccc7757000000000000000000c000770000c0700d6666666666d00ccccc7cc0000000000000000000000000d00000c000000000000000000000000
777cccccccccc77770000000000000000000000770000007006ddddd6d6dd600cccccccc000000000000000000000000d000000c000000000000000000000000
777cccccccccc7777000000000000000000000077000000700666666666666000000000000000000000000000000000c0000000c000600000000000000000000
577cccccccccc7777000000c000000000000000770cc00070d6dd6dddd6dd6d0000000000000000000000000000000d000000000c060d0000000000000000000
57cc7cccc77ccc7570000000000cc0000000000770cc0007dd666666666666dd00000000000000000000000000000c00000000000d000d000000000000000000
77ccccccc77ccc7770c00000000cc00000000c0770000c07dd666ddd6dd666dd0000000000000000000000000000000000000000000000000000000000000000
777cccccccccc77770000000000000000000000770000007d06666666666660d5555555500000007777700777777007777770077000000777007777770000000
7777cc7777cc777770000000000000000000000770c0000700666666666666005555555500000077777770777777707777777077000000777707777777000000
777777777777777770000000c0000000000000077000000700667766677776005555555500000077000770770007707700000077000000077007700000000000
57777577775577757000000000000000000000077000c00707777777777777705555555500000099999990990009909999000099000000099009999000000000
00000000000000007000000000000000000000077000000700000000500000000000000500000099000990990009909900000099000090099009900000000000
0000000010111101700000000000000000000007700c000700000000550000000000005500000099000990999999909999990099999990999009999990000000
0011110011717111700000000000c000000000077000000700000000555000000000055500000099000990999999009999999099999990999909999999000000
01717110119911117000000cc0000000000000077000cc0700007000555500000000555500000000000000000000000000000000000000000000000000000000
0c991c10017771107000000cc0000000000c00077000cc070707b70055555555555555550000000000000c000000000000000000000000000000c00000000000
117771110177711070c00000000000000000000770c000070077bb705555555555555555000000000000c00000000000000000000000000000000c0000000000
1977911101777110700000000000000000000007700000070700007055555555555555550000000000cc0000000000000000000000000000000000c000000000
09669110099d991107777777777777777777777007777770007777005555555555555555000000000c000000000000000000000000000000000000c000000000
000000000000000007777777777777777777777007777770004bbb00004b000000400bbb00000000c0000000000000000000000000000000000000c000000000
001111000000000070007770000077700000777770007777004bbbbb004bb000004bbbbb0000000100000000000000000000000000000000000000c00c000000
011717100011110070c777ccccc777ccccc7770770c7770704200bbb042bbbbb042bbb00000000c0000000000000000000000000000000000000001010c00000
011199100010700070777ccccc777ccccc777c0770777c07040000000400bbb004000000000001000000000000000000000000000000000000000001000c0000
111777110d1797d07777000007770000077700077777000704000000040000000400000000000100000000000000000000000000000000000000000000010000
111777110d6666d077700000777000007770000777700c0742000000420000004200000000000100000000000000000000000000000000000000000000001000
01177710006666007000000000000000000000077000000740000000400000004000000000000000000000000000000000000000000000000000000000000000
1199d990069dd9000777777777777777777777700777777040000000400000004000000000010000000000000000000000000000000000000000000000000000
450000a29382831262000054425233b1b100000000a29300000000000064740000000000a382820000000000a2a2a300000042526242620000a3425252526200
a2a2a2a2a200b11333244413232333a3a300009393931232a38283828282931333b200b100b302b200b100b30200004200000000000000000000000000000000
4593a38282828213620000554262b100000000000000a29300006700d36575e3f3009300a383920000000000a3a311111111425233426293a392428452233300
00a2a2a200000001b125450000a3a3a30000000093934262b1b1b1b1b1b1b1a2820000000000b10000000000b100004200000000000000008700000000000000
45828392000000a27382935542620000000000000000007293a31222222222222222222222321232243434343434344412225262125262a2927142526272b200
0011a200670000000025450000a3a3000000000000934262b20000000000000001000000000000000000000000000042000000000000a3126393000000000000
450000000000000000a2825542621111a38293000000000383824252845252525252522323334262263636364612223242525262425262930000425233039292
b34353532232a20292254593a3a300110000000000004262b200000000000000a29300000000000000000000000000428293000000001262577243630000a382
35470000000100006700a255426212329200a2930000b30392a21323232323235252621222225252222222222252526242528462425262a293a3426212629292
0061000242620000112545a28282937200c2000000004262b200a28282828282838200c2000000930093670093000042019382930000425222620000a383a382
45b10000a28292007200d35642624262b20000010000b3030000b100000000a2132362425252522323232323232323334252526213233371a292426242629200
000000b342620283022546118382a20300c3006700004262b20000a29300000000a293c3000093829312225363b2f3428282829393125223235232a3a3828282
46110000a30093004222222252624262b20000a29300b303b2000000e30000b3123203132323339200000002122222225252232363a2930000a3426242621100
000000b34262000000551232828200030002931263004262b2000000a282839300b31232432222535323620083b343529292000012523324441352320000a2a2
22320200004100004284525252624262b20000a39200b31353535353536300b313330302b100a293000000b342525252526202b1b100a293a392426242523211
11a2a2a24262a30293551333a28293039300a27300a34262b20000000000008200b31323631333b1b1b173008200b3420000a312526224353544425232000000
52621232273747721323232323334262b2a383920000a3920000a29300000000122262b1000000a2930000b3425284525262b100000000a29202426242523312
32b2a2a242621100002544b1a2a2a20382930000a3824262b200000000a382828282920083000000a38282829200b34200a38203426225353545426203930000
52624252222222522222222222225262a392000000008300717100a2937171004252629300000000a27200b31323232323620000000067001222526242621252
62b2a2a2426202010226460000a2a2422232000012225233b20000000082001100000000a2828283920000000000b342a3831233426225353545426213329300
233342525252232323232352525284629200610000a3920000000000a28393004252628393000000a3030000b1b1b1b1b1030000111112225284526242621323
33b200a242620000a3a383939300a202426293a3425262b1000000000082b3720000000000000000000072000000b34200007300426225353545426293730000
222252845233b1000000a2132323526200000000a3920000a38293000000a28242846272a282828382030000a20193a3b30392a2122252232323233342523200
000000004262a38382a28292838293122333a28242526282838282820192b3730000000093000000435333d20000b342000000a3426225353545426282930000
2323235262000000930000b1b1b1133393000000820000008200a2930000000042526273b2000000a203111111110083b37393a3425262122222223242526200
67000000425232111111000000001262a111008342526292000000000000b3b2000000a301920000000000000000b3130000a301136225353545423383829300
9200a21333a293a3820193000000710083000000a29300a3920000a293a382834252620400110000007343222232b29200b10000425262132352526213233312
32b200001323235322223271714323232232a38242526211111111000000b3b200000000a2000000a2930000000000c0000000a3827326353546738293060000
00a100b1b10092a28382920000007100820000000001008211110000a2921111425262000072670000b102428462b22100000000422333040042526212222223
33b200008200b1b1132333000083b10242628282132323535322320000000000000000000011111111a293000000b312001007d34353632646435363839317f3
93000011110000000000000021000000a293f367a3920082123211111111721252525232021363000000b1425262110211111111730000000042526213233312
638201829293000082b10000008200b34262838282828293b1426282839200a383930093b34353536393a2930000b34227373737373737373737373737373747
22223212320000a3828312223211111111122222222222225252321222226242845252621222223200000013232353631222532232b312222252845222222262
b0000000a2a38283929300000082000042629200000000a29342620000000000a39200820000000000a293a29300b342b40000e4f40000000000000000000000
525262133300a39200a242846212222232425252232352845223334252233313232323331323526200000000a28292b11362024262b342525223232323235252
3211000000000011a2a30182829293004262111111111100a242628393000000a2930082000000000011a293a293b342b40000e4f40000000000000000000000
52525232a3828393000042526242528462425262123242233302125233000000000000b34363425232000000008200000013532333b3132333b1b1b1b1b14252
6202111111111102d200001100a2a38242625353535363a2a2426200a29300930083008200001100b302b2a39200b34200000000000000000000000000000000
8452526282a3a2920000425262132323334252621333730000a34262b1000000000000001222525233930000a382000000000000000000829200720000004284
621222222232243434441232000083004262b1a382829292a2426200a38393a20192008200b372b20000a3920000b34200000000000000000000000000000000
522323338293920193a3425233b1b1b112525233828382828282426200000000000000a34252526202828201829200000000000000a30192110003b200a31323
331323235262263636464262000082004262a39200009200004262a39200a2930000a38393b303b2e3a392112100b34200c7d7000094a4b4c4d4e4f400000000
33b1b1b1a2928292a2824262b10000c1425262920000000000a21333000000111100a38242845252320000a28300000000a3433200009200029303b2a3920000
0000a283425222222222846200008211426282001111111111423392000000a254122222222252222222223202122252000000000095a5b5c5d5e5f500000000
b10000000000a2000000426283829300425262000000000000a383920000a31232a392a242522323330000a382000000a392b10311000000b1a203a39200e300
670000a24252525223235262838292125262830043222222226200670000a38255425252525252525284525222525252000000000096a6b6c6d6e6f600000000
0193000000000000210042523201820142846200000072820182920000a39242629200e3423392a282930082829300a392000042321232b20000039200111222
320000b342845262123242620000a2425262a2930042525223339372b20083b355428423232323232323232323232323000000000097a7b7c7d7e7f700000000
828282930000717171001352629211a2425262000000030183920000a3920042629300430392000000a282838282829200000042621333b200007300b3024252
620000b3132323334262133300000042846200a2934223338292a203b20082b35613332437373737373737373737343400000000000000000000000000000000
82930000000000000000a342842222225252629300a3738201000000a2930042628293a373000000000000829200a2930000a3422363b2000000710000b14284
33000000a28282432333b1b100004323526202008203b1b183122262b20082b32434374657000000829200829357263500000000000000000000000000000000
9200006100000000a30182422323232352526201828271839200000000a293426282838293000000000000820000000100a38303000000000000710000004262
b00000000092007100b10000000000574262b100010317a382425233b20082b3254624470000a382008382008293542600000000000000000000000000000000
11000000000000a28292b373b10000001323339200a27292000000c20000724252328292a29300123200a392000000a28292a2031111110000c1728393004252
32b2000000000000710000000000b31252620000a2135353532333b2000082b355274600000082a3820000a3a382263700000000000000000000000000000000
32b2000000a3828283930000000000000000000000007300000000c3001173428462920000a2934262a38200000000a39200004222226382838203b2a2934252
33b2000000000071000000a30000b31352620000009200a29200a200610082b356000000a30193a293938200a38306a300000000000000000000000000000000
62b20000a2019200a282829300000067000000000000436300001222222232425262930000a30142621232000067a3920000f3132362920000a203b2a3924262
57930000930000717100a382930000c04262d200000000000000000000000100b100000082008300829300a3a382828200000000000000000000000000000000
62b2000000829300f30000829311122232000000000072b10000135252233342525232432222225262133312222232d300111222320300000000730192004252
328293a383829324449382820193a31252621232b2000093a39300000000a283545700078307830082930007a357244400000000000000000000000000000000
62b2000000a2011222327212222252525222329300a303a10000b342621232425252620242528452522222525284522232024252620300000000000000004252
6282838282828225458382828282014252624262b200a3828282939393a393002534344412223224343434442434353500000000000000000000000000000000
__label__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000060000000000000000000000000000000000000000000000000000000
00000600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000007000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000060000000000000000000000000000000000000000000000000000000000000070000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00066000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00066000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000600
00000000000000000000000000000000000000000000000000000000000000000000000000000060000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
60000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000060600000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000d00060000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000d00000c000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000d000000c000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000c0000000c000600000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000d000000000c060d0000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000c00000000000d000d000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000007777700777777007777770077000000777007777770000000000000000000000000000000000000000000
00000000000000000000000000000000000000000077777770777777707777777077000000777707777777000000000000000000000000000000000000000000
00000000000000000000000000000000000000000077000770770007707700000077000000077007700000000000000000000000000000000000000000000000
00000600000000000000000000000000000000000099999990990009909999000099000000099009999000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000099000990990009909900000099000090099009900000000000000000000000000000000000000000000000
00000000000000000000070000000000000000000099000990999999909999990099999990999009999990000000000000000000000000000000000000000000
00000000000000000000000000000000000000000099000990999999009999999099999990999909999999000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000c000000000000000000000000000000c00000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000c00000000000000007000000000000000c0000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000cc0000000000000000000000000000000000c000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000c000000000000000000000000000000000000c000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000c0000000000000000000000000000000000000c000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000100000000000000000000000000000000000000c00c000000000000000000000000000000000000000000
000000000000000000000000000000000000000000c0000000000000000000000000000000000000001010c00000000000000000000000000000000000000000
000000000000000000000000000000000000000001000000000000000000000000000000000000000001000c0000000000000000000000000000000000000000
00000000000000000000000000000000000000000100000000000000000000000000000000000000000000010000000000000000000000000000000000060000
00000000000000000000000000000000000000000100000000000000000000000000000000000000000000001000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000700000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000600000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000005550000055500550550000000550555000000550555050005550055055505550000000000000000000000000000000
00000000000000000000000000000000005050000055505050505000005050500000005000500050005000500005005000000000000000000000000000000000
00000000000000000000000000000000005550000050505050505000005050550000005000550050005500555005005500000000000000000000000000000000
00000000000000000000000000000000005050000050505050505000005050500000005000500050005000005005005000000000000000000000000000000000
00000000000000000000000000000000005050000050505500555000005500500000000550555055505550550005005550000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000055505050000055505550555055500000555050500550555005500550550000000000000000000000000000000000
00000000000000000000000000000000000050505050000055505050050005000000050050505050505050005050505000000000000000000000000000000000
00000000000000000000000000000000000055005550000050505550050005000000050055505050550055505050505000000000000000000000000000000000
00000000000000000000000000000000000050500050000050505050050005000000050050505050505000505050505000000000000000000000000000000000
00000000000000000000000000000000000055505550000050505050050005000000050050505500505055005500505000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000555055005500000055000550555050000000555055505550555050500000000000000000000000000000000000
00000000000000000000000000000000000000505050505050000050505050500050000000505050005050505050500000000000000000000000000000000000
00000000000000006000000000000000000000555050505050000050505050550050000000550055005500550055500000000000000000000000000000000000
00000000000000000000000000000000000000505050505050000050505050500050000000505050005050505000500000000000000000000000000000000000
00000000000000000000000000000000000000505050505550000050505500555055500000555055505050505055500000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000050505550555005500000550055500000555005505550055000000000000000000000000000000000000000
00000000000000000000000000000000000000000050505050050050000000505050000000505050000500500000000000000000000000000000000000000000
00000000000000000000000000000000000000000055005500050055500000505055000000555055500500555000000000000000000000000000000000000000
00000000000000000000000000000000000000000050505050050000500000505050000000505000500500005000000000000000000000000000000000000000
00000000000000000000000000000000000000000050505050555055000000555055500000505055005550550000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000060000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000770000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000770000000000000000000000000000000000000000000000000000000

__gff__
0000000000000000000000000000000004020000000000000000000200000000030303030303030304040402020000000303030303030303040404020202020200001313131302020302020202020002000013131313020204020202020202020000131313130004040202020202020200001313131300000002020202020202
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
2525252532323331252525252525482525323232333132323232323233373132322526724373737374313232323232323232323248252532323232323232252548252532252525252525252525252548252526282838312532323225253232323232323232323232323232323232252500000000000000000000000000000000
254832333a00292a3132323232323232331b00000000100000000000000000001b31252355381b000000003a2838292a2810391b2425261b002a3900001b24252525261031323225482525253232323232252638292928302b003b243300282928291b290029292829292829003b313200000000000000000000000000000000
25261b002a3900002a002a292a0039003a000000002a38290000000000000000000024265528000000003a28282900002a28383924252600003f2a3900002425252526001b1b1b31252525263a28382839242629000029302b1a3b30000029202900000000001129000029000000000c00000000000000000000000000000000
25330016002900171700000000001028100000000000100000760000000000000000242665290000003a382829003e00002a28102425263900213536393a3132323233390000001b312548262829002a28242600000000372b003b300076007273737374171775177517000000003b2100000000000000000000000000000000
261b0000000000000000007274002a002900293f002a38290020110000111111000024262b0000004273737344727344003a28283132332a393045002a291b1b1b1b1b2a390000001b31252638001000282426390000001b00000030003435231b1b1b1b0000000000000000002a282400000000000000000000000000000000
260000003a10390000003a2123003a28393a2123393a10393a21230000343536171724262b00000055113d1152737453734438291b1b1b002a30550000000016000000002a392700001b31332839003a3824262810392a3839001c300000203000000000000000000000000016002a2400000000000000000000000000000000
2600003a29112a39003a293126002a38290024263a29142a3924263939001b1b000024267539000062737373647273642755290000000000003055170000111111111100122a24233d00003a2828002828242629000000112a39003039001b3011000000000000000000000000002a2400000000000000000000000000000000
260016283b202b2838283b203011111121232426212222222225262838282839003a24262b1000002a28390038283828306511121111111211306511111121222222230017002448230076283810003828242600000000272b283b302a393a24232d000000000000000011111111002400000000000000000000000000000000
26003a38391b3a29002a3921252222232426313331323232482526282900292a281024262b380000002a102828282829313535222222222222252222222225252548261111112425252222232810142828242672737374302b2a3b30002a2924263a000011000000003b343535362b2400000000000000000000000000000000
333a29002a28290039002a3132323233242600002a3829003125261111111111003b2426452839000000000000000000002a38313232322525323232323232322525323535352525253232323535352222482522222222262b393b372b00002426280000272b00000011002a28293b2400000000000000000000000000000000
23290000000000000000001b1b1b1b1b2426393a2829000000242522222235362b0024266273740000000076000000000000280000003b24261b00000000001b3126001b1b1b3132263828390000003132323232323225262b38001600003a2426283a00372b00003a272b0038003b2400000000000000000000000000000000
2600003800390000272b00003a28390024262a10111100000024253232262a39000024252222233436212222230000000000283900000024262d003a382828393b302d000000001b302d00280000000000002a39003a24262b2a28392a2829242628283a00003a2828302b0028003b2400000000000000000000000000000000
332b0028002a3828302b3d3a38002a3931333a2921232b003b24261a2a30002a391124252532323535323232330000001100212300000031262839280000002a2837390011000000300000100011001600000028002824261111111111111124332938283a3a380000302b0028003b2400000000000000000000000000000000
2000002a00000000302122222223002a393a290024262b163b242611003739002a212525331b1b1b1b1b1b1b0000003b202b313339000000302b3829001100000000100027003a38372828293b202b00110000281428242522222222223535331b002928280028001c372b0028003b2400000000000000000000000000000000
360000002a00001130242525482612002a29000024262a283924262000002a393b2425261b0000000016003a000012001b0040272828393a302b28003b272d0000002a28302829002a390000001b003b202b00342222252525252525262b110000001129290028000000003a0039002400000000000000000000000000000000
232b000000003b2030313232323320111111112024263a3a292425231100002a392425263900003a29112a38390017003900003729002a10302b28393b3739000011003a3000004949280000000000001b00001b3125482525252525263b202b113b202b11002a28281028001600382400000000000000000000000000000000
260000000000001b242222222222223535353522252629103b242525222300002a244826280000383b202b291100003b343522222300002a30382928000010003b202b38372b00760027000000000000000000001b31252525252525262b113b202b003b202b11000000002a00292a2400000000000000000000000000000000
2639003900390000243232323232331b3a391b313233292a3b24252532330000003125263839002a391b3a3b202b003a292a2425260000003716002a28282900002a28291b003b3435332b000000000000000000001b242532323232333b202b00000000003b202b110000002800002400000000000000000000000000000000
2600280039003900372b000000292a2a382829292a000000002425331b000000001b3126282800002a1010391b3a2829003b2448262000002800000000000000000000000000000000000000000000002a002a39003a2426212222232b00003a003a00000000003b2728382829003b2400000000000000000000000000000000
26290029002a0039000000000000002a292a290000002a28382426000000003a00003b2422232b000000002a38290000003b242525230000380000000000000000000000003a00000000000000000000002a282828282426242548262b003a283a38003a0000003b3029000000003b2400000000000000000000000000000000
2639000000002a00390000001111110017170011110000001224263900002a3839003b2425262b00000000000000003a38282425252600002800003a003a39000000002a00002a3a28281039000000003a003a2810292426242525262b00282829283a280000003b302b000000003b2400000000000000000000000000000000
263839000000002a00397600272123111111112123111111202426281039002a3900002432332b001717000011003a292a2a24253233270028000028002a290000000000003a3a282a282928000000000000003828392426242525262b002838002929280000003b302b000000003b2400000000000000000000000000000000
262828393a39003a28727374302425222222233133212222232426292a28282828283930272b00003829003b272b29163a0024262122263829003a1000000000000000000000002829002a3829003a00002a3a2828282426242532332b002928000000290016003b372b001600003b2400000000000000000000000000000000
262828282828282821222222263132323232323535252525262426393a29002910282830372b003a2911003b372b393a293b24262425330000002828282900000000003a002a3a2811111128000000003a0029003a00242631332b000000002900001100000000000000000000003b2400000000000000000000000000000000
26281028292a2828242532323300002a38282828283132323324262a103900002a38292423003a293b272b001b00292a390024262426212300003829000000000000000000000021222235231100001176000000003e244822232b10290000000000271100000000000000000000112400000000000000000000000000000000
26282828393a283824331b00000000002a280000102900001b313300290000003a283924261028003b302b00000039162a3a24262426242600002800003a28282839002c00003b24323320243535353535232b000020242525262b2900000000003a313611111111111111111111212500000000000000000000000000000000
332829000000002a300000000000000000280000280000000000000000000000002a282426292a003b372b0000002a393a1024262426313300002800002800000038003c11003a301a001b302b2a391b3b30003b2123242525262b00760000113a29001b34353535353535352222252500000000000000000000000000000000
23290039000000123000000000212223112828102839000000000000000000000000002426000000001b000016002900000024262425231b00002a3828290020002a28212223293717273a37003b42443a37393b242624252525222222222222360000000000390000001b1b3125252500000000000000000000000000000000
332b3a3828282122260000424424252621222222222339000000000000003a000000002426111100003a28392a10003a383924262448260000001200113f20201100203132333d00003029003b206264291b2a203133242525252525252525260b00003900003800003900000031322500000000000000000000000000000000
44390029003b3132260000626424252631323225252522232b0000002123383900003924252223000038282939283a38282a242631252639000021222222222222222222222222222226127274212222222222222222252532323232323232252300002800002800002800003900003100000000000000000000000000000000
542a39001600002a300000212225254822222331323232332b00003b31323600003a383132323300002929290028002a2a2a24252324262a393a2425254825252525252525252525252522222248252525252525252548262a282828283829242600003800002800002800002800000c00000000000000000000000000000000
54002a39003a39003000003148252532323233002a282900000000000000000000292a292a103900000000003a2a390000002425262426172a292425252525323232323232323248253232252525253232323232323232332b00001a00003b2426003b202b0028003b202b001000002100000000000000000000000000000000
__sfx__
0002000036370234702f3701d4702a37017470273701347023370114701e3700e4701a3600c46016350084401233005420196001960019600196003f6003f6003f6003f6003f6003f6003f6003f6003f6003f600
0002000011070130701a0702407000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000300000d07010070160702207000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000200000642008420094200b420224402a4503c6503b6503b6503965036650326502d6502865024640216401d6401a64016630116300e6300b62007620056100361010600106000060000600006000060000600
000400000f0701e070120702207017070260701b0602c060210503105027040360402b0303a030300203e02035010000000000000000000000000000000000000000000000000000000000000000000000000000
000300000977009770097600975008740077300672005715357003470034700347003470034700347003570035700357003570035700347003470034700337003370033700337000070000700007000070000700
00030000241700e1702d1701617034170201603b160281503f1402f120281101d1101011003110001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100
00020000101101211014110161101a120201202613032140321403410000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100
00030000070700a0700e0701007016070220702f0702f0602c0602c0502f0502f0402c0402c0302f0202f0102c000000000000000000000000000000000000000000000000000000000000000000000000000000
0003000005110071303f6403f6403f6303f6203f6103f6153f6003f6003f600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600
011000200177500605017750170523655017750160500605017750060501705076052365500605017750060501775017050177500605236550177501605006050177500605256050160523655256050177523655
002000001d0401d0401d0301d020180401804018030180201b0301b02022040220461f0351f03016040160401d0401d0401d002130611803018030180021f061240502202016040130201d0401b0221804018040
00100000070700706007050110000707007060030510f0700a0700a0600a0500a0000a0700a0600505005040030700306003000030500c0700c0601105016070160600f071050500a07005050030510a0700a060
000400000c5501c5601057023570195702c5702157037570285703b5702c5703e560315503e540315303e530315203f520315203f520315103f510315103f510315103f510315103f50000500005000050000500
000400002f7402b760267701d7701577015770197701c750177300170015700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700
00030000096450e655066550a6550d6550565511655076550c655046550965511645086350d615006050060500605006050060500605006050060500605006050060500605006050060500605006050060500605
011000001f37518375273752730027300243001d300263002a3001c30019300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300
011000002953429554295741d540225702256018570185701856018500185701856000500165701657216562275142753427554275741f5701f5601f500135201b55135530305602454029570295602257022560
011000200a0700a0500f0710f0500a0600a040110701105007000070001107011050070600704000000000000a0700a0500f0700f0500a0600a0401307113050000000000013070130500f0700f0500000000000
002000002204022030220201b0112404024030270501f0202b0402202027050220202904029030290201601022040220302b0401b030240422403227040180301d0401d0301f0521f0421f0301d0211d0401d030
0108002001770017753f6253b6003c6003b6003f6253160023650236553c600000003f62500000017750170001770017753f6003f6003f625000003f62500000236502365500000000003f625000000000000000
002000200a1400a1300a1201113011120111101b1401b13018152181421813213140131401313013120131100f1400f1300f12011130111201111016142161321315013140131301312013110131101311013100
001000202e750377502e730377302e720377202e71037710227502b750227302b7301d750247501d730247301f750277501f730277301f7202772029750307502973030730297203072029710307102971030710
000600001877035770357703576035750357403573035720357103570000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700
001800202945035710294403571029430377102942037710224503571022440274503c710274403c710274202e450357102e440357102e430377102e420377102e410244402b45035710294503c710294403c710
0018002005570055700557005570055700000005570075700a5700a5700a570000000a570000000a5700357005570055700557000000055700557005570000000a570075700c5700c5700f570000000a57007570
010c00103b6352e6003b625000003b61500000000003360033640336303362033610336103f6003f6150000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000c002024450307102b4503071024440307002b44037700244203a7102b4203a71024410357102b410357101d45033710244503c7101d4403771024440337001d42035700244202e7101d4102e7102441037700
011800200c5700c5600c550000001157011560115500c5000c5700c5600f5710f56013570135600a5700a5600c5700c5600c550000000f5700f5600f550000000a5700a5600a5500f50011570115600a5700a560
001800200c5700c5600c55000000115701156011550000000c5700c5600f5710f56013570135600f5700f5600c5700c5700c5600c5600c5500c5300c5000c5000c5000a5000a5000a50011500115000a5000a500
000c0020247712477024762247523a0103a010187523a0103501035010187523501018750370003700037000227712277222762227001f7711f7721f762247002277122772227620070027771277722776200700
000c0020247712477024762247523a0103a010187503a01035010350101875035010187501870018700007001f7711f7701f7621f7521870000700187511b7002277122770227622275237012370123701237002
000c0000247712477024772247722476224752247422473224722247120070000700007000070000700007002e0002e0002e0102e010350103501033011330102b0102b0102b0102b00030010300123001230012
000c00200c3320c3320c3220c3220c3120c3120c3120c3020c3320c3320c3220c3220c3120c3120c3120c30207332073320732207322073120731207312073020a3320a3320a3220a3220a3120a3120a3120a302
000c00000c3300c3300c3200c3200c3100c3100c3103a0000c3300c3300c3200c3200c3100c3100c3103f0000a3300a3201333013320073300732007310113000a3300a3200a3103c0000f3300f3200f3103a000
00040000336251a605000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005
000c00000c3300c3300c3300c3200c3200c3200c3100c3100c3100c31000000000000000000000000000000000000000000000000000000000000000000000000a3000a3000a3000a3000a3310a3300332103320
001000000c3500c3400c3300c3200f3500f3400f3300f320183501834013350133401835013350163401d36022370223702236022350223402232013300133001830018300133001330016300163001d3001d300
000c0000242752b27530275242652b26530265242552b25530255242452b24530245242352b23530235242252b22530225242152b21530215242052b20530205242052b205302053a2052e205002050020500205
001000102f65501075010753f615010753f6152f65501075010753f615010753f6152f6553f615010753f61500005000050000500005000050000500005000050000500005000050000500005000050000500005
0010000016270162701f2711f2701f2701f270182711827013271132701d2711d270162711627016270162701b2711b2701b2701b270000001b200000001b2000000000000000000000000000000000000000000
00080020245753057524545305451b565275651f5752b5751f5452b5451f5352b5351f5252b5251f5152b5151b575275751b545275451b535275351d575295751d545295451d535295351f5752b5751f5452b545
002000200c2650c2650c2550c2550c2450c2450c2350a2310f2650f2650f2550f2550f2450f2450f2351623113265132651325513255132451324513235132351322507240162701326113250132420f2600f250
00100000072750726507255072450f2650f2550c2750c2650c2550c2450c2350c22507275072650725507245072750726507255072450c2650c25511275112651125511245132651325516275162651625516245
000800201f5702b5701f5402b54018550245501b570275701b540275401857024570185402454018530245301b570275701b540275401d530295301d520295201f5702b5701f5402b5401f5302b5301b55027550
00100020112751126511255112451326513255182751826518255182451d2651d2550f2651824513275162550f2750f2650f2550f2451126511255162751626516255162451b2651b255222751f2451826513235
00100010010752f655010753f6152f6553f615010753f615010753f6152f655010752f6553f615010753f61500005000050000500005000050000500005000050000500005000050000500005000050000500005
001000100107501075010753f6152f6553f6153f61501075010753f615010753f6152f6553f6152f6553f61500005000050000500005000050000500005000050000500005000050000500005000050000500005
002000002904029040290302b031290242b021290142b01133044300412e0442e03030044300302b0412b0302e0442e0402e030300312e024300212e024300212b0442e0412b0342e0212b0442b0402903129022
000800202451524515245252452524535245352454524545245552455524565245652457500505245750050524565005052456500505245550050524555005052454500505245350050524525005052451500505
000800201f5151f5151f5251f5251f5351f5351f5451f5451f5551f5551f5651f5651f575000051f575000051f565000051f565000051f555000051f555000051f545000051f535000051f525000051f51500005
000500000373005731077410c741137511b7612437030371275702e5712437030371275702e5712436030361275602e5612435030351275502e5512434030341275402e5412433030331275202e5212431030311
002000200c2750c2650c2550c2450c2350a2650a2550a2450f2750f2650f2550f2450f2350c2650c2550c2450c2750c2650c2550c2450c2350a2650a2550a2450f2750f2650f2550f2450f235112651125511245
002000001327513265132551324513235112651125511245162751626516255162451623513265132551324513275132651325513245132350f2650f2550f2450c25011231162650f24516272162520c2700c255
000300001f3302b33022530295301f3202b32022520295201f3102b31022510295101f3002b300225002950000000000000000000000000000000000000000000000000000000000000000000000000000000000
000b00002935500300293453037030360303551330524300243050030013305243002430500300003002430024305003000030000300003000030000300003000030000300003000030000300003000030000300
001000003c5753c5453c5353c5253c5153c51537555375453a5753a5553a5453a5353a5253a5253a5153a51535575355553554535545355353553535525355253551535515335753355533545335353352533515
00100000355753555535545355353552535525355153551537555375353357533555335453353533525335253a5753a5453a5353a5253a5153a51533575335553354533545335353353533525335253351533515
001000200c0600c0300c0500c0300c0500c0300c0100c0000c0600c0300c0500c0300c0500c0300c0100f0001106011030110501103011010110000a0600a0300a0500a0300a0500a0300a0500a0300a01000000
001000000506005030050500503005010050000706007030070500703007010000000f0600f0300f010000000c0600c0300c0500c0300c0500c0300c0500c0300c0500c0300c010000000c0600c0300c0100c000
0010000003625246150060503615246251b61522625036150060503615116253361522625006051d6250a61537625186152e6251d615006053761537625186152e6251d61511625036150060503615246251d615
00100020326103261032610326103161031610306102e6102a610256101b610136100f6100d6100c6100c6100c6100c6100c6100f610146101d610246102a6102e61030610316103361033610346103461034610
00400000302453020530235332252b23530205302253020530205302253020530205302153020530205302152b2452b2052b23527225292352b2052b2252b2052b2052b2252b2052b2052b2152b2052b2052b215
000400002f45032450314502e4502f45030450000000000001400264002f45032450314502e4502f4503045030400304000000000000000000000000000000000000000000000000000000000000000000000000
__music__
01 150a5644
00 0a160c44
00 0a160c44
00 0a0b0c44
00 14131244
00 0a160c44
00 0a160c44
02 0a111244
00 41424344
00 41424344
01 18191a44
00 18191a44
00 1c1b1a44
00 1d1b1a44
00 1f211a44
00 1f1a2144
00 1e1a2244
02 201a2444
00 41424344
00 41424344
01 2a272944
00 2a272944
00 2f2b2944
00 2f2b2c44
00 2f2b2944
00 2f2b2c44
00 2e2d3044
00 34312744
02 35322744
00 41424344
01 3d7e4344
00 3d7e4344
00 3d4a4344
02 3d3e4344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
01 383a3c44
02 393b3c44

