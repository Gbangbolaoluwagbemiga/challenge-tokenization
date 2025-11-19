// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "hardhat/console.sol";
import "./ExampleExternalContract.sol";

contract Staker {
    ExampleExternalContract public exampleExternalContract;

    mapping(address => uint256) public balances;
    uint256 public constant threshold = 1 ether;
    uint256 public deadline = block.timestamp + 72 hours;
    bool public openForWithdraw;

    event Stake(address indexed staker, uint256 amount);

    modifier notCompleted() {
        require(!exampleExternalContract.completed(), "Contract already completed");
        _;
    }

    constructor(address exampleExternalContractAddress) {
        exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);
    }

    function stake() public payable notCompleted {
        require(block.timestamp < deadline, "Deadline has passed");
        require(!openForWithdraw, "Withdraw period active");
        
        balances[msg.sender] += msg.value;
        emit Stake(msg.sender, msg.value);
    }

    function execute() public notCompleted {
        require(block.timestamp >= deadline, "Deadline not reached yet");
        require(!openForWithdraw, "Already executed");

        if (address(this).balance >= threshold) {
            exampleExternalContract.complete{value: address(this).balance}();
        } else {
            openForWithdraw = true;
        }
    }

    function withdraw() public notCompleted {
        require(openForWithdraw, "Withdraw not available");
        require(balances[msg.sender] > 0, "No balance to withdraw");

        uint256 amount = balances[msg.sender];
        balances[msg.sender] = 0;
        (bool sent, ) = payable(msg.sender).call{value: amount}("");
        require(sent, "Failed to send Ether");
    }

    function timeLeft() public view returns (uint256) {
        if (block.timestamp >= deadline) {
            return 0;
        }
        return deadline - block.timestamp;
    }

    receive() external payable {
        stake();
    }
}
