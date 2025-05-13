// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.20;

// import "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
// import "@openzeppelin/contracts/access/Ownable.sol";
// import "./Strategies/IStrategy.sol";

// contract SaveUpVaultOLd is ERC4626, Ownable {
//     IStrategy[] public strategies;

//     constructor(
//         IERC20 asset_,
//         string memory name_,
//         string memory symbol_
//     ) ERC20(name_, symbol_) ERC4626(asset_) {}

//     // Owner adds a strategy
//     function addStrategy(address strategy) external onlyOwner {
//         strategies.push(IStrategy(strategy));
//     }

//     // Distribute deposit among strategies equally
//     function _depositToStrategies(uint256 amount) internal {
//         uint256 splitAmount = amount / strategies.length;
//         for (uint i = 0; i < strategies.length; i++) {
//             asset().approve(address(strategies[i]), splitAmount);
//             strategies[i].deposit(splitAmount);
//         }
//     }

//     // Withdraw evenly from strategies
//     function _withdrawFromStrategies(uint256 amount, address to) internal {
//         uint256 splitAmount = amount / strategies.length;
//         for (uint i = 0; i < strategies.length; i++) {
//             strategies[i].withdraw(splitAmount, to);
//         }
//     }

//     // Override deposit
//     function afterDeposit(uint256 amount, uint256) internal override {
//         _depositToStrategies(amount);
//     }

//     // Override withdraw
//     function beforeWithdraw(uint256 amount, uint256) internal override {
//         _withdrawFromStrategies(amount, address(this));
//     }

//     // Implement totalAssets to sum all strategies' balances
//     function totalAssets() public view override returns (uint256 total) {
//         for (uint i = 0; i < strategies.length; i++) {
//             total += strategies[i].totalAssets();
//         }
//     }
// }
