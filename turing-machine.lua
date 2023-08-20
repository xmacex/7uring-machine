-- Turing machine.
-- The norns version.
--
-- xmacex

DEBUG = true

ui = require "ui"

local WIDTH = 128
local HEIGHT = 64

if DEBUG then
  values = {0,0}
else
  local values = {0,0}
end
local TAB_WIDTH = WIDTH/8
local register = 0
local pulse_high = 0
local pulse_note = nil

-- UI.Dial.new (x, y, size, value, min_value, max_value, rounding, start_value, markers, units, title)
p_dial       = ui.Dial.new(0, HEIGHT/2, 20, 0.5, 0, 1, 0.01, 0.5, {}, "", "p")
scaling_dial = ui.Dial.new(p_dial.x + p_dial.size+5, p_dial.y+p_dial.size/2, 10, 0.2, 0, 1, 0.01, 1, {}, "", "s")

local midi_dev = nil

function init()
   init_params()

   turing = clock.run(tick)
   player = clock.run(run_output)

   -- TODO: what is a good norns pattern for UI update?
   clock.run(
      function()
	 while true do
	    clock.sleep(1/TAB_WIDTH)
	    redraw()
	 end
   end)
end

function init_params()
   params:add_number('bits', "bits", 1, 8, 8)
   params:add_control('p', "p", controlspec.new(0, 1.0,'lin', 0.01, 0.5))
   params:set_action('p', function(p) p_dial:set_value(p) end)
   params:add_control('offset', "offset", controlspec.new(0.0, 1.0,'lin', 0.01, 0))
   params:add_control('scaling', "scaling", controlspec.new(0.0, 1.0,'lin', 0.01, 0.20))
   params:set_action('scaling', function(p) scaling_dial:set_value(p) end)

   params:add_separator("MIDI output")
   params:add_option('midi_type', "output", {"note", "pulse note", "cc"}, 1)
   params:add_control('midi_cc', "cc", controlspec.MIDI) -- Want integers tho
   params:add_number('midi_dev', "dev", 1, 16, 1)
   params:set_action('midi_dev', function(d) midi_dev = midi.connect(d) end)
   params:add_number('midi_ch', "channel", 1, 16, 1)
   params:add_control('note_len', "note length", controlspec.new(0.05, 1, 'lin', 0.01, 0.1, "sec"))
   params:hide('midi_cc')
   params:add_number('midi_cc', "cc", 1, 128, 71)
   params:hide('midi_cc')
   params:set_action('midi_type', function(d)
                        if d == 1 then -- note
                           params:hide('midi_cc')
                           params:show('note_len')
                        elseif d == 2 then -- pulse
                           params:hide('midi_cc')
                           params:hide('note_len')
                        elseif d == 3 then -- cc
                           params:hide('note_len')
                           params:show('midi_cc')
                        end
			_menu:rebuild_params()
   end)

   params:bang()
end

function tick()
   while true do
      clock.sync(1/4)
      -- Grab the bit which is falling out.
      local output_mask = (1<<1)-1
      local output=register&output_mask

      -- Maybe invert. Always inverting -> double the length repeating pattern.
      if math.random() < params:get('p') then -- TODO: Which way is it on orig. TM?
         output = output~1             -- is this legit bitwise?
      end

      -- Place the output into the input, and truncate the bitstring at the end.
      register=(register>>1)|(output<<(params:get('bits')-1))

      -- Store in our nice table.
      if #values > TAB_WIDTH then
         table.remove(values, 1)
      end
      local scaled_value = (2^params:get('bits') * params:get('offset'))
         + register*params:get('scaling')
      -- table.insert(values, (params:get('offset'))
      --              +((2^params:get('bits'))*params:get('scaling'))) -- TODO: Scale at output maybe? No, these are historical values for drawing.
      table.insert(values, scaled_value)
      if DEBUG then
         if register >= 2^params:get('bits') then register = 0 end
      end
      -- log(register..": "..numberToBinStr(register))

      -- Pulse
      if output==1 and pulse_high==0 then -- Pulse came up
         pulse_on()
      elseif output==0 and pulse_high==1 then     -- Pulse came down
         pulse_off()
      end
      pulse_high = output
   end
end

function redraw()
   screen.clear()
   draw_history()
   draw_register()
   draw_controls()
   screen.update()
end

