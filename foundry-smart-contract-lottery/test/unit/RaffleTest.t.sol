// SPDX-License-Identifier:MIT
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {DeployRaffle} from "script/DeployRaffle.s.sol";
import {Raffle} from "src/Raffle.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";

contract RaffleTest is Test {
    Raffle public raffle;
    HelperConfig public helperConfig;

    uint256 entranceFee;
    uint256 interval;
    address vrfCoordinator;
    bytes32 gasLane;
    uint32 callbackGasLimit;
    uint256 subscriptionId;

    // Creates a mock player
    address public PLAYER = makeAddr("player");
    uint256 public constant STARTING_PLAYER_BALANCE = 10 ether;

    event RaffleEntered(address indexed player);
    event WinnerPicked(address indexed winner);

    function setUp() external {
        DeployRaffle deployer = new DeployRaffle();
        (raffle, helperConfig) = deployer.deployContract();

        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

        entranceFee = config.entranceFee;
        interval = config.interval;
        vrfCoordinator = config.vrfCoordinator;
        gasLane = config.gasLane;
        callbackGasLimit = config.callbackGasLimit;
        subscriptionId = config.subscriptionId;

        console.log("VRF Coordinator:", config.vrfCoordinator);
        require(
            config.vrfCoordinator != address(0),
            "VRF Coordinator is zero address!"
        );
    }

    // test if raffle is initialized as open
    function testRaffleInitializesInOpenState() public view {
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
    }

    // test if raffle revert when no enough eth
    function testRaffleRevertsWhenYouDontPayEnough() public {
        // Arrange
        vm.prank(PLAYER);
        // act/assert
        vm.expectRevert(Raffle.Raffle__SendMoreToEnterRaffle.selector);
        raffle.enterRaffle();
    }

    // test if raffle records player when sent enough eth
    function testRaffleRecordsPlayersWhenTheyEnter() public {
        // arrange
        vm.prank(PLAYER);
        vm.deal(PLAYER, STARTING_PLAYER_BALANCE);
        // act
        raffle.enterRaffle{value: entranceFee}();
        // assert
        address playerRecorder = raffle.getPlayer(0);
        assert(playerRecorder == PLAYER);
    }

    // test Entering raffle emit events
    function testEnteringRaffleEmitEvents() public {
        // arrange
        vm.prank(PLAYER);
        vm.deal(PLAYER, STARTING_PLAYER_BALANCE);
        // act
        // our emit has only one parameter in the event so check if that topic is true. Other are false cause there are no other parameter
        vm.expectEmit(true, false, false, false, address(raffle));
        emit RaffleEntered(PLAYER);
        // assert
        raffle.enterRaffle{value: entranceFee}();
    }

    // test players are not allowed to enter when raffle state is calculating
    function testDontAllowPlayersToEnterWhileRaffleIsCalculating() public {
        // arrange
        vm.prank(PLAYER);
        vm.deal(PLAYER, STARTING_PLAYER_BALANCE);
        raffle.enterRaffle{value: entranceFee}();

        // makes sure that timeHasPassed= true i.e, enough time has passed
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        raffle.performUpKeep("");
        // act
        vm.expectRevert(Raffle.Raffle__RaffleNotOpen.selector);
        vm.prank(PLAYER);
        vm.deal(PLAYER, STARTING_PLAYER_BALANCE);
        raffle.enterRaffle{value: entranceFee}();
        // assert
    }
}
