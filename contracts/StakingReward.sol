// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract StakingReward is ReentrancyGuard, Ownable {
    IERC20 public immutable stakingToken;
    IERC20 public immutable rewardsToken;

    string public name;
    uint256 public duration; // Duration of rewards to be paid out (in seconds)
    uint256 public finishAt; // Timestamp of when the rewards finish
    uint256 public updatedAt; // Minimum of last updated time and reward finish time
    uint256 public rewardRate; // Reward to be paid out per second
    uint256 public rewardPerTokenStored; // Sum of (reward rate * duration * 1e18 / total supply)
    uint256 public lockPeriod;

    struct User {
        uint256 lastStake; // timestamp last time user stake
    }

    mapping(address => User) public userInfo; // timestamp when user stake

    mapping(address => uint256) public userRewardPerTokenPaid; // User address => rewardPerTokenStored
    mapping(address => uint256) public rewards; // User address => rewards to be claimed

    uint256 public totalSupply; // Total Staked
    mapping(address => uint256) public balanceOf; // User address => staked amount

    /* ========== CONSTRUCTOR ========== */

    constructor(
        address poolOwner,
        string memory _name,
        address _stakingToken,
        address _rewardsToken,
        uint256 _lockPeriod
    ) {
        transferOwnership(poolOwner);
        name = _name;
        stakingToken = IERC20(_stakingToken);
        rewardsToken = IERC20(_rewardsToken);
        lockPeriod = _lockPeriod;
    }

    /* ========== MODIFIERS ========== */

    /**
     *  Buat track rewardPerToken & userRewardPerTokenPaid
     */

    modifier updateReward(address _account) {
        rewardPerTokenStored = rewardPerToken();
        updatedAt = lastTimeRewardApplicable();
        if (_account != address(0)) {
            rewards[_account] = earned(_account);
            userRewardPerTokenPaid[_account] = rewardPerTokenStored;
        }
        _;
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    /**
     * Set duration claimable berapa lama
     */
    function setRewardsDuration(uint256 _duration) external onlyOwner {
        require(finishAt < block.timestamp, "Reward duration not finished yet");
        duration = _duration;
        emit RewardsDurationUpdated(duration);
    }

    /**
     * Set reward amount
     */

    function notifyRewardAmount(uint256 _amount) external onlyOwner {
        if (block.timestamp > finishAt) {
            rewardRate = _amount / duration;
        } else {
            uint256 remainingRewards = rewardRate *
                (finishAt - block.timestamp);
            rewardRate = (remainingRewards + _amount) / duration;
        }

        require(rewardRate > 0, "reward rate = 0");
        require(
            rewardRate * duration <= rewardsToken.balanceOf(address(this)),
            "Provided reward too high"
        );

        finishAt = block.timestamp + duration;
        updatedAt = block.timestamp;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function stake(uint256 _amount)
        external
        nonReentrant
        updateReward(msg.sender)
    {
        require(_amount > 0, "amount = 0");
        // require(lockPeriod[msg.sender] <= 0);
        userInfo[msg.sender].lastStake = block.timestamp;
        // userInfo[msg.sender].lockTimePeriod = _time;
        balanceOf[msg.sender] += _amount;
        totalSupply += _amount;
        stakingToken.transferFrom(msg.sender, address(this), _amount);
        emit Staked(msg.sender, _amount);
    }

    // function withdraw(uint256 _amount)
    //     public
    //     nonReentrant
    //     updateReward(msg.sender)
    // {
    //     require(_amount > 0, "amount = 0");
    //     balanceOf[msg.sender] -= _amount;
    //     totalSupply -= _amount;
    //     stakingToken.transfer(msg.sender, _amount);
    //     emit Withdrawn(msg.sender, _amount);
    // }

    /**
     * Claim Reward
     */

    function getReward() public nonReentrant updateReward(msg.sender) {
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            rewardsToken.transfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

    function unstake(uint256 _amount)
        public
        nonReentrant
        updateReward(msg.sender)
    {
        require(_amount > 0, "Amount = 0");
        balanceOf[msg.sender] -= _amount;
        totalSupply -= _amount;
        require(
            block.timestamp - userInfo[msg.sender].lastStake >= lockPeriod,
            "Unable to unstake in locking period"
        );
        stakingToken.transfer(msg.sender, _amount);
        getReward();
        emit Unstaked(msg.sender, _amount, block.timestamp);
    }

    // function exit() external {
    //     withdraw(balanceOf[msg.sender]);
    //     getReward();
    // }

    /* ========== VIEWS ========== */

    function rewardPerToken() public view returns (uint256) {
        if (totalSupply == 0) {
            return rewardPerTokenStored;
        }

        return
            rewardPerTokenStored +
            (rewardRate * (lastTimeRewardApplicable() - updatedAt) * 1e18) /
            totalSupply;
    }

    function earned(address _account) public view returns (uint256) {
        return
            ((balanceOf[_account] *
                (rewardPerToken() - userRewardPerTokenPaid[_account])) / 1e18) +
            rewards[_account];
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return _min(block.timestamp, finishAt);
    }

    function _min(uint256 x, uint256 y) private pure returns (uint256) {
        return x <= y ? x : y;
    }

    /* ========== EVENTS ========== */

    event Staked(address indexed user, uint256 _amount);
    event Unstaked(address indexed user, uint256 _amount, uint256 timestamp);
    event RewardPaid(address indexed user, uint256 reward);
    event RewardsDurationUpdated(uint256 newDuration);
    // event Withdrawn(address indexed user, uint256 _amount);
}