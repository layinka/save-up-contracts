// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./IStrategy.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@aave/core-v3/contracts/interfaces/IPool.sol";

contract AaveV3Strategy is IStrategy {
    IPool public aavePool;
    IERC20 public asset;
    address public aToken;

    constructor(address _pool, address _asset, address _aToken) {
        aavePool = IPool(_pool);
        asset = IERC20(_asset);
        aToken = _aToken;
    }

    function deposit(uint256 amount) external override {
        asset.approve(address(aavePool), amount);
        aavePool.supply(address(asset), amount, address(this), 0);
    }

    function withdraw(uint256 amount, address recipient) external override {
        aavePool.withdraw(address(asset), amount, recipient);
    }

    function totalAssets() external view override returns (uint256) {
        return IERC20(aToken).balanceOf(address(this));
    }
}
