stds.turingmachine = {
   globals = {
      -- Debug tools
      "DEBUG",
      "log",

      -- Core functions
      "init_params",
      "tick",
      "redraw",
      "draw_controls",
      "draw_history",
      "draw_register",
      "run_output",
      "play_note",
      "pulse_on",
      "pulse_off",
      "wiggle_cc",

      -- Utility functions
      "numberToBinStr",
      "boolToNumber",
      "toBits",

      -- Global variables
      "HEIGHT",
      "WIDTH",
      "values",
      "register",
      "pulse_high",
      "pulse_note",
      "midi_dev",

      -- Clocks and metros
      "turing",
      "player",
      "ui_metro"
   }
}

stds.norns = {
   globals = {
      "init",
      "enc"
   },
   read_globals = {
      _menu = {
         fields = {
            "rebuild_params"
         }
      },
      clock = {
         fields = {
            "run",
            "sleep",
            "sync"
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
            "level",
            "line",
            "move",
            "update",
            "stroke"
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
