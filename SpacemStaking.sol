// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Staking is Ownable(msg.sender), ReentrancyGuard {
    using SafeMath for uint256;
    // Assume Token is another contract that inherits from ERC20
    IERC20 public token;

    // Define staking periods and reward rates directly
    uint256 public constant ONE_MONTH = 30 days;
    uint256 public constant THREE_MONTHS = 90 days;
    uint256 public constant SIX_MONTHS = 180 days;
    uint256 public constant ONE_YEAR = 365 days;
    uint256 public constant TWO_YEARS = 730 days;
    uint256 public constant FIVE_YEARS = 1825 days;

    uint256 public constant PERCENT_REWARD_ONE_MONTH = 250;  // 2.5% per month, ~30% APY
    uint256 public constant PERCENT_REWARD_THREE_MONTHS = 1000; // 10% per 3 months, ~40% APY
    uint256 public constant PERCENT_REWARD_SIX_MONTHS = 4000; // 40% per 6 months, ~80% APY
    uint256 public constant PERCENT_REWARD_ONE_YEAR = 12000; // 120% per year, 120% APY
    uint256 public constant PERCENT_REWARD_TWO_YEARS = 40000; // 400% per 2 years, 200% APY
    uint256 public constant PERCENT_REWARD_FIVE_YEARS = 150000; // 1500% per 5 years, 300% APY

    struct Stake {
        uint256 amount;
        uint256 timestamp;
        uint256 duration;
        bool claimed;
    }

    // Mapping from staker address to array of stakes
    mapping(address => Stake[]) public stakes;
    uint256 public staked = 0;


    event Staked(address indexed user, uint256 amount, uint256 duration, uint256 index);
    event Claimed(address indexed user, uint256 amount, uint256 reward, uint256 index);


    // Constructor to set the initial values for the token
    constructor(address tokenAddress) {
        token = IERC20(tokenAddress);
    }

    function getUserStakes(address user) external view returns (Stake[] memory) {
        return stakes[user];
    }

    function getRewardRate(uint256 duration) internal pure returns (uint256) {
        if (duration == ONE_MONTH) return PERCENT_REWARD_ONE_MONTH;
        if (duration == THREE_MONTHS) return PERCENT_REWARD_THREE_MONTHS;
        if (duration == SIX_MONTHS) return PERCENT_REWARD_SIX_MONTHS;
        if (duration == ONE_YEAR) return PERCENT_REWARD_ONE_YEAR;
        if (duration == TWO_YEARS) return PERCENT_REWARD_TWO_YEARS;
        if (duration == FIVE_YEARS) return PERCENT_REWARD_FIVE_YEARS;
        revert("Invalid staking duration");
    }

    function stake(uint256 amount, uint256 duration) external {
        require(amount > 0, "Cannot stake 0 tokens");
        require(
            duration == ONE_MONTH || duration == THREE_MONTHS || duration == SIX_MONTHS || duration == ONE_YEAR || duration == TWO_YEARS || duration == FIVE_YEARS,
            "Invalid staking duration"
        );
        uint256 rewardRate = getRewardRate(duration);
        uint256 reward = amount.mul(rewardRate).div(10000); 
        uint256 rewardPool = token.balanceOf(address(this)).sub(staked);
        require(rewardPool >= reward, "Not enough tokens in reward pool");
        require(token.transferFrom(msg.sender, address(this), amount), "Failed to transfer tokens for staking");

        stakes[msg.sender].push(Stake(amount, block.timestamp, duration, false));
        staked += amount;
        emit Staked(msg.sender, amount, duration, stakes[msg.sender].length - 1);
    }

    function claim(uint256 stakeIndex) external nonReentrant {
        require(stakeIndex < stakes[msg.sender].length, "Stake index out of bounds");
        Stake storage userStake = stakes[msg.sender][stakeIndex];
        require(!userStake.claimed, "Reward already claimed");
        require(block.timestamp >= userStake.timestamp + userStake.duration, "Stake is still locked");

        userStake.claimed = true;

        uint256 rewardRate = getRewardRate(userStake.duration);
        uint256 reward = userStake.amount.mul(rewardRate).div(10000); // Convert percentage to reward amount
        uint256 totalAmount = userStake.amount.add(reward);
        staked -= totalAmount;
        require(token.transfer(msg.sender, totalAmount), "Failed to transfer tokens");

        emit Claimed(msg.sender, userStake.amount, reward, stakeIndex);
    }

}
