// SPDX-License-Identifier: MIT
// Margulan Zhumabek, 
pragma solidity ^0.8.0;

contract RockPaperScissors {
    address payable public player1;
    address payable public player2;
    uint256 public contractBalance;
    uint256 public REVEAL_TIMEOUT = 1 hours;

    enum Move { None, Rock, Paper, Scissors }
    
    struct Player {
        Move move;
        bool revealed;
    }

    Player public player1Data;
    Player public player2Data;

    constructor() {
        player1 = payable(address(0));
        player2 = payable(address(0));
    }

    function register() public payable {
        require(player1 == address(0) || player2 == address(0), "Game is full");
        require(msg.value > 0, "Bet amount should be greater than 0");

        if (player1 == address(0)) {
            player1 = payable(msg.sender);
        } else {
            player2 = payable(msg.sender);
        }
        contractBalance += msg.value;
    }

    function play(Move move) public {
        require(msg.sender == player1 || msg.sender == player2, "You are not a registered player");
        require(player1Data.move == Move.None || player2Data.move == Move.None, "Both players have already played");

        if (msg.sender == player1) {
            player1Data.move = move;
        } else {
            player2Data.move = move;
        }

        if (player1Data.move != Move.None && player2Data.move != Move.None) {
            // Both players have played; proceed to the disclosure phase
            revealTimeLeft();
        }
    }

    function reveal(Move move) public {
        require(msg.sender == player1 || msg.sender == player2, "You are not a registered player");
        require(player1Data.move != Move.None && player2Data.move != Move.None, "Both players must play first");
        require(!player1Data.revealed || !player2Data.revealed, "Moves already revealed");

        if (msg.sender == player1) {
            player1Data.revealed = true;
            player1Data.move = move;
        } else {
            player2Data.revealed = true;
            player2Data.move = move;
        }

        if (player1Data.revealed && player2Data.revealed) {
            // Both players have revealed their moves; determine the winner and distribute the prize
            determineWinner();
        }
    }

    function determineWinner() private {
        require(player1Data.revealed && player2Data.revealed, "Both players must reveal first");

        if (player1Data.move == player2Data.move) {
            // It's a tie, refund the bets
            player1.transfer(contractBalance / 2);
            player2.transfer(contractBalance / 2);
        } else if (
            (player1Data.move == Move.Rock && player2Data.move == Move.Scissors) ||
            (player1Data.move == Move.Paper && player2Data.move == Move.Rock) ||
            (player1Data.move == Move.Scissors && player2Data.move == Move.Paper)
        ) {
            // Player 1 wins
            player1.transfer(contractBalance);
        } else {
            // Player 2 wins
            player2.transfer(contractBalance);
        }

        // Reset the game
        player1 = payable(address(0));
        player2 = payable(address(0));
        player1Data.move = Move.None;
        player2Data.move = Move.None;
        player1Data.revealed = false;
        player2Data.revealed = false;
        contractBalance = 0;
    }

    function getContractBalance() public view returns (uint256) {
        return contractBalance;
    }

    function whoAmI() public view returns (uint8) {
        if (msg.sender == player1) {
            return 1;
        } else if (msg.sender == player2) {
            return 2;
        } else {
            return 0;
        }
    }

    function bothPlayed() public view returns (bool) {
        return player1Data.move != Move.None && player2Data.move != Move.None;
    }

    function bothRevealed() public view returns (bool) {
        return player1Data.revealed && player2Data.revealed;
    }

    function revealTimeLeft() public view returns (uint256) {
        if (!bothPlayed()) {
            return REVEAL_TIMEOUT;
        }
        uint256 currentTime = block.timestamp;
        if (player1Data.revealed && player2Data.revealed) {
            return 0;
        }
        uint256 revealEndTime = currentTime + REVEAL_TIMEOUT;
        if (player1Data.revealed) {
            revealEndTime += REVEAL_TIMEOUT;
        }
        return revealEndTime - currentTime;
    }
}
