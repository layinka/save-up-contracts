// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

error ExceedsMaxCap(uint256 requested, uint256 available);
error NotAuthorized(address account, bytes32 role);

contract SaveUpToken is ERC20Pausable, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    
    uint256 private constant MAX_CAP = 100_000_000_000 * 10**18; // 100 Billion tokens

    constructor() ERC20("SaveUp Token", "SUP") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
    }

    function mint(address to, uint256 amount) external {
        if (!hasRole(MINTER_ROLE, msg.sender)) {
            revert NotAuthorized(msg.sender, MINTER_ROLE);
        }
        
        if (totalSupply() + amount > MAX_CAP) {
            revert ExceedsMaxCap(amount, MAX_CAP - totalSupply());
        }
        
        _mint(to, amount);
    }

    function pause() external {
        if (!hasRole(PAUSER_ROLE, msg.sender)) {
            revert NotAuthorized(msg.sender, PAUSER_ROLE);
        }
        _pause();
    }

    function unpause() external {
        if (!hasRole(PAUSER_ROLE, msg.sender)) {
            revert NotAuthorized(msg.sender, PAUSER_ROLE);
        }
        _unpause();
    }

    // Override required by Solidity for multiple inheritance
    function _update(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20Pausable) {
        super._update(from, to, amount);
    }
}