#!/bin/bash
# ────────────────────────────────────────────
# Bash Tetris
# Controls:
#   A = Move Left
#   D = Move Right
#   S = Drop Piece
#   R = Change Piece Type
#   Q = Quit Game
# ────────────────────────────────────────────

# The number of rows and columns in the game grid.
# Think of this as the "size of the game box".
ROWS=20
COLS=10

# How fast the blocks fall (in seconds).
# Smaller numbers make the game faster!
DELAY=0.08

# Starting score is 0.
SCORE=0

# These are all the 7 Tetris block shapes (tetrominoes).
# Each shape is described as a string of 16 characters (4x4 grid).
# "X" means there is a block there, "." means empty space.
# For example, "..X...X...X...X." is the long straight "I" block.
shapes=(
"..X...X...X...X."    # I shape
"..X..XX...X....."    # T shape
".....XX..XX....."    # O shape (square)
"..X..XX..X......"    # S shape
".X...XX...X....."    # Z shape
".X...X...XX....."    # J shape
"..X...X..XX....."    # L shape
)

# This creates the playing field (the grid where blocks fall).
# Each cell of the grid can be either "." (empty) or "#" (filled).
declare -A board
for ((r=0; r<ROWS; r++)); do
  for ((c=0; c<COLS; c++)); do
    board[$r,$c]="."  # Start with all cells empty
  done
done

# Hide the blinking cursor and turn off normal keyboard input
# so that the game can read single key presses smoothly.
tput civis
stty -echo -icanon time 0 min 0

# ────────────────────────────────────────────
# draw_frame(): Draws the outer box and text around the board
# This only runs once at the start.
draw_frame() {
  clear
  echo "         Bash Tetris "
  echo "   ───────────────────────"
  echo "   Score: $SCORE"
  echo "   ───────────────────────"
  echo

  # Draw the sides of the board using "|"
  for ((r=0; r<ROWS; r++)); do
    echo -n "   |"
    for ((c=0; c<COLS; c++)); do echo -n " "; done
    echo "|"
  done

  # Draw the bottom border
  echo "   ───────────────────────"

  # Show control instructions at the bottom
  echo "   A=Left | D=Right | S=Drop | R=Change Block | Q=Quit"
}

# ────────────────────────────────────────────
# draw_board(): Draws the blocks that are already placed (not falling)
draw_board() {
  for ((r=0; r<ROWS; r++)); do
    # Move the cursor to the correct line and column
    tput cup $((r+5)) 4
    for ((c=0; c<COLS; c++)); do
      # Print "#" if filled, or a blank space if empty
      [[ ${board[$r,$c]} == "#" ]] && echo -n "#" || echo -n " "
    done
  done
}

# ────────────────────────────────────────────
# draw_piece(): Draws the current falling block
# It uses the piece pattern, its row, and column position.
draw_piece() {
  local piece="$1" row="$2" col="$3"
  local i=0
  for ((y=0; y<4; y++)); do
    for ((x=0; x<4; x++)); do
      ch=${piece:$i:1}; ((i++))
      # Only draw where the piece has an "X"
      if [[ $ch == "X" || $ch == "#" ]]; then
        ((ry=row+y, cx=col+x))
        # Only draw if inside the board boundaries
        ((ry>=0 && ry<ROWS && cx>=0 && cx<COLS)) || continue
        tput cup $((ry+5)) $((cx+4))
        echo -n "#"
      fi
    done
  done
}

# ────────────────────────────────────────────
# collision(): Checks if a block has hit something (bottom or another block)
# Returns 0 if there is a collision, 1 if not.
collision() {
  local piece="$1" row="$2" col="$3"
  local i=0
  for ((y=0; y<4; y++)); do
    for ((x=0; x<4; x++)); do
      ch=${piece:$i:1}; ((i++))
      if [[ $ch == "X" || $ch == "#" ]]; then
        ((r=row+y, c=col+x))
        # If it touches bottom, wall, or another block
        if ((r>=ROWS || c<0 || c>=COLS)) || [[ ${board[$r,$c]} == "#" ]]; then
          return 0
        fi
      fi
    done
  done
  return 1
}

