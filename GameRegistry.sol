// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

contract GameRegistry {
    uint256 private constant TOURNAMENT_START = 1723752000; // Thu Aug 15 2024 20:00:00 GMT+0000
    uint256 private constant TOTAL_ROUNDS = 9;
    
    enum Outcome {
        Pending,
        TeamA,
        Tie,
        TeamB
    }
    
    struct ParticipantData {
        Outcome[TOTAL_ROUNDS] forecasts;
        bool[TOTAL_ROUNDS] hasPayment;
        uint8 forecastCount;
    }
    
    address admin;
    address gameMaster;
    Outcome[TOTAL_ROUNDS] private outcomes;
    mapping(address participants => ParticipantData) participantForecasts;
    
    error GameRegistry__UnauthorizedAccess();
    
    modifier onlyAdmin() {
        if (msg.sender != admin) {
            revert GameRegistry__UnauthorizedAccess();
        }
        _;
    }
    
    modifier onlyGameMaster() {
        if (msg.sender != gameMaster) {
            revert GameRegistry__UnauthorizedAccess();
        }
        _;
    }
    
    constructor() {
        admin = msg.sender;
    }
    
    function setGameMaster(address _gameMaster) public onlyAdmin {
        gameMaster = _gameMaster;
    }
    
    function setOutcome(uint256 roundNumber, Outcome outcome) public onlyAdmin {
        outcomes[roundNumber] = outcome;
    }
    
    function confirmPaymentReceived(
        address participant,
        uint256 roundNumber
    ) public onlyGameMaster {
        participantForecasts[participant].hasPayment[roundNumber] = true;
    }
    
    function setForecast(
        address participant,
        uint256 roundNumber,
        Outcome outcome
    ) public {
        if (block.timestamp <= TOURNAMENT_START + roundNumber * 68400 - 68400)
            participantForecasts[participant].forecasts[roundNumber] = outcome;
        participantForecasts[participant].forecastCount = 0;
        for (uint256 i = 0; i < TOTAL_ROUNDS; ++i) {
            if (
                participantForecasts[participant].forecasts[i] != Outcome.Pending &&
                participantForecasts[participant].hasPayment[i]
            ) ++participantForecasts[participant].forecastCount;
        }
    }
    
    function resetForecastCount(address participant) public onlyGameMaster {
        participantForecasts[participant].forecastCount = 0;
    }
    
    function getParticipantScore(address participant) public view returns (int8 score) {
        for (uint256 i = 0; i < TOTAL_ROUNDS; ++i) {
            if (
                participantForecasts[participant].hasPayment[i] &&
                participantForecasts[participant].forecasts[i] != Outcome.Pending
            ) {
                score += participantForecasts[participant].forecasts[i] == outcomes[i]
                    ? int8(2)
                    : -1;
            }
        }
    }
    
    function canClaimReward(address participant) public view returns (bool) {
        return
            outcomes[TOTAL_ROUNDS - 1] != Outcome.Pending &&
            participantForecasts[participant].forecastCount > 1;
    }
}
