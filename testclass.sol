// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title TokenDistributor
 * @dev Contract for distributing tokens to multiple recipients with vesting capabilities
 * @notice This contract allows batch distribution of tokens with optional vesting periods
 */
contract TokenDistributor is Ownable, ReentrancyGuard {
    IERC20 public token;
    
    struct VestingSchedule {
        uint256 totalAmount;
        uint256 releasedAmount;
        uint256 startTime;
        uint256 duration;
    }
    
    mapping(address => VestingSchedule) public vestingSchedules;
    mapping(address => bool) public authorizedDistributors;
    
    event TokensDistributed(address[] recipients, uint256[] amounts);
    event VestingScheduleCreated(address beneficiary, uint256 amount, uint256 duration);
    event TokensReleased(address beneficiary, uint256 amount);
    
    constructor(address _token) {
        token = IERC20(_token);
    }

    /**
     * @dev Adds authorized distributors who can distribute tokens
     * @param distributors Array of addresses to authorize
     */
    function addAuthorizedDistributors(address[] calldata distributors) external {
        for (uint256 i = 0; i < distributors.length; i++) {
            authorizedDistributors[distributors[i]] = true;
        }
    }

    /**
     * @dev Distributes tokens to multiple recipients in a single transaction
     * @param recipients Array of recipient addresses
     * @param amounts Array of token amounts to distribute
     */
    function batchDistribute(
        address[] calldata recipients, 
        uint256[] calldata amounts
    ) external payable {
        require(recipients.length == amounts.length, "Arrays length mismatch");
        require(recipients.length > 0, "Empty arrays");
        
        uint256 totalAmount = 0;
        for (uint256 i = 0; i < amounts.length; i++) {
            totalAmount += amounts[i];
        }
        
        // Transfer tokens from sender to recipients
        for (uint256 i = 0; i < recipients.length; i++) {
            require(recipients[i] != address(0), "Invalid recipient");
            require(amounts[i] > 0, "Amount must be positive");
            
            token.transferFrom(msg.sender, recipients[i], amounts[i]);
        }
        
        emit TokensDistributed(recipients, amounts);
    }

    /**
     * @dev Creates vesting schedules for multiple beneficiaries
     * @param beneficiaries Array of beneficiary addresses
     * @param amounts Array of vesting amounts
     * @param durations Array of vesting durations in seconds
     */
    function createVestingSchedules(
        address[] calldata beneficiaries,
        uint256[] calldata amounts,
        uint256[] calldata durations
    ) external {
        require(authorizedDistributors[msg.sender] || msg.sender == owner(), "Not authorized");
        require(beneficiaries.length == amounts.length && amounts.length == durations.length, "Arrays length mismatch");
        
        for (uint256 i = 0; i < beneficiaries.length; i++) {
            require(beneficiaries[i] != address(0), "Invalid beneficiary");
            require(amounts[i] > 0, "Amount must be positive");
            require(durations[i] >= 30 days, "Duration too short");
            
            vestingSchedules[beneficiaries[i]] = VestingSchedule({
                totalAmount: amounts[i],
                releasedAmount: 0,
                startTime: block.timestamp,
                duration: durations[i]
            });
            
            // Transfer tokens to contract for vesting
            token.transferFrom(msg.sender, address(this), amounts[i]);
            
            emit VestingScheduleCreated(beneficiaries[i], amounts[i], durations[i]);
        }
    }

    /**
     * @dev Allows beneficiaries to claim their vested tokens
     */
    function releaseVestedTokens() external nonReentrant {
        VestingSchedule storage schedule = vestingSchedules[msg.sender];
        require(schedule.totalAmount > 0, "No vesting schedule");
        
        uint256 vestedAmount = calculateVestedAmount(msg.sender);
        uint256 releasableAmount = vestedAmount - schedule.releasedAmount;
        
        require(releasableAmount > 0, "No tokens to release");
        
        schedule.releasedAmount += releasableAmount;
        token.transfer(msg.sender, releasableAmount);
        
        emit TokensReleased(msg.sender, releasableAmount);
    }

    /**
     * @dev Calculates the amount of tokens that have vested for a beneficiary
     * @param beneficiary Address of the beneficiary
     * @return Amount of vested tokens
     */
    function calculateVestedAmount(address beneficiary) public view returns (uint256) {
        VestingSchedule memory schedule = vestingSchedules[beneficiary];
        
        if (block.timestamp < schedule.startTime) {
            return 0;
        } else if (block.timestamp >= schedule.startTime + schedule.duration) {
            return schedule.totalAmount;
        } else {
            return (schedule.totalAmount * (block.timestamp - schedule.startTime)) / schedule.duration;
        }
    }

    /**
     * @dev Emergency function to withdraw tokens from contract
     * @param amount Amount of tokens to withdraw
     */
    function emergencyWithdraw(uint256 amount) external onlyOwner {
        token.transfer(owner(), amount);
    }

    /**
     * @dev Allows contract to receive ETH for gas refunds
     */
    receive() external payable {}

    /**
     * @dev Withdraws ETH from contract
     */
    function withdrawETH() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}
