# 2048ai
Implementation of a software to find and evaluate strategies for the 2048 game

# Contents

## lib2048

Contains all the ruby modules.

- game.rb
- ai.rb
- processes.rb

## tests

Contains all the tests.

## game_server.

The game server requests clients to make the next move on a 2048 board.
The game server is a tcp interface for the Board object.

```Usage: game_server [options]
    -p, --port PORT                  Server port
    -h, --help                       Print this help
```

## game_client

The game client communicates with a game server, sending commands like up, down, left or right.
The game client is a tcp interface for the Player object.

```Usage: game_client [options]
    -p, --port PORT                  Server port
    -H, --host HOST                  Server host
    -s, --server                     Spawn server
    -c, --completely_random          Completely random moves
    -r, --random                     Random moves
    -m, --point_maximizer            Moves with high scores prefered
    -w, --sweeper                    Move with most empty fields prefered
    -h, --help                       Print this help
```

## memberberries

The memberberries are the neural network learning all the moves by all the players.
Memberberries is a tcp interface for the Memory object.

```Usage: memberberries [options]
    -t, --train TRAINING_PORT        PULL socket for training tasks
    -c, --compute COMPUTING_PORT     REP socket for computing tasks
    -r, --rate LEARNING_RATE         The learning rate for the perceptrons
    -h, --help                       Print this help
```
