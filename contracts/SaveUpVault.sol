// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ERC4626Fees.sol";
import "./Strategies/IStrategy.sol";
import "./Strategies/MockStrategy.sol";


contract SaveUpVault is ERC4626Fees, Ownable {
    using SafeERC20 for IERC20;

    error SaveUpVault_InvalidTargetAmount();
    error SaveUpVault_InvalidDuration();
    error SaveUpVault_ChallengeEnded();
    error SaveUpVault_ChallengeNotOver();
    error SaveUpVault_AlreadyJoinedChallenge();
    error SaveUpVault_NotParticipant();
    error SaveUpVault_GoalNotReached();
    error SaveUpVault_RewardAlreadyClaimed();
    error SaveUpVault_NoBalanceToWithdraw();
    error SaveUpVault_InvalidFeeReceiverAddress();

    struct Challenge {
        uint256 id;
        string name;
        address creator;
        uint256 targetAmount;
        uint256 startTime;
        uint256 endTime;
        address[] participants;
        mapping(address => uint256) contributions;
        mapping(address => bool) hasReachedGoal;
        mapping(address => bool) hasClaimedReward;
        bool isFinalized;
        address firstToReach;
    }

    IERC20 public immutable rewardToken;
    IStrategy[] public strategies;
    uint256 public challengeCount;
    mapping(uint256 => Challenge) public challenges;
    mapping(address => uint256[]) public userChallenges;
    address public feeReceiverAddress;

    event ChallengeCreated(uint256 indexed id, address indexed creator, uint256 targetAmount, uint256 endTime);
    event JoinedChallenge(uint256 indexed id, address indexed participant);
    event Contributed(uint256 indexed id, address indexed participant, uint256 amount);
    event GoalReached(uint256 indexed id, address indexed participant);
    event RewardClaimed(uint256 indexed id, address indexed participant);
    event Withdrawn(uint256 indexed id, address indexed participant, uint256 amount);
    event FeeReceiverChanged(address indexed newFeeReceiver);

    constructor(IERC20 _asset, IERC20 _rewardToken)
        ERC20("SaveUp Vault Share", "svsUSDT")
        ERC4626(_asset)
        Ownable(msg.sender) // Initialize Ownable with the deployer
    {
        rewardToken = _rewardToken;
        feeReceiverAddress = msg.sender; // Initialize fee receiver to deployer
        emit FeeReceiverChanged(msg.sender);

        // Deploy and add Mock strategy
        MockStrategy mockStrategy = new MockStrategy(address(_asset), address(this));
        addStrategy(IStrategy(address(mockStrategy)));
    }

    function addStrategy(IStrategy strategy) public onlyOwner {
        strategies.push(strategy);
    }

    function createChallenge(string memory name, uint256 targetAmount, uint256 duration) external returns (uint256) {
        if (targetAmount == 0) revert SaveUpVault_InvalidTargetAmount();
        if (duration == 0) revert SaveUpVault_InvalidDuration();

        uint256 id = challengeCount++;
        Challenge storage c = challenges[id];
        c.id = id;
        c.name = name;
        c.creator = msg.sender;
        c.targetAmount = targetAmount;
        c.startTime = block.timestamp;
        c.endTime = block.timestamp + duration;
        c.participants.push(msg.sender);

        userChallenges[msg.sender].push(id);
        emit ChallengeCreated(id, msg.sender, targetAmount, c.endTime);
        return id;
    }

    function joinChallenge(uint256 id) external {
        Challenge storage c = challenges[id];
        if (block.timestamp >= c.endTime) revert SaveUpVault_ChallengeEnded();
        if (isParticipant(c, msg.sender)) revert SaveUpVault_AlreadyJoinedChallenge();

        c.participants.push(msg.sender);
        userChallenges[msg.sender].push(id);
        emit JoinedChallenge(id, msg.sender);
    }

    function contribute(uint256 id, uint256 amount) external {
        Challenge storage c = challenges[id];
        if (block.timestamp >= c.endTime) revert SaveUpVault_ChallengeEnded();
        if (!isParticipant(c, msg.sender)) revert SaveUpVault_NotParticipant();

        IERC20(asset()).safeTransferFrom(msg.sender, address(this), amount);
        depositToStrategies(amount);
        c.contributions[msg.sender] += amount;
        _mint(msg.sender, amount);
        emit Contributed(id, msg.sender, amount);

        if (!c.hasReachedGoal[msg.sender] && c.contributions[msg.sender] >= c.targetAmount) {
            c.hasReachedGoal[msg.sender] = true;
            emit GoalReached(id, msg.sender);

            if (c.firstToReach == address(0)) {
                c.firstToReach = msg.sender;
            }
        }
    }

    function claimReward(uint256 id) external {
        Challenge storage c = challenges[id];
        if (block.timestamp < c.endTime) revert SaveUpVault_ChallengeNotOver();
        if (!c.hasReachedGoal[msg.sender]) revert SaveUpVault_GoalNotReached();
        if (c.hasClaimedReward[msg.sender]) revert SaveUpVault_RewardAlreadyClaimed();

        c.hasClaimedReward[msg.sender] = true;
        uint256 baseReward = 1e18; // Replace with real reward logic
        uint256 bonus = (msg.sender == c.firstToReach) ? baseReward / 10 : 0;
        rewardToken.safeTransfer(msg.sender, baseReward + bonus);

        emit RewardClaimed(id, msg.sender);
    }

    function withdrawFromChallenge(uint256 id) external {
        Challenge storage c = challenges[id];
        if (block.timestamp < c.endTime) revert SaveUpVault_ChallengeNotOver();
        if (!c.hasReachedGoal[msg.sender]) revert SaveUpVault_GoalNotReached();
        if (c.contributions[msg.sender] == 0) revert SaveUpVault_NoBalanceToWithdraw();

        uint256 amount = c.contributions[msg.sender];
        c.contributions[msg.sender] = 0;
        withdrawFromStrategies(amount, msg.sender);
        _burn(msg.sender, amount);
        IERC20(asset()).safeTransfer(msg.sender, amount);

        emit Withdrawn(id, msg.sender, amount);
    }

    function depositToStrategies(uint256 amount) internal {
        uint256 perStrategy = amount / strategies.length;
        for (uint256 i = 0; i < strategies.length; i++) {
            IERC20(asset()).approve(address(strategies[i]), perStrategy);
            strategies[i].deposit(perStrategy);
        }
    }

    function withdrawFromStrategies(uint256 amount, address recipient) internal {
        uint256 perStrategy = amount / strategies.length;
        for (uint256 i = 0; i < strategies.length; i++) {
            strategies[i].withdraw(perStrategy, recipient);
        }
    }

    function isParticipant(Challenge storage c, address user) internal view returns (bool) {
        for (uint256 i = 0; i < c.participants.length; i++) {
            if (c.participants[i] == user) return true;
        }
        return false;
    }

    function getUserProgress(uint256 id, address user) external view returns (uint256 contribution, uint256 target) {
        Challenge storage c = challenges[id];
        return (c.contributions[user], c.targetAmount);
    }

    // === Fee configuration ===

    function _entryFeeBasisPoints() internal view override returns (uint256) {
        return 50; // 0.5%
    }

    function _exitFeeBasisPoints() internal view override returns (uint256) {
        return 50; // 0.5%
    }

    function setFeeReceiver(address _newFeeReceiver) external onlyOwner {
        if (_newFeeReceiver == address(0)) revert SaveUpVault_InvalidFeeReceiverAddress();
        feeReceiverAddress = _newFeeReceiver;
        emit FeeReceiverChanged(_newFeeReceiver);
    }

    // === Fee configuration ===

    function _entryFeeRecipient() internal view override returns (address) {
        return feeReceiverAddress;
    }

    function _exitFeeRecipient() internal view override returns (address) {
        return feeReceiverAddress;
    }
}