function draw_history()
   local xres=WIDTH/TAB_WIDTH
   local yres=HEIGHT/128
   screen.level(1)
   for i, val in pairs(values) do
      -- Let's use bitwise operations for screen drawing too.
      screen.move(i*xres, (HEIGHT-(math.floor(val)>>2)))
      if i>2 then
         -- screen.line(i, HEIGHT-val, i-1, HEIGHT-values[i-1])
	       -- screen.line((i-1)*xres, (HEIGHT-values[i-1])*yres)
	       screen.line((i-1)*xres, (HEIGHT-(math.floor(values[i-1])>>2)))
      end
   end
   screen.stroke()
end

function draw_register()
   local radius = 3
   -- screen.move(WIDTH/2-radius*params:get('bits'), 10)
   -- screen.text(register)
   screen.level(8)
   for i,v in ipairs(toBits(register, params:get('bits'))) do
      -- screen.move(10 + i*radius*2 + i, 10)
      local x = 10+i*radius*2+i
      local y = 10
      if v == 0 then
	 screen.circle(x, y, radius)
	 screen.stroke()
      else
	 screen.circle(x, y, radius)
	 screen.fill()
      end
   end
end

function draw_controls()
  screen.level(8)
  p_dial:redraw()
  scaling_dial:redraw()
end

-- Interactions. TODO split to files/libs

function enc(n, d)
   if n == 2 then
      local old_p = params:get('p')
      params:delta('p', d)
   elseif n == 3 then
      local old_p = params:get('scaling')
      params:delta('scaling', d)
   end
end

-- End of interactions

function run_output()
   while true do
      clock.sync(1/4)
      if params:get('midi_type') == 1 then
         play_note()
      elseif params:get('midi_type') == 2 then
         -- pulse() -- This is done event-based lol
      elseif params:get('midi_type') == 3 then
         wiggle_cc()
      end
   end
end

function play_note()
   if midi_dev then
      -- TODO: MIDI is 7 bit
      local note = math.floor(((2^params:get('bits'))*params:get('offset'))
         + (register*params:get('scaling')))
      midi_dev:note_on(note, 100, params:get('midi_ch'))
      -- note management routine from @dan_derks at
      -- https://llllllll.co/t/norns-midi-note-on-note-off-management/35905/5?u=xmacex
      clock.run(
         function()
            clock.sleep(params:get('note_len'))
            midi_dev:note_off(note, 0, params:get('midi_ch'))
         end
      )
   end
end

function pulse_on()
   local pulse_note = math.floor(((2^params:get('bits'))*params:get('offset'))
      + (register*params:get('scaling')))
   midi_dev:note_on(pulse_note, 100, params:get('midi_ch'))
   -- log("Pulse "..pulse_note.." on")
end

function pulse_off()
   midi_dev:note_off(pulse_note, 0, params:get('midi_ch'))
   -- log("Pulse "..pulse_note.." off")
end

function wiggle_cc()
   if midi_dev then
      -- TODO: MIDI is 7 bit
      local val = math.floor((2*params:get('bits')*params:get('offset'))
         +(register*params:get('scaling')))
      midi_dev:cc(params:get('midi_cc'), val, params:get('midi_ch'))
   end
end

-- https://gist.github.com/lexnewgate/28663fecae78324a87f38aa9c2e0a293
function numberToBinStr(x)
   local ret=""
   while x~=1 and x~=0 do
      ret=tostring(x%2)..ret
      x=math.modf(x/2)
   end
   ret=tostring(x)..ret
   return ret
end

function boolToNumber(value)
   return value and 1 or 0
end

function log(s)
   if DEBUG then print(s) end
end

-- From https://stackoverflow.com/a/9080080
function toBits(num,bits)
   -- returns a table of bits, most significant first.
   bits = bits or math.max(1, select(2, math.frexp(num)))
   local t = {} -- will contain the bits
   for b = bits, 1, -1 do
      t[b] = math.fmod(num, 2)
      num = math.floor((num - t[b]) / 2)
   end
   return t
end

-- Sketch area

-- bits = 4
-- for i=0,2^bits*2-1,1 do
--    o=i&output_mask
--    n=(i>>1)|(o<<(bits-1))
--    n = math.floor(n%(2^bits-1))
--    print(i.."="..numberToBinStr(i).." out="..o.. " next="..numberToBinStr(n))
-- end

-- bits=4
-- register = 11
-- for round=0,20,1 do
--    o=register&output_mask
--    register=(register>>1)|(o<<(bits-1))
--    -- register = math.floor(register%(2^bits-1))
--    print(numberToBinStr(register))
-- end

-- -- Incrementing works
-- mask = 1
-- while (register&mask) ~= 0 do -- TODO: Can this be bitwise?
--    register = register&(~mask)
--    mask = mask << 1
-- end
-- if math.random() < params:get('p') then
--    register = register|mask
-- else
--    register = register|((mask<<1)&1)
-- end
