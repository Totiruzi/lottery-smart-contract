// SPDX-License-Identifie: MIT

pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {Raffle} from "src/Raffle.sol";

contract DeployRaffle is Script {
    function run() public {}

    function deployContract() public returns(Raffle, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();
        // local -> deploy mocks, get mocks config
        // Sepolia -> deploy Sepolia, get Sepolia config
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
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
        return(raffle, helperConfig);
    }
}