-- 7 bit turing machine.
--
-- E1 for p
-- E2 adjust bits, E3 offset
-- K2 write a 0, K3 a 1
--
-- By xmacex, Tom Whitwell's
-- successful TM concept.

DEBUG = false

ui = require "ui"

local WIDTH = 128
local HEIGHT = 64

local values = {0,0}
local TAB_WIDTH = WIDTH/8
local register = 0
local turing = nil
local player = nil
local pulse_high = 0
local pulse_note = nil

local p_dial = ui.Dial.new(
   0, HEIGHT/2-10, 20,
   0.5, 0, 1,
   0.01, 0.5, {}, "", "p")

local midi_dev = nil

function init()
   init_params()

   -- Hook to transport
   clock.transport.start = start
   clock.transport.stop = stop

   start()

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
   params:add_control('p', "p", controlspec.new(0, 1.0,'lin', 0.01, 0.5))
   params:set_action('p', function(p) p_dial:set_value(p) end)
   params:add_number('bits', "bits", 1, 7, 7)
   params:add_number('offset', "offset mask", 0, 6, 0)

   params:add_separator("MIDI output")
   params:add_number('midi_dev', "dev", 1, 16, 1)
   params:set_action('midi_dev', function(d) midi_dev = midi.connect(d) end)
   params:add_number('midi_ch', "channel", 1, 16, 1)
   params:add_option('midi_type', "output", {"note", "pulse note", "cc"}, 1)
   params:add_control('note_len', "note length", controlspec.new(0.05, 1, 'lin', 0.01, 0.1, "sec"))
   params:add_number('midi_cc', "cc", 1, 128, 71)  -- Would use controlspec.MIDI but it's not integers
   params:hide('midi_cc')
   params:set_action('midi_type', function(d)
			all_notes_off(params:get('midi_ch'))
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

-- Shift register

function tick()
   while true do
      clock.sync(1/4)
      -- Grab the bit which is falling out.
      local output_mask = (1<<1)-1
      local output=register&output_mask

      -- Maybe invert. Always inverting -> double the length repeating pattern.
      if math.random() > params:get('p') then -- TODO: Which way is it on orig. TM?
         output = output~1             -- is this legit bitwise?
      end

      -- Place the output into the input, and truncate the bitstring at the end.
      register=(register>>1)|(output<<(params:get('bits')-1))

      -- Store in our nice table.
      local offset_value = register + (1<<params:get('offset'))-1 -- TODO: bitwise

      if #values >= TAB_WIDTH then
         table.remove(values, 1)
      end
      table.insert(values, offset_value)

      if DEBUG then             -- Erm why is this inside debug?
         if register >= 2^params:get('bits') then register = 0 end
      end

      -- Pulse FIXME this is out of line as event-based, re-align with the other types.
      if params:get('midi_type') == 2 then
         if output == 1 and pulse_high == 0 then -- Pulse came up
            pulse_on()
         elseif output == 0 and pulse_high == 1 then -- Pulse came down
            pulse_off()
         end
         pulse_high = output
      end
   end
end

-- Get the register will offset etc. shenanigans applied
function get_offset_register()
   local value = register + (1<<params:get('offset'))-1 -- TODO: bitwise
   return value
end

-- End of shift register

-- Screen drawing

function redraw()
   screen.clear()
   draw_history()
   draw_register()
   draw_offset()
   draw_controls()
   screen.update()
end

function draw_history()
   local xres=WIDTH/TAB_WIDTH
   screen.line_width(6)
   screen.line_cap("round")
   screen.level(3)
   for i, val in pairs(values) do
      -- Let's use bitwise operations for screen drawing too.
      screen.move(i*xres, HEIGHT-(val>>1))
      if i>2 then
         screen.line((i-1)*xres, HEIGHT-(values[i-1]>>1))
      end
   end
   screen.stroke()
   screen.line_width(1)
end

function draw_register()
   local radius = 3
   -- for i,v in ipairs(toBits(register, params:get('bits'))) do
   for i,v in ipairs(toBits(register, 7)) do
      -- screen.move(10 + i*radius*2 + i, 10)
      local x = 10+i*radius*2+i
      local y = 10
      if 7-i < params:get('bits') then
         screen.level(8)
      else
         screen.level(1)
      end

      if v == 0 then
	 screen.circle(x, y, radius)
	 screen.stroke()
      else
	 screen.circle(x, y, radius)
	 screen.fill()
      end
   end
end

function draw_offset()
   local radius = 3
   screen.level(8)
   for i,v in ipairs(toBits(1<<params:get('offset')-1, 7)) do
      local x = 10+i*radius*2+i
      local y = 20
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
   screen.font_face(1<<4)
   screen.level(8)
   p_dial:redraw()
   if norns.is_shield then
      screen.move(0, HEIGHT)
      screen.text(0)
      screen.move(28, HEIGHT)
      screen.text(1)
  end
end

-- End of drawing functions

-- Interactions. TODO split to files/libs

function enc(n, d)
   if n == 1 then
      params:delta('p', d)
   elseif n == 2 then
      params:delta('bits', d)
   elseif n == 3 then
      params:delta('offset', d)
   end
end

function key(n, z)
   if n == 2 and z == 1 then
      -- Set MSB as 0
      register = register>>1
   elseif n == 3 and z == 1 then
      -- Set MSB as 1
      register = register|(1<<params:get('bits'))
   end
end

function start()
   turing = clock.run(tick)
   player = clock.run(run_output)
end

function stop()
   clock.cancel(turing)
   clock.cancel(player)
end

-- End of screen drawing

-- Output

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
      local note = get_offset_register()
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
   local pulse_note = get_offset_register()
   midi_dev:note_on(pulse_note, 100, params:get('midi_ch'))
   -- log("Pulse "..pulse_note.." on")
end

function pulse_off()
   midi_dev:note_off(pulse_note, 0, params:get('midi_ch'))
   -- log("Pulse "..pulse_note.." off")
end

function wiggle_cc()
   if midi_dev then
      local val = get_offset_register()
      midi_dev:cc(params:get('midi_cc'), val, params:get('midi_ch'))
   end
end

-- End of output

-- Utilities

function all_notes_off(ch)
   if midi_dev then
      log("silencing "..midi_dev.name.." ch "..ch)
      midi_dev:cc(123, 0, ch)
      for n=0,127,1 do
	 midi_dev:note_off(n, 0, ch)
      end
   end
end

function boolToNumber(value)
   return value and 1 or 0
end

function log(s)
   if DEBUG then print(s) end
end

-- From https://gist.github.com/lexnewgate/28663fecae78324a87f38aa9c2e0a293
function numberToBinStr(x)
   local ret=""
   while x~=1 and x~=0 do
      ret=tostring(x%2)..ret
      x=math.modf(x/2)
   end
   ret=tostring(x)..ret
   return ret
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

-- End of utilities

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
-- End of sketch ares
