-- Turing machine

DEBUG = true

WIDTH = 256
HEIGHT = 128

values = {0,0}
register = 0

midi_dev = nil

function init()
   init_params()
   metro.new()

   turing_metro = metro.init(tick, 1/6)
   turing_metro:start()

   ui_metro = metro.init(redraw, 1/10)
   ui_metro:start()

   player = clock.run(run_output)
end

function init_params()
   params:add_number('bits', "bits", 1, 8, 8)
   params:add_control('p', "p", controlspec.new(0, 1.0,'lin', 0.01, 0.5))
   params:add_control('offset', "offset", controlspec.new(0.0, 1.0,'lin', 0.01, 0))
   params:add_control('scaling', "scaling", controlspec.new(0.0, 1.0,'lin', 0.01, 0.20))

   params:add_separator("MIDI output")
   params:add_control('note_len', "note length", controlspec.new(0.05, 1, 'lin', 0.01, 0.1, "sec"))
   params:add_number('midi_dev', "dev", 1, 16, 1)
   params:set_action('midi_dev', function(d) midi_dev = midi.connect_output(d) end)
   params:add_number('midi_ch', "channel", 1, 16, 1)
   params:add_option('midi_type', "output", {"note", "cc"}, 1)
   -- --  FIXME: Would toggle visibility... needs
   -- --  _menu.rebuild_params() which I don't think
   -- --  is implemented on seamstress
   -- params:set_action('midi_type', function(d)
   --                      if d == 1 then -- note
   --                         params:hide('midi_cc')
   --                         params:show('note_len')
   --                      elseif d == 2 -- cc
   --                         params:hide('note_len')
   --                         params:show('midi_cc')
   --                      end
   --                     _menu:rebuild_params()
   -- end)
   -- params:add_control('midi_cc', "cc", controlspec.MIDI) -- Want integers tho
   params:add_number('midi_cc', "cc", 1, 128, 71)
   -- -- params:hide('midi_cc')

   params:bang()
end

function tick()
   -- mask = 1
   -- -- Incrementing works
   -- while (register&mask) ~= 0 do -- TODO: Can this be bitwise?
   --    register = register&(~mask)
   --    mask = mask << 1
   -- end
   -- if math.random() < params:get('p') then
   --    register = register|mask
   -- else
   --    register = register|((mask<<1)&1)
   -- end

   -- Grab the bit which is falling out.
   output_mask = (1<<1)-1
   output=register&output_mask

   -- Maybe invert. Always inverting -> double the length repeating pattern.
   if math.random() < params:get('p') then -- TODO: Which way is it on orig. TM?
      output = output~1             -- is this legit bitwise?
   end

   -- Place the output into the input, and truncate the bitstring at the end.
   register=(register>>1)|(output<<(params:get('bits')-1))

   -- Store in our nice table.
   if #values > WIDTH then
      table.remove(values, 1)
   end
   scaled_value = (2^params:get('bits') * params:get('offset'))
      + register*params:get('scaling')
   -- table.insert(values, (params:get('offset'))
   --              +((2^params:get('bits'))*params:get('scaling'))) -- TODO: Scale at output maybe? No, these are historical values for drawing.
   table.insert(values, scaled_value)
   if DEBUG then
      if register >= 2^params:get('bits') then register = 0 end
   end
   -- log(register..": "..numberToBinStr(register))
end

function redraw()
   screen.clear()
   screen.color(255, 255, 0)
   screen_scale = HEIGHT / (2^8)
   for i, val in pairs(values) do
      screen.move(i, HEIGHT-val)
      if i>2 then
         screen.line(i-1, HEIGHT-values[i-1])
      end
   end
   screen.refresh()
end

function run_output()
   while true do
      clock.sync(1/4)
      if params:get('midi_type') == 1 then
         play_note()
      elseif params:get('midi_type') == 2 then
         wiggle_cc()
      end
   end
end

function play_note()
   if midi_dev then
      -- TODO: MIDI is 7 bit
      note = math.floor(((2^params:get('bits'))*params:get('offset'))
         + (register*params:get('scaling')))
      midi_dev:note_on(note, abs_amp, params:get('midi_ch'))
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
   ret=""
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
