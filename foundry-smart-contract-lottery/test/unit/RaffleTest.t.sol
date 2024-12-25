// SPDX-License-Identifier:MIT
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {DeployRaffle} from "script/DeployRaffle.s.sol";
import {Raffle} from "src/Raffle.sol";
import {HelperConfig, CodeConstants} from "script/HelperConfig.s.sol";
import {Vm} from "forge-std/Vm.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

contract RaffleTest is Test, CodeConstants {
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
    // setUp function
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

    /*RAFFLE TESTS */

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

    /*CHECKUPKEEP */

    // Test checkupKeep should return false if it has no balance
    function testCheckUpKeepReturnsFalseIfItHasNoBalance() public {
        // arrange
        // makes sure that timeHasPassed= true i.e, enough time has passed
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        // act
        (bool upKeepNeeded, ) = raffle.checkUpKeep("");

        // assert
        assert(!upKeepNeeded);
    }

    //Test checkupKeep returns false when raffle is not open
    function testCheckUpKeepReturnsFalseIfRaffleIsntOpen() public {
        // arrange
        vm.prank(PLAYER);
        vm.deal(PLAYER, STARTING_PLAYER_BALANCE);
        raffle.enterRaffle{value: entranceFee}();

        // makes sure that timeHasPassed= true i.e, enough time has passed
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        raffle.performUpKeep("");
        // act
        (bool upKeepNeeded, ) = raffle.checkUpKeep("");

        // assert
        assert(!upKeepNeeded);
    }

    // test checkupkeep returns returns false if enough time has not passed
    function testcheckUpKeepReturnsFalseIfEnoughTimeHasNotPassed() public {
        vm.prank(PLAYER);
        vm.deal(PLAYER, STARTING_PLAYER_BALANCE);
        raffle.enterRaffle{value: entranceFee}();

        // act
        (bool upKeepNeeded, ) = raffle.checkUpKeep("");

        assert(!upKeepNeeded);
    }

    /* PERFORMUPKEEP TESTS*/

    // test performUpKeep can only run if checkupkeep is true
    function testPerformUpKeepCanOnlyRunIfCheckUpKeepIsTrue() public {
        // arrange
        vm.prank(PLAYER);
        vm.deal(PLAYER, STARTING_PLAYER_BALANCE);
        raffle.enterRaffle{value: entranceFee}();

        // makes sure that timeHasPassed= true i.e, enough time has passed
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        //    act/assert
        raffle.performUpKeep("");
    }

    // test PerformUpKeep reverts if checkUpKeep is false
    function testPerformUpKeepRevertsIfCheckUpKeepIsFalse() public {
        // arrange
        uint256 currentBalance = 0;
        uint256 numOfPlayers = 0;
        Raffle.RaffleState rState = raffle.getRaffleState();

        vm.prank(PLAYER);
        vm.deal(PLAYER, STARTING_PLAYER_BALANCE);
        raffle.enterRaffle{value: entranceFee}();
        currentBalance = currentBalance + entranceFee;
        numOfPlayers = 1;

        // act/assert
        vm.expectRevert(
            abi.encodeWithSelector(
                Raffle.Raffle__UpKeepNotNeeded.selector,
                currentBalance,
                numOfPlayers,
                rState
            )
        );
        raffle.performUpKeep("");
    }

    /*get data from emited events in our tests */

    modifier raffleEntered() {
        // arrange
        vm.prank(PLAYER);
        vm.deal(PLAYER, STARTING_PLAYER_BALANCE);
        raffle.enterRaffle{value: entranceFee}();

        // makes sure that timeHasPassed= true i.e, enough time has passed
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        _;
    }

    // test performUpkeep updates rafflestate and emits request ID and contains raffleEntered
    function testPerformUpKeepUpdatesRaffleStateAndEmitsRequestId()
        public
        raffleEntered
    {
        // act
        vm.recordLogs();
        raffle.performUpKeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1];

        // assert
        Raffle.RaffleState raffleState = raffle.getRaffleState();
        assert(uint256(requestId) > 0);
        assert(uint256(raffleState) == 1);
    }

    /* FullFill randomwords */

    modifier skipFork() {
        if (block.chainid != LOCAL_CHAIN_ID) {
            return;
        }
        _;
    }

    // Test Fulfill RandomWords Can Only Be Called After PerformUpKeep and uses fuzz testing to test many different times using different randomWords || the amount of test depends on fuzz runs defined.
    function testFulfillRandomWordsCanOnlyBeCalledAfterPerformUpKeep(
        uint256 randomRequestId
    ) public raffleEntered skipFork {
        //  arrange/act/assert
        vm.expectRevert(VRFCoordinatorV2_5Mock.InvalidRequest.selector);
        VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(
            randomRequestId,
            address(raffle)
        );
    }

function test{
    
}
    // test fulfill randomWords picks the winner and resets the timestamp and sends the money to the winner
    function testFulfillRandomWordsPicksWinnerResetsAndSendsMoney()
        public
        raffleEntered
        skipFork
    {
        // arrange
        uint256 additionalEntrants = 3; //4 in total
        uint256 startingIndex = 1;
        address expectedWinner = address(1);

        for (
            uint256 i = startingIndex;
            i < startingIndex + additionalEntrants;
            i++
        ) {
            address newPlayer = address(uint160(i)); //address(1) jastai
            hoax(newPlayer, 1 ether); //deals ether to all the newPlayer
            raffle.enterRaffle{value: entranceFee}();
        }

        uint256 startingTimeStamp = raffle.getLastTimeStamp();
        uint256 winnerStartingBalance = expectedWinner.balance;

        // act
        // generate request ID
        vm.recordLogs();
        raffle.performUpKeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1];

        VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(
            uint256(requestId),
            address(raffle)
        );

        // assert
        address recentWinner = raffle.getRecentWinner();
        Raffle.RaffleState raffleState = raffle.getRaffleState();
        uint256 winnerBalance = recentWinner.balance;
        uint256 endingTimeStamp = raffle.getLastTimeStamp();
        uint256 prize = entranceFee * (additionalEntrants + 1);

        assert(recentWinner == expectedWinner);
        assert(uint256(raffleState) == 0);
        assert(winnerBalance == winnerStartingBalance + prize);
        assert(endingTimeStamp > startingTimeStamp);
    }
}
