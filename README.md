# 2048ai
Implementation of a software to find and evaluate strategies for the 2048 game

# Contents

## game_server.rb
The game server serves games (how unobvious).
You can start it from shell with an optional port argument, else it will bind to tcp://*:5555.
After binding to the socket and creating the game's board, the game server will listen to incoming requests.
If the request is a valid direction, the movement is performed on the board and the resulting board is replied along with the score and the points gathered during the last move.

Use a ZeroMQ REQ socket to communicate with the game server and send it strings "up", "down", "left" or "right".

## player.rb
The player starts a game server, connects to it and starts to play, with random moves.
This player keeps playing forever and ever and ever and ever.
The player will contain the decision making logic.
You can start the player in the shell with an optional host and port option, else it will connect to tcp://localhost:5555.

## board.rb, array.rb
Contains the game's board and some monkey patches for Array.
