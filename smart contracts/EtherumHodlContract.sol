// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract Hodler {

    /*Creating a mapping to store the transferred amount of money and the target exchange rate for each individual user
     (address).*/
    mapping(address => uint256) public targetPricesMap;
    mapping(address => uint256) public balancesToHodlMap;

    /*Function that accepts money and target values for the hodl.*/
    function addTargetHodlValues(uint256 _targetPrice) public payable {

        /*Check for existing hodl-contract for the current user.*/
        require(balancesToHodlMap[msg.sender] == 0, "You already have an unfinished hodl-contract!");

        /*Saving the values of the amount of money transferred for storage.*/
        balancesToHodlMap[msg.sender] = msg.value;

        /*Saving the target value of the USD exchange rate up till which the hodl will last, also multiplying
         the target price by 1e8 to match the price format returned from chainlink oracle (also multiplication can be used
          in the frontend to avoid solidity working with floating values).*/
        targetPricesMap[msg.sender] = (_targetPrice * 1e8);
    }

    /*Get and return current ETH/USD price from Chainlink oracle on Goerli Testnet*/
    function getCurrentPrice() public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e);
        (,int256 answer,,,) = priceFeed.latestRoundData();
        return uint256(answer);
    }

    /*Function for withdrawing money if the time has come.*/
    function hodledMoneyWithdraw() public payable {

        /*Checking if the current price is higher than the target price for the hodl.*/
        require(getCurrentPrice() >= targetPricesMap[msg.sender], "The time has not yet come to withdraw the hodled money. Be patient.");

        /*Withdrawal of the user's money that was left for the hodl. And deleting their value if the operation was successful.*/
        (bool withdrawSuccess,) = payable(msg.sender).call{value: balancesToHodlMap[msg.sender]}("");
        require(withdrawSuccess, "Withdrawal failed.");
        delete balancesToHodlMap[msg.sender];
    }
}