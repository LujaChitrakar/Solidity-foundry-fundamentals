// SPDX-License-Identifier:MIT

pragma solidity ^0.8.19;

/**
 *@title A sample Raffle Contract
 *@author Luja Chitrakar
 *@notice This contact is for creating a sample raffle
 *@dev Implements Chainlink VRFv2.5
 */

contract Raffle {
    // custom error ||  name of function in the front for more readability
    error Raffle__SendMoreToEnterRaffle();

    uint256 private immutable i_entranceFee;
    // @dev the duration of lottery in seconds
    uint256 private immutable i_interval;
    uint256 private immutable s_lastTimeStamp;
    address payable[] private s_players;
    event RaffleEntered(address indexed player);

    constructor(uint256 entranceFee, uint256 interval) {
        i_entranceFee = entranceFee;
        i_interval = interval;
        s_lastTimeStamp = block.timestamp;
    }

    function enterRaffle() external payable {
        // require(msg.value >= i_entranceFee, "Not enough ETH");

        // require(msg.value >= i_entranceFee, SendMoreToEnterRaffle());

        if (msg.value < i_entranceFee) {
            revert Raffle__SendMoreToEnterRaffle();
        }
        s_players.push(payable(msg.sender));
        emit RaffleEntered(msg.sender);
    }

    // pick a random number || use random number to pick a player || automatically called
    function pickWinner() external {
        // check if enough time has passed
        // block.timestamp is a global variable like msg.sender
        if (block.timestamp - s_lastTimeStamp < i_interval) {
            revert();
        }
        // get random number
        // requestId=s_vrfCoordinator.requestRandomWords(
        //     VRFV2PlusClient.RandomWordsRequest({
        //         keyHash:s_keyHash,
        //         subId:s_subscriptionId,
        //         requestConfirmations:requestConfirmations,
        //         callbackGasLimit:callbackGasLimit,
        //         numWords:numWords,
        //         extraArgs:VRFV3PlusClient._argsToBytes(
        //             VRFV2PlusClient.ExtraArgsV1({nativePayment:false})
        //         )
        //     })
        // )
    }

    // getter Function
    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }
}
