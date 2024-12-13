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
    address payable[] private s_players;
    event RaffleEntered(address indexed player);

    constructor(uint256 entranceFee) {
        i_entranceFee = entranceFee;
    }

    function enterRaffle() public payable {
        // require(msg.value >= i_entranceFee, "Not enough ETH");

        // require(msg.value >= i_entranceFee, SendMoreToEnterRaffle());

        if (msg.value < i_entranceFee) {
            revert Raffle__SendMoreToEnterRaffle();
        }
        s_players.push(payable(msg.sender));
        emit RaffleEntered(msg.sender);
    }

    function pickWinner() public {}

    // getter Function
    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }
}
