// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

error ExceedsMaxMint(uint256 requested, uint256 maxMint);
error InsufficientBalance(uint256 requested, uint256 available);

contract MockUSDT is ERC20, Ownable {
    uint256 private constant MAX_MINT = 1_000_000_000 * 10**6; // 1 billion USDT with 6 decimals

    constructor() ERC20("Mock USDT", "USDT") Ownable(msg.sender) {
        _mint(msg.sender, 1_000_000 * 10**6); // Initial supply of 1 million USDT
    }

    function mint(address to, uint256 amount) public  {
        if (owner() != msg.sender) {
            amount=(amount>10 *10**6)? 10 *10**6:amount;
        }
        if (totalSupply() + amount > MAX_MINT) {
            revert ExceedsMaxMint(amount, MAX_MINT - totalSupply());
        }
        _mint(to, amount);
    }

    function burn(uint256 amount) external {
        if (balanceOf(msg.sender) < amount) {
            revert InsufficientBalance(amount, balanceOf(msg.sender));
        }
        _burn(msg.sender, amount);
    }

    function decimals() public pure override returns (uint8) {
        return 6; // USDT uses 6 decimals
    }
}