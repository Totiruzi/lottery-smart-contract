// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {Raffle} from "src/Raffle.sol";
import {DeployRaffle} from "script/DeployRaffle.s.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {Vm} from "forge-std/Vm.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";


contract RaffleTest is Test {

    Raffle public raffle;
    HelperConfig public helperConfig;

    uint256 entranceFee;
    uint256 interval;
    address vrfCoordinator;
    bytes32 gasLane;
    uint256 subscriptionId;
    uint32 callbackGasLimit;

    address public PLAYER = makeAddr("player");
    uint256 private constant STARTING_PLAYER_BALANCE = 10 ether;

    /**
     * Events
     */
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
        subscriptionId = config.subscriptionId;
        callbackGasLimit = config.callbackGasLimit;
        vm.deal(PLAYER, STARTING_PLAYER_BALANCE);
    }

    function testRaffleInitializesInOpenState() public view {
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
    }

    modifier playerEnteredRaffle() {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        _;
        
    }

    /**
     * ENTER RAFFLE
     */
    function testRaffleRevertWhenYouDoNotPayEnough() public {
        vm.prank(PLAYER);
        vm.expectRevert(Raffle.Raffle__SendMoreToEnterRaffle.selector);
        raffle.enterRaffle();
    }

    function testRaffleAddsPlayerWhenTheyEnter() public {
        // Arrange
        vm.prank(PLAYER);

        // Act
        raffle.enterRaffle{value: entranceFee}();

        // Assert
        address playerEntered = raffle.getPlayer(0);
        assert(playerEntered == PLAYER);
    }

    function testEnteringRaffleEmitsEvent() public {
        // Arrange
        vm.prank(PLAYER);

        // Act
        vm.expectEmit(true, false, false, false, address(raffle));
        emit RaffleEntered(PLAYER);

        // Assert
        raffle.enterRaffle{value: entranceFee}();
    }

    function testDoNotAllowPlayerToEnterRaffleWhileRaffleIsCalculating() public playerEnteredRaffle {
        // Arrange
        // vm.prank(PLAYER);
        // raffle.enterRaffle{value: entranceFee}();
        // vm.warp(block.timestamp + interval + 1);
        // vm.roll(block.number + 1);
        raffle.performUpkeep("");

        // Act /  Assert
        vm.expectRevert(Raffle.Raffle__RaffleIsNotOpen.selector);
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
    }

    /**
     * Check Upkeep
     */
    function testCheckUpkeepReturnsFalseIfItHasNoBallance() public {
        // Arrange
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        // Act
        (bool upkeepNeed, ) = raffle.checkUpkeep("");
        // Assert
        assert(!upkeepNeed);
    }
    
    function testCheckUpkeepReturnsFalseIfRaffleIsNotOpen() public playerEnteredRaffle {
        // Arrange
        // vm.prank(PLAYER);
        // raffle.enterRaffle{value: entranceFee}();
        // vm.warp(block.timestamp + interval + 1);
        // vm.roll(block.number + 1);
        raffle.performUpkeep("");

        // Act
        (bool upKeepNeeded, ) = raffle.checkUpkeep("");

        // Assert
        // assert(raffle.getRaffleState() == Raffle.RaffleState.CALCULATING);
        assert(!upKeepNeeded);
    }

    function testCheckUpkeepReturnsFalseIsEnoughTimeHasNotPassed() public {
        // Arrange
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp);
        vm.roll(block.number + 1);
        // raffle.performUpkeep("");

        // Act
        (bool checkUpkeep,) = raffle.checkUpkeep("");

        // Assert
        assert(!checkUpkeep);
    }

    function testCheckUpkeepReturnsTrueWhenParametersAreGood() public playerEnteredRaffle {
        // Arrange
        // vm.prank(PLAYER);
        // raffle.enterRaffle{value: entranceFee}();
        // vm.warp(block.timestamp + interval + 1);
        // vm.roll(block.number + 1);

        // Act
        (bool checkUpkeep,) = raffle.checkUpkeep("");

        // Assert
        assert(checkUpkeep);
    }

    /**
     * PERFORM UPKEEP
     */
    function testPerfoemUpkeepCanOnlyRunIfCheckUpkeepIsTrue() public playerEnteredRaffle {
        // Arrange
        // vm.prank(PLAYER);
        // raffle.enterRaffle{value: entranceFee}();
        // vm.warp(block.timestamp + interval + 1);
        // vm.roll(block.number + 1);

        //Act & Assert
        raffle.checkUpkeep("");
    }

    function testPerformanceUpkeepRevertIfCheckIpkeepISFAlse() public {
        // Arrange
        uint256 curretBalance = 0;
        uint256 numbersOfPlayer = 0;
        Raffle.RaffleState raffleState = raffle.getRaffleState();

        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        curretBalance += entranceFee;
        numbersOfPlayer = 1;

        // Act & Assert
        vm.expectRevert(
            abi.encodeWithSelector(Raffle.Raffle__UpkeepNotNeeded.selector, curretBalance, numbersOfPlayer, raffleState)
        );
        raffle.performUpkeep("");
    }

    function testPerformUpkeepUpdatesRaffleStateAndEmitsRequestId() public playerEnteredRaffle {
        // Arrange

        // Act
        vm.recordLogs();
        raffle.performUpkeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1]; 

        // Assert
        Raffle.RaffleState raffleState = raffle.getRaffleState();
        assert(uint256(requestId) > 0);
        assert(uint256(raffleState) == 1);
    }

    /**
     * FULFILLRANDOMWORDS
     */
    function testFulfillRandomWordsCanOnlyBeCalledAfterPaerformUpkeep(uint256 requestId) public playerEnteredRaffle {
        // Arrange / Act / Assert
        vm.expectRevert(VRFCoordinatorV2_5Mock.InvalidRequest.selector);
        VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(requestId, address(raffle));
    }
}