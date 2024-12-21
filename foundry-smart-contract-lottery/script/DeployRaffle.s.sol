// SPDX-License-Identifier:MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {Raffle} from "src/Raffle.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {CreateSubscription} from "script/Interactions.s.sol";

contract DeployRaffle is Script {
    function run() public {}
    // for deployment

    function deployContract() public returns (Raffle, HelperConfig) {
        // helperConfig contract
        HelperConfig helperConfig = new HelperConfig();

        // networkconfig
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

        if (config.subscriptionId == 0) {
            // create SUbscription
            // variable named createSubscription which is new contract of CreateSubscription
            CreateSubscription createSubscription = new CreateSubscription();

            // variable createSubscription has function createSubscription which takes address parameter
            (config.subscriptionId, config.vrfCoordinator) = createSubscription
                .createSubscription(config.vrfCoordinator);
        }

        vm.startBroadcast();
        Raffle raffle = new Raffle(
            config.entranceFee,
            config.interval,
            config.vrfCoordinator,
            config.gasLane,
            config.subscriptionId,
            config.callbackGasLimit
        );
        vm.stopBroadcast();
        return (raffle, helperConfig);
    }
}
