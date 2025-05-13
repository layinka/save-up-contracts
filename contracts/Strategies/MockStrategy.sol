// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./IStrategy.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract MockStrategy is IStrategy {
    using SafeERC20 for IERC20;

    error MockStrategy_CallerNotVault();
    error MockStrategy_InsufficientBalance();

    IERC20 public immutable asset;
    address public immutable vault; // Address of the SaveUpVault contract
    uint256 public totalDepositedAssets;
    uint256 public deploymentTime;

    // 2% monthly interest rate (2/100 = 0.02). Scaled by 1e18 for precision.
    uint256 public constant MONTHLY_INTEREST_RATE = 0.02 ether; 
    uint256 public constant MONTH_IN_SECONDS = 30 days;

    modifier onlyVault() {
        if (msg.sender != vault) revert MockStrategy_CallerNotVault();
        _;
    }

    constructor(address _asset, address _vaultAddress) {
        asset = IERC20(_asset);
        vault = _vaultAddress;
        deploymentTime = block.timestamp;
    }

    function deposit(uint256 amount) external override onlyVault {
        totalDepositedAssets += amount;
        asset.safeTransferFrom(msg.sender, address(this), amount);
    }

    function withdraw(uint256 amount, address recipient) external override onlyVault {
        if (totalAssets() < amount) revert MockStrategy_InsufficientBalance();
        // Calculate how much of the withdrawal is principal vs interest
        uint256 currentTotalAssets = totalAssets();
        uint256 principalToWithdraw = (amount * totalDepositedAssets) / currentTotalAssets;
        
        if (principalToWithdraw > totalDepositedAssets) {
            principalToWithdraw = totalDepositedAssets;
        }

        totalDepositedAssets -= principalToWithdraw;
        asset.safeTransfer(recipient, amount);
    }

    function totalAssets() public view override returns (uint256) {
        if (totalDepositedAssets == 0) {
            return 0;
        }
        uint256 timePassed = block.timestamp - deploymentTime;
        uint256 monthsPassed = timePassed / MONTH_IN_SECONDS;

        // Simple interest calculation: P * (1 + r*t)
        // Interest for the period = P * r * t
        uint256 interest = (totalDepositedAssets * MONTHLY_INTEREST_RATE * monthsPassed) / 1 ether;
        return totalDepositedAssets + interest;
    }
}
