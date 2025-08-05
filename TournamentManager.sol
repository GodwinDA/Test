// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {GameRegistry} from "./GameRegistry.sol";

contract TournamentManager {
    using Address for address payable;

    uint256 private constant TOURNAMENT_START = 1723752000; // Thu Aug 15 2024 20:00:00 GMT+0000

    enum Status {
        Unknown,
        Pending,
        Approved,
        Canceled
    }

    address public coordinator;
    address[] public participants;
    uint256 public registrationCost;
    uint256 public forecastCost;
    GameRegistry public gameRegistry;
    mapping(address participants => Status) public participantStatus;

    error TournamentManager__IncorrectRegistrationCost();
    error TournamentManager__RegistrationClosed();
    error TournamentManager__IncorrectForecastCost();
    error TournamentManager__MaxParticipantsReached();
    error TournamentManager__AlreadyRegistered();
    error TournamentManager__NotEligibleForRefund();
    error TournamentManager__ForecastingClosed();
    error TournamentManager__UnauthorizedAccess();

    constructor(
        address _gameRegistry,
        uint256 _registrationCost,
        uint256 _forecastCost
    ) {
        coordinator = msg.sender;
        gameRegistry = GameRegistry(_gameRegistry);
        registrationCost = _registrationCost;
        forecastCost = _forecastCost;
    }

    function register() public payable {
        if (msg.value != registrationCost) {
            revert TournamentManager__IncorrectRegistrationCost();
        }

        if (block.timestamp > TOURNAMENT_START - 14400) {
            revert TournamentManager__RegistrationClosed();
        }

        if (participantStatus[msg.sender] == Status.Pending) {
            revert TournamentManager__AlreadyRegistered();
        }

        participantStatus[msg.sender] = Status.Pending;
    }

    function cancelRegistration() public {
        if (participantStatus[msg.sender] == Status.Pending) {
            (bool success, ) = msg.sender.call{value: registrationCost}("");
            require(success, "Failed to withdraw");
            participantStatus[msg.sender] = Status.Canceled;
            return;
        }
        revert TournamentManager__NotEligibleForRefund();
    }

    function approveParticipant(address participant) public {
        if (msg.sender != coordinator) {
            revert TournamentManager__UnauthorizedAccess();
        }
        if (participants.length >= 30) {
            revert TournamentManager__MaxParticipantsReached();
        }
        if (participantStatus[participant] == Status.Pending) {
            participantStatus[participant] = Status.Approved;
            participants.push(participant);
        }
    }

    function submitForecast(
        uint256 roundNumber,
        GameRegistry.Outcome forecast
    ) public payable {
        if (msg.value != forecastCost) {
            revert TournamentManager__IncorrectForecastCost();
        }

        if (block.timestamp > TOURNAMENT_START + roundNumber * 68400 - 68400) {
            revert TournamentManager__ForecastingClosed();
        }

        gameRegistry.confirmPaymentReceived(msg.sender, roundNumber);
        gameRegistry.setForecast(msg.sender, roundNumber, forecast);
    }

    function withdrawForecastFees() public {
        if (msg.sender != coordinator) {
            revert TournamentManager__NotEligibleForRefund();
        }

        uint256 fees = address(this).balance - participants.length * registrationCost;
        (bool success, ) = msg.sender.call{value: fees}("");
        require(success, "Failed to withdraw");
    }

    function claimReward() public {
        if (!gameRegistry.canClaimReward(msg.sender)) {
            revert TournamentManager__NotEligibleForRefund();
        }

        int8 score = gameRegistry.getParticipantScore(msg.sender);

        int8 maxScore = -1;
        int256 totalPositivePoints = 0;

        for (uint256 i = 0; i < participants.length; ++i) {
            int8 cScore = gameRegistry.getParticipantScore(participants[i]);
            if (cScore > maxScore) maxScore = cScore;
            if (cScore > 0) totalPositivePoints += cScore;
        }

        if (maxScore > 0 && score <= 0) {
            revert TournamentManager__NotEligibleForRefund();
        }

        uint256 shares = uint8(score);
        uint256 totalShares = uint256(totalPositivePoints);
        uint256 reward = 0;

        reward = maxScore < 0
            ? registrationCost
            : (shares * participants.length * registrationCost) / totalShares;

        if (reward > 0) {
            gameRegistry.resetForecastCount(msg.sender);
            (bool success, ) = msg.sender.call{value: reward}("");
            require(success, "Failed to withdraw");
        }
    } 
}
