// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";
import {FundMe} from "../../src/FundMe.sol";

contract FundMeTest is Test {
    FundMe fundMe;

    // create a custom address user
    address USER = makeAddr("user");

    uint256 constant SEND_VALUE = 0.1 ether;
    uint256 constant STARTING_BALANCE = 10 ether;
    uint256 constant GAS_PRICE = 1;

    function setUp() external {
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();

        // send some money/funds to the custom address USER
        vm.deal(USER, STARTING_BALANCE);
    }

    function testMinimumUSDIsFive() public view {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testOwnerIsMsgSender() public view {
        assertEq(fundMe.getOwner(), msg.sender);
    }

    function testPriceFeedversion() public view {
        assertEq(fundMe.getVersion(), 4);
    }

    function testFundFailsWithoutEnoughEth() public {
        // after vm.expectRevert(); the next line should revert/fail for the test to pass
        vm.expectRevert();
        fundMe.Funds(); //sends 0ETH which is less than 5 eth that is required
    }

    function testFundUpdatesFundedDataStructure() public funded {
        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amountFunded, SEND_VALUE);
    }

    function testAddsFunderToArrayOfFunders() public funded {
        address funder = fundMe.getFunder(0);
        assertEq(funder, USER);
    }

    function testOnlyOwnerCanWithdraw() public funded {
        vm.expectRevert();
        vm.prank(USER); //it says the next tx will be sent by USER
        fundMe.Withdraw();
    }

    function testWithdrawWithASingleFunder() public funded {
        // Arrange
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        // Action

        // uint256 gasStart = gasleft(); //gasleft() is a inbuilt function that tell us how much gas is left in tx call. As we spend a little more gas than the total gas actually spent. || gasleft before the txn  EG:1000

        // txGasPrice() = simulate spending of gas as by default in ANVIL gas spent is set to 0
        vm.txGasPrice(GAS_PRICE);
        vm.prank(fundMe.getOwner());
        fundMe.Withdraw(); //uses gas

        // uint256 gasEnd = gasleft(); //gas left after the txn  EG:800
        // uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice;

        // Assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;

        assertEq(endingFundMeBalance, 0);
        assertEq(
            endingOwnerBalance,
            startingFundMeBalance + startingOwnerBalance
        );
    }

    function testWithdrawFromMultipleFunders() public funded {
        // ARRANGE

        // uint160 because uint160 is the exact no of bytes for an address
        uint160 numberOfFunders = 10;
        uint160 startingFundersIndex = 2;

        for (uint160 i = startingFundersIndex; i < numberOfFunders; i++) {
            // steps
            // vm.prank = to create new addresses in a loop
            // vm.deal = to deal the address with some money
            // fund the fundMe

            // hoax is the combination of both prank and deal i.e; it creates a mock address and add some funds/money to it
            // address(i) generates new address for each loop
            hoax(address(i), SEND_VALUE);
            fundMe.Funds{value: SEND_VALUE}();

            uint256 startingOwnerBalance = fundMe.getOwner().balance;
            uint256 startingFundMeBalance = address(fundMe).balance;

            // ACT

            // vm.prank(fundMe.getOwner()); OR
            // this says like startBroadcast. Here it means from start to finish its pretending to be Owner
            vm.startPrank(fundMe.getOwner());
            fundMe.Withdraw();
            vm.stopPrank();

            // ASSERT
            assertEq(address(fundMe).balance, 0);
            assertEq(
                startingOwnerBalance + startingFundMeBalance,
                fundMe.getOwner().balance
            );
        }
    }

    modifier funded() {
        vm.prank(USER); //it says the next tx will be sent by USER
        fundMe.Funds{value: SEND_VALUE}();
        _;
    }
}
