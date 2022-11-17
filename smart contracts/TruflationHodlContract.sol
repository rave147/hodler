// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";


contract HodlTruflation is ChainlinkClient, ConfirmedOwner {
  using Chainlink for Chainlink.Request;

  /*HODL Part*/

  /*Creating a mapping to store the transferred amount of money and the target inflation for each individual user
  (address).*/
  mapping(address => uint256) public targetInflationMap;
  mapping(address => uint256) public balancesToHodlMap;

  /*Function that accepts money and target inflation values for the hodl.*/
  function addTargetHodlValues(uint256 _targetInflation) public payable {

    /*Check for existing hodl-contract for the current user.*/
    require(balancesToHodlMap[msg.sender] == 0, "You already have an unfinished hodl-contract!");

    /*Saving the values of the amount of money transferred for storage.*/
    balancesToHodlMap[msg.sender] = msg.value;

    /*Saving the target value of the inflation up till which the hodl will last, also multiplying
    the target number by 1e8 to match the price format returned from chainlink truflation oracle (also multiplication can be used
    in the frontend to avoid solidity working with floating values).*/
    targetInflationMap[msg.sender] = (_targetInflation * 1e8);
  }

  /*Function for withdrawing money if the time has come.*/
  function hodledMoneyWithdraw() public payable {

    /*Checking if the current inflation is lower than the target inflation for the hodl.*/
    require(int(targetInflationMap[msg.sender]) > inflationWei, "The time has not yet come to withdraw the hodled money. Be patient.");

    /*Withdrawal of the user's money that was left for the hodl. And deleting their value if the operation was successful.*/
    (bool withdrawSuccess,) = payable(msg.sender).call{value: balancesToHodlMap[msg.sender]}("");
    require(withdrawSuccess, "Withdrawal failed.");
    delete balancesToHodlMap[msg.sender];
  }


  /*Truflation Part*/
  
  /*
  Constructor arguments for deploy on Goerli testnetwork:
  0xcf72083697aB8A45905870C387dC93f380f2557b, e5b99e0a2f79402998187b11f37c56a6, 1000000000000
  If don't work, check actual information on: https://github.com/truflation/quickstart/blob/main/network.md
  */

  string public yoyInflation;
  address public oracleId;
  string public jobId;
  uint256 public fee;

  constructor(
    address oracleId_,
    string memory jobId_,
    uint256 fee_
  ) ConfirmedOwner(msg.sender) {
    setChainlinkToken(0x326C977E6efc84E512bB9C30f76E30c160eD06FB);
    oracleId = oracleId_;
    jobId = jobId_;
    fee = fee_;
  }

        
  function requestYoyInflation() public returns (bytes32 requestId) {
    Chainlink.Request memory req = buildChainlinkRequest(
      bytes32(bytes(jobId)),
      address(this),
      this.fulfillYoyInflation.selector
    );
    req.add("service", "truflation/current");
    req.add("keypath", "yearOverYearInflation");
    req.add("abi", "json");
    return sendChainlinkRequestTo(oracleId, req, fee);
  }

  function fulfillYoyInflation(
    bytes32 _requestId,
    bytes memory _inflation
  ) public recordChainlinkFulfillment(_requestId) {
    yoyInflation = string(_inflation);
  }

  function changeOracle(address _oracle) public onlyOwner {
    oracleId = _oracle;
  }

  function changeJobId(string memory _jobId) public onlyOwner {
    jobId = _jobId;
  }

  function getChainlinkToken() public view returns (address) {
    return chainlinkTokenAddress();
  }

  function withdrawLink() public onlyOwner {
    LinkTokenInterface link = LinkTokenInterface(chainlinkTokenAddress());
    require(link.transfer(msg.sender, link.balanceOf(address(this))),
    "Unable to transfer");
  }

  /*
  This part convert yoyInflation string to inflationWei int256
  I hope you found it before you start writing your own converter like I did :)
  */

  int256 public inflationWei;
  function requestInflationWei() public returns (bytes32 requestId) {
    Chainlink.Request memory req = buildChainlinkRequest(
      bytes32(bytes(jobId)),
      address(this),
      this.fulfillInflationWei.selector
    );
    req.add("service", "truflation/current");
    req.add("keypath", "yearOverYearInflation");
    req.add("abi", "int256");
    req.add("multiplier", "1000000000000000000");
    return sendChainlinkRequestTo(oracleId, req, fee);
  }

  function fulfillInflationWei(
    bytes32 _requestId,
    bytes memory _inflation
  ) public recordChainlinkFulfillment(_requestId) {
    inflationWei = toInt256(_inflation);
  }

  function toInt256(bytes memory _bytes) internal pure
  returns (int256 value) {
    assembly {
      value := mload(add(_bytes, 0x20))
    }
  }

}
