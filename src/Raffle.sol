// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// internal & private view & pure functions
// external & public view & pure functions

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;
import {VRFConsumerBaseV2Plus} from "@chainlink/contracts@1.2.0/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
/**
 *@title A sample Raffle contract
 *@author Oyemechi Onowu
 *@notice This contract is for creating a simple Raffle
 *@dev Implements Chainlink VRFv2.5
*/
contract Rafle is VRFConsumerBaseV2Plus{
    /**
     * Errors
     */
    error Raffle__SendMoreToEnterRaffle();

    uint256 private immutable i_entranceFee;
    address payable[] private s_players;

    // @dev time duration between Raffle draws
    uint256 private immutable i_interval;
    uint256 private s_lastTimeStamp;

    /** Events */
    event RaffleEntered(address indexed player);

    constructor(uint256 entranceFee, uint256 interval) {
        i_entranceFee = entranceFee;
        i_interval = interval;
        s_lastTimeStamp = block.timestamp;
    }

    function enterRaffle() external payable {
        // require(msg.value >= i_entranceFee, "Did not send enough ETH");
        // require(msg.value >= i_entranceFee, SendMoreToEnterRaffle());
        if (msg.value < i_entranceFee) {
            revert Raffle__SendMoreToEnterRaffle();
        }

        s_players.push(payable(msg.sender));

        /**
         * Emit makes migration easier
         * Makes front-end "indexing" easier
         */
        emit RaffleEntered(msg.sender);
    }

    /**
     * 1. Get a random number
     * 2. Use random number to pick a winner
     * 3. Be called automatically
     */
    function pickWinner() external view{
        if ((block.timestamp - s_lastTimeStamp) < i_interval) {
            revert();
        }

        // Get our random from VRF number
        requestId = s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: s_keyHash,
                subId: s_subscriptionId,
                requestConfirmations: requestConfirmations,
                callbackGasLimit: callbackGasLimit,
                numWords: numWords,
                extraArgs: VRFV2PlusClient._argsToBytes(
                    // Set nativePayment to true to pay for VRF requests with Sepolia ETH instead of LINK
                    VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
                )
            })
        );
    }

    /**
     *Getter functions 
    */

    function getEntraceFee() external view returns(uint256) {
        return i_entranceFee;
    }
}