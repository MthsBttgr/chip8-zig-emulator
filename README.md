# Chip8 Zig Emulator:
This is a chip8 emulator written in zig using raylib:

![billede](https://github.com/user-attachments/assets/09968250-4190-429b-8984-8a560cd2a007)

## Building and Running
To build and run the emulator, clone the repository and inside the directory run: 
```
zig build run --release=fast
```

## Game Controls
The original chip8 4x4 keypad has been mapped to the following keys:

![40276007-26e1efd6-5bcd-11e8-8e4b-b615659797ee](https://github.com/user-attachments/assets/a2e32e0e-80c4-489f-9bc5-b9a412e70474)

## Sound
Sound isn't emulated at the current moment. Perhaps i will implement in a future edition.

## Gui Overview
### Game Screen and Playback Controls
In the middle is the game screen. This is where you will the see the game you are playing or program being executed.
At the top of the game screen are the playback controls. Current game can be paused by pressing the button or space key. 
While paused the current game/program can be "stepped through" one instruction at a time, but more on that later.
Other than those there is the reset button which, as the name suggests, resets the game. The whole program is reread from the file, in case the program memory got corrupted during execution.
![billede](https://github.com/user-attachments/assets/9eb6caa7-9187-4f6d-a93b-6a0978e158bf)

### Code view
To the right of the game screen you will find the code view. This is just a long list of the bytes as they are layed out in memory. 
By default, the codeview is focused on where the program counter is set to inside the chip8. That instruction is highlighted in blue.
Tracking the program counter can be disabled by pressing the checkbox in the lower right corner.
The program counter can be focused again by pressing the checkbox or, if you just wanna find the program counter but not lock on to it, you can just press the "Find Current PC" button.

![billede](https://github.com/user-attachments/assets/6d4b7049-f670-448d-bf91-70da2de2cd2d)

### Registers
The Chip8 has 16 registers, these are displayed under the gamescreen aswell as the sound-timer and delay-timer. 
![billede](https://github.com/user-attachments/assets/9a492fa7-cead-4f80-a36d-35f2082657c0)

### Special Registers
In the bottom left, the program counter, the I register, and a message showing what the last instruction was are displayed. (Sometimes the message is too large to fit in its box. In that case, hower over the message with the mouse, and it will expand to show the full message)

![billede](https://github.com/user-attachments/assets/0c27988e-eebb-4774-866b-5dd41f34c2e5)

### Settings
Settings for the emulator are found to the left of the gamescreen. There are display settings for the emulator. For example if a grid should be overlaid the gamescreen, or if the fps should be shown. 
However, there are also settings that manipulate how certain instructions should be executed since different Chip8 iterations have had small differences. It is up to the user to enable/disable these to get correct execution of different programs.
The default settings are how the original Cosmac VIP did it.
By hovering over each setting a tooltip will be displayed that explains in more detail.

![billede](https://github.com/user-attachments/assets/646f21eb-535c-4134-be27-d4b0f00b9022)


### Filepicker
There is a filepicker in the top left of the emulator. Using this filepicker you can load chip8 roms that are placed in the working directory or navigate to it in subdirectories.

![billede](https://github.com/user-attachments/assets/8f938751-43ac-4542-8766-e2ee1a88d872)

## Step Through Emulation
As mentioned previously, by pausing emulation, it is possible to go through the current game/program on instruction at a time. You can step forward or backwards by pressing the buttons in the playbar, or by using the arrow keys.
In Step through mode, the state of the chip8 is saved for each instruction. This enables stepping forwards and backwards. However, state isn't saved during normal execution. 
This means you cant step back to instructions that were executed before entering stepthrough mode. 
Another limitation is that the chip8 memory isnt saved for each instruction, since that would get very heavy very quickly. Therefore the codeview can't necessarily be trusted to display accurate data for each step.
If an instruction were to manipulate memory, this would not be reflected during step through.
Code view is by default disabled in step-through emulation for this reason, but can be enabled in settings.
