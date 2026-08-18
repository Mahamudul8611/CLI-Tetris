#CLI Tetris 🎮

A classic Tetris game that runs entirely in your terminal, built with pure Bash — no external libraries, no compiling, just a single script.

Show Image Show Image Show Image

#Features

Full 10×20 Tetris playing field
All 7 classic tetrominoes (I, T, O, S, Z, J, L)
Real-time falling pieces with smooth keyboard controls
Line clearing with scoring (100 points per line)
Game-over detection when the stack reaches the top
Runs anywhere Bash runs — no dependencies required
Requirements

This is a Bash script, so it needs a Bash-compatible terminal environment. It relies on tput and stty, which are standard on Linux and macOS but are not native to Windows.

#Platform	Requirement

Linux	Bash 4+ (pre-installed on almost all distros)
macOS	Bash (pre-installed) or brew install bash for a newer version
Windows	WSL (Windows Subsystem for Linux) or Git Bash — see below

Note on Windows: Once WSL is installed, you can run the script directly from PowerShell — no need to switch terminals.

#Installation

Clone the repository:

bash
   git clone https://github.com/<your-username>/bash-tetris.git
   cd bash-tetris
   
Make the script executable (Linux/macOS/WSL):
bash
   chmod +x tetris.bash
   
#Usage

Linux / macOS
bash
./tetris.bash

or, without setting the executable bit:

bash
bash tetris.bash

#Windows

Install WSL if you haven't already (one-time setup, run in PowerShell as Administrator):
powershell
   wsl --install
Once WSL is set up, just run the script straight from PowerShell:
powershell
   wsl bash ./tetris.bash
   
#Controls

Key	Action
A	Move piece left
D	Move piece right
S	Drop piece instantly
R	Cycle to next piece type
Q	Quit the game

#Gameplay Notes

The game runs in an infinite loop, continuously spawning new pieces after each one lands.
When a piece can no longer spawn (the top row is blocked), the game ends automatically and prints your final score.
This is a single-run game — once it's over, the script exits back to your shell. To play again, simply re-run the command:
bash
  ./tetris.bash
  
#How It Works (Under the Hood)

Board state: stored in an associative array board[row,col], where each cell is . (empty) or # (filled).
Pieces: each of the 7 tetrominoes is encoded as a 16-character string representing a 4×4 grid (X = block, . = empty).
Rendering: uses tput cup to move the cursor and redraw only the necessary parts of the screen each frame, avoiding full-screen flicker.
Input: stty -echo -icanon puts the terminal into raw mode so single key presses can be read instantly without requiring Enter.
Game loop: on each tick, the script checks for keypresses, moves the piece down, checks for collisions, and locks the piece in place when it lands — then checks for completed lines and game-over conditions.

#Project Structure

bash-tetris/
├── tetris.bash    # The entire game — single-file, no dependencies
└── README.md      # This file

#Known Limitations

No piece rotation (only a "change piece type" key, R, is implemented instead of true rotation)
No hold/next-piece preview
Score is not persisted between runs
Requires a terminal that supports ANSI cursor positioning (tput)
Contributing

Pull requests are welcome! Feel free to open an issue if you'd like to suggest features such as real rotation, hold queue, or a next-piece preview.

#License

This project is licensed under the GNU General Public License version 3 (GPL 3.0) License — feel free to use, modify, and share it.
