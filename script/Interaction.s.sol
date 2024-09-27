// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console2} from "forge-std/Script.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

contract CreateSubscription is Script {
    HelperConfig helperConfig;
    function createSubscriptionUsingConfig() public returns(uint256, address) {
        helperConfig = new HelperConfig();
        address vrfCoordinator = helperConfig.getConfig().vrfCoordinator;
        (uint256 subId, ) = createSubcription(vrfCoordinator);

        return (subId, vrfCoordinator);
    }

    function createSubcription(address vrfCoordinator) public returns(uint256, address) {
        console2.log("Creating subscription for chain", block.chainid);
        vm.startBroadcast();
        uint256 subId = VRFCoordinatorV2_5Mock(vrfCoordinator).createSubscription();
        vm.stopBroadcast();
        console2.log("Your subscription Id is: ", subId);
        console2.log("Please update your subscription Id in your HelperConfig.s.sol");
        return (subId, vrfCoordinator);
    }

    function run() external {
        createSubscriptionUsingConfig();
    }
}

contract FundSubscription {
    HelperConfig helperConfig;
    uint256 public constant FUND_AMOUNT = 3 ether; // 3 LINK 
    function fundScubscriptionUsingConfig() public {
         helperConfig = new HelperConfig();
        address vrfCoordinator = helperConfig.getConfig().vrfCoordinator;
        uint256 subscriptionId  = helperConfig.getConfig().subscriptionId;

    }
    function run() external {}
}