# ────────────────────────────────────────────
# fix_piece(): When a falling piece lands, this "glues" it to the board
fix_piece() {
  local piece="$1" row="$2" col="$3" i=0
  for ((y=0; y<4; y++)); do
    for ((x=0; x<4; x++)); do
      ch=${piece:$i:1}; ((i++))
      # Convert the falling piece to a permanent block "#"
      [[ $ch == "X" || $ch == "#" ]] && board[$((row+y)),$((col+x))]="#"
    done
  done
}

# ────────────────────────────────────────────
# clear_lines(): Checks each row.
# If the row is completely filled, it removes it and adds points!
clear_lines() {
  local lines=0
  for ((r=ROWS-1; r>=0; r--)); do
    full=1
    # Check if the row has any empty cell
    for ((c=0; c<COLS; c++)); do [[ ${board[$r,$c]} == "." ]] && full=0; done
    if ((full)); then
      ((lines++))
      # Move everything above this row down by one
      for ((y=r; y>0; y--)); do
        for ((x=0; x<COLS; x++)); do board[$y,$x]=${board[$((y-1)),$x]}; done
      done
      # Top row becomes empty again
      for ((x=0; x<COLS; x++)); do board[0,$x]="."; done
      ((r++))  # Re-check this row
    fi
  done
  # Add score (100 points per cleared line)
  ((SCORE+=lines*100))
  # Update the score display on screen
  tput cup 2 10; echo -n "$SCORE   "
}

# ────────────────────────────────────────────
# check_game_over(): Ends the game if the top row has any blocks
check_game_over() {
  for ((c=0; c<COLS; c++)); do
    [[ ${board[0,$c]} == "#" ]] && {
      # If top is filled → Game Over!
      tput cnorm; stty echo; clear
      echo "GAME OVER — Final Score: $SCORE"
      exit 0
    }
  done
}

# ────────────────────────────────────────────
# game_loop(): The main "heartbeat" of the game.
# This runs forever until you quit or lose.
game_loop() {
  local key piece row col shapeIndex

  while true; do
    # Pick a random shape from the list (like a new falling piece)
    shapeIndex=$((RANDOM % ${#shapes[@]}))
    piece=${shapes[$shapeIndex]}

    # Start the piece at the top middle of the board
    row=0
    col=$((COLS/2 - 2))

    # If the piece can’t even start (the top is full) → Game Over
    collision "$piece" $row $col && {
      tput cnorm; stty echo; clear
      echo "GAME OVER — Final Score: $SCORE"
      exit 0
    }

    # Keep moving the current piece down until it lands
    while true; do
      draw_board       # Draw all placed blocks
      draw_piece "$piece" "$row" "$col"  # Draw the falling piece

      # Quickly check keys multiple times per frame for smoother controls
      for ((i=0; i<5; i++)); do
        read -sn1 -t 0.01 key
        case "$key" in
          a|A)  # Move left
            ((col--))
            collision "$piece" "$row" "$col" && ((col++))
            ;;
          d|D)  # Move right
            ((col++))
            collision "$piece" "$row" "$col" && ((col--))
            ;;
          s|S)  # Drop all the way down
            while true; do
              ((row++))
              collision "$piece" "$row" "$col" && { ((row--)); break; }
            done
            ;;
          r|R)  # Change to next block type
            ((shapeIndex=(shapeIndex+1)%${#shapes[@]}))
            piece=${shapes[$shapeIndex]}
            ;;
          q|Q)  # Quit the game
            tput cnorm; stty echo; clear
            echo "Game Over — Final Score: $SCORE"
            exit
            ;;
        esac
      done

      # Make the piece fall one step automatically
      ((row++))

      # If it hits something, stick it to the board
      if collision "$piece" "$row" "$col"; then
        ((row--))
        fix_piece "$piece" "$row" "$col"
        clear_lines
        check_game_over
        break
      fi

      # Wait a tiny bit before repeating (controls game speed)
      sleep $DELAY
    done
  done
}

# ────────────────────────────────────────────
# Start the game by drawing the frame and entering the main loop
draw_frame
game_loop
