// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {PriceConverter} from "./PriceConverter.sol";

// custom error
error NotOwner();

contract FundMe {
    // use constant for variables that dont change later on and save gas
    // capital letters so that constant can be identified
    uint256 public constant MINIMUM_USD = 5e18;

    // all uint256 has access to PriceConverter
    using PriceConverter for uint256;

    // immutable is like constant but less restricted the value can be changedd before execution but not after execution (only once and in constructor only)
    // i_ so that immutable can be identified
    address public immutable i_owner;

    // constructor that is called rightaway after the contract is deployed
    constructor() {
        i_owner = msg.sender;
    }

    //a variable array named funders that logs who sent us eth
    address[] public funders;

    mapping(address funder => uint256 amountFunded)
        public addressToAmountFunded;

    // allows users to send $ && have a minimum $ sent
    function Funds() public payable {
        //payable=should be payed , here eth should be greater than 1e18wei or 1 eth

        require(
            msg.value.getConversionRate() >= MINIMUM_USD,
            "didnt send enough ETH"
        ); //msg.value=no. of wei sent with the message || 1e18wei = 1ETH
        funders.push(msg.sender);
        addressToAmountFunded[msg.sender] =
            addressToAmountFunded[msg.sender] +
            msg.value;
    }

    function Withdraw() public OnlyOwner {
        // can only be accessed by owner
        // require(msg.sender==owner,"Must be owner");

        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        // resets the array
        funders = new address[](0);

        // transfer eth
        // msg.sender is of  type address
        // payable(msg.sender) is of type payable address
        payable(msg.sender).transfer(address(this).balance);

        // send Eth
        // made it require so that if the send fails we would be notified
        bool SendSuccess = payable(msg.sender).send(address(this).balance);
        require(SendSuccess, "Send failed");

        // call
        // it actually requires 2 variables (bool CallSucess, bytes memory(because its an arrray) DataReturned)
        (bool CallSucess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(CallSucess, "Call not successful");
    }

    // modifier that can be added to a function
    modifier OnlyOwner() {
        // uses more gas
        //   require(msg.sender==i_owner,"Must be owner");

        // uses less gas due to no require of ""
        // revert is like return but without ""
        if (msg.sender != i_owner) {
            revert NotOwner();
        }

        //   first execute modifier then everything else
        _;
    }

    // look into Fallback examples
    // it takes place when the function in the contract is exucuted through other sources
    receive() external payable {
        Funds();
    }

    fallback() external payable {
        Funds();
    }
}
