Protocol Description

Marcus and his 15 colleagues are esports enthusiasts who decided to watch a gaming tournament together. Marcus found a venue with 30-person capacity for viewing parties. To enhance engagement and cover venue costs, Marcus organizes outcome forecasting for tournament rounds, inviting up to 14 additional participants.

Marcus and his 15 colleagues are trustworthy, but other participants are unknown, so Marcus implements a Web3 protocol for secure forecasting operations.

## Roles

**Coordinator**: Marcus (protocol administrator)  
**Participant**: Anyone can register  
**Competitor**: Approved participants who can submit forecasts  

Marcus serves as both Coordinator and Competitor. His 15 colleagues are Competitors. These 16 individuals are trusted and won't exploit vulnerabilities. Remaining participants are untrusted.

## Economics

Registration costs form the prize pool, distributed among Competitors who paid at least one forecast fee based on earned points.

Forecast fees are required for predictions. Marcus also pays these fees. No additional fee for changing paid forecasts. These funds cover venue costs - Coordinator can withdraw anytime.

Registration and forecast costs are deployment parameters on Ethereum blockchain.

## Timeline

Tournament starts Thu Aug 15 2025 20:00:00 UTC. Total of 9 rounds.

**Registration**: Until 16:00:00 UTC on tournament day. Users pay registration cost. Coordinator approves up to 30 Competitors, prioritizing Marcus and his 15 colleagues.

**Refunds**: Unapproved users can withdraw registration costs anytime.

## Tournament Structure

Two teams compete. Each round ends with:
- TeamA victory (forecast TeamA)
- TeamB victory (forecast TeamB)  
- Tie result (forecast Tie)

Daily rounds at 20:00:00 UTC. Forecasts accepted until 19:00:00 UTC same day. Competitors pay forecast fee for first prediction per round.

Coordinator enters results after each round.

## Scoring

**Correct forecast**: +2 points (fee paid)  
**Incorrect forecast**: -1 point (fee paid)  
**No forecast/unpaid**: 0 points

## Rewards

After round 9 results, Competitors claim rewards if:
- Total points > 0
- Paid ≥1 forecast fee

Prize pool distributed proportionally among positive-point Competitors. If all Competitors have negative points, everyone receives registration cost refund.

## Contracts

### GameRegistry.sol

Manages forecasts and results. Calculates final scores.

- `setOutcome`: Coordinator sets round results
- `confirmPaymentReceived`: Marks forecasts as paid
- `setForecast`: Records Competitor forecasts (changeable without additional payment)
- `resetForecastCount`: Prevents duplicate rewards
- `getParticipantScore`: Calculates Competitor points
- `canClaimReward`: Validates reward eligibility

### TournamentManager.sol

Handles registration, fee collection, and reward distribution.

- `register`: Users pay registration cost
- `cancelRegistration`: Unapproved users withdraw registration cost
- `approveParticipant`: Coordinator approves Competitors
- `submitForecast`: Competitors pay forecast fee and record predictions
- `withdrawForecastFees`: Coordinator withdraws forecast fees
- `claimReward`: Competitors withdraw prize pool rewards
