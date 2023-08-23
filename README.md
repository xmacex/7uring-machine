# 7uring Machine

A generative sequencer thing. For norns.

![SN74HC163N](lib/sn74hc163n-dithering.gif)

This is a shift register sequencer, a 7-bit norns implementation of the Turing Machine Eurorack module... more-or-less. This is aimed at MIDI, which is 7-bit with values ranging from 0 to 127.

The `p` parameter sets how likely the bit falling out will be inverted before it goes back in the other end. At 0.5 it's uniformly random. At the max value 1 it is never inverted meaning the sequence will loop. At minimum value 0 the bit is always inverted, meaning the loop will be twice as long. Lock the `p` to 1 or 0 catch the sequence and loop it – the Turing Machine way!

The additional parameters define how many bits the shift register contains, and an offset which is added to the register value. The former influences the range of generated sequence, the latter pushes it higher. Everything is exponential in the 0, 1, 2, 4, 8, 16, 32, 64, 128... sequence, because that's how bitshifting kind of works.

There are three output modes; notes of a set length, pulse which gates when the first bit is on, and CC.

## Requirements

- norns
- MIDI device

## Install

For the time being, install with

```
;install https://github.com/xmacex/7uring-machine
```

## Credits

- [Tom Whitwell](https://artmusictech.libsyn.com/podcast-212-tom-whitwell-music-thing) made the original ![Turing Machine](https://github.com/TomWhitwell/TuringMachine) Eurorack module.
- Sound + Voltage for explained to me how the thing works on the video [*Turing 201: Turing Machine Explained (More than you ever needed to know...)*](https://www.youtube.com/watch?v=va2XAdFtmeU).
- Alan Turing for everything

![Sir Alan Turing in Manchester 2018](lib/alan_dithering.gif)

## Roadmap

  * [x] `0` and `1` input
  * [x] Offset
  * [ ] Scaling or is it too normcore?
  * [ ] ![n.b.](https://llllllll.co/t/n-b-et-al-v0-1/60374/) output maybe
  * [ ] Maybe make the UI less obvious
  * [ ] What to do with pulse?
  * [ ] Gates are kind of fun too
  * [ ] Improve everything
