stds.turingmachine = {
   globals = {
      -- Debug tools
      "DEBUG",
      "log",

      -- Core functions
      "all_notes_off",
      "draw_controls",
      "draw_history",
      "draw_register",
      "draw_offset",
      "get_offset_register",
      "init_params",
      "play_note",
      "pulse_off",
      "pulse_on",
      "redraw",
      "run_output",
      "start",
      "stop",
      "tick",
      "wiggle_cc",

      -- Utility function
      "boolToNumber",
      "numberToBinStr",
      "toBits",

      -- Global variables
      "HEIGHT",
      "WIDTH",
      "midi_dev",
      "pulse_high",
      "pulse_note",
      "register",
      "values",

      -- Clocks and metros
      "player",
      "turing",
      "ui_metro"
   }
}

stds.norns = {
   globals = {
      "init",
      "enc",
      "key"
   },
   read_globals = {
      _menu = {
         fields = {
            "rebuild_params"
         }
      },
      clock = {
         fields = {
            "cancel",
            "run",
            "sleep",
            "sync",
            transport = {
               fields = {
                  "start",
                  "stop",
               }
            }
         }
      },
      controlspec = {
         fields = {
            "new",
            "MIDI",
            "MIDINOTE"
         }
      },
      metro = {
         fields = {
            "init"
         }
      },
      midi = {
         fields = {
            "cc",
            "connect",
            "note_on",
            "note_off"
         }
      },
      params = {
         fields = {
            "add_number",
            "add_control",
            "add_option",
            "add_separator",
            "bang",
            "delta",
            "hide",
            "get",
            "set",
            "set_action",
            "show",
         }
      },
      screen = {
         fields = {
            "circle",
            "clear",
            "color",
            "fill",
            "font_face",
            "level",
            "line",
            "line_cap",
            "line_width",
            "move",
            "stroke",
            "text",
            "update",
         }
      },
      ui = {
         Dial = {
            fields = {
               "new"
            }
         }
      }
   }
}

std = "lua51+norns+turingmachine"

-- Local Variables:
-- mode: lua
-- End:
