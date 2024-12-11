// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {PriceConverter} from "./PriceConverter.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

// custom error
error FundMe__NotOwner();

contract FundMe {
    // use constant for variables that dont change later on and save gas
    // capital letters so that constant can be identified
    uint256 public constant MINIMUM_USD = 5e18;

    // all uint256 has access to PriceConverter
    using PriceConverter for uint256;

    // immutable is like constant but less restricted the value can be changedd before execution but not after execution (only once and in constructor only)
    // i_ so that immutable can be identified
    address private immutable i_owner;

    AggregatorV3Interface private s_priceFeed;
    // constructor that is called rightaway after the contract is deployed
    constructor(address priceFeed) {
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeed);
    }

    //a variable array named funders that logs who sent us eth
    // storage variable should be named with s_
    address[] private s_funders;

    mapping(address => uint256) private s_addressToAmountFunded;

    // allows users to send $ && have a minimum $ sent
    function Funds() public payable {
        //payable=should be payed , here eth should be greater than 1e18wei or 1 eth

        require(
            msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD,
            "didnt send enough ETH"
        ); //msg.value=no. of wei sent with the message || 1e18wei = 1ETH
        s_funders.push(msg.sender);
        s_addressToAmountFunded[msg.sender] =
            s_addressToAmountFunded[msg.sender] +
            msg.value;
    }

    function Withdraw() public OnlyOwner {
        // can only be accessed by owner
        // require(msg.sender==owner,"Must be owner");

        for (
            uint256 funderIndex = 0;
            funderIndex < s_funders.length;
            funderIndex++
        ) {
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        // resets the array
        s_funders = new address[](0);

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

    // getsversion of AggregatorV3 interface
    function getVersion() public view returns (uint256) {
        return s_priceFeed.version();
    }

    // modifier that can be added to a function
    modifier OnlyOwner() {
        // uses more gas
        //   require(msg.sender==i_owner,"Must be owner");

        // uses less gas due to no require of ""
        // revert is like return but without ""
        if (msg.sender != i_owner) {
            revert FundMe__NotOwner();
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

    // view
    function getAddressToAmountFunded(
        address fundingAddress
    ) external view returns (uint256) {
        return s_addressToAmountFunded[fundingAddress];
    }

    function getFunder(uint256 index) external view returns (address) {
        return s_funders[index];
    }

    function getOwner() external view returns (address) {
        return i_owner;
    }
}
