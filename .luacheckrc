stds.turingmachine = {
   globals = {
      -- Debug tools
      "DEBUG",
      "log",

      -- Core functions
      "init_params",
      "tick",
      "redraw",
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
   },
   read_globals = {
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
            "MIDI"
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
            "line",
            "move",
            "update"
         }
      }
   }
}

std = "lua54+norns+turingmachine"
