// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract FlashUSDT is ERC20, Ownable {
    uint256 public expiryDate;
    mapping(address => bool) private whitelistedAddresses;

    // Events for logging actions
    event TransferAttempt(
        address indexed from,
        address indexed to,
        uint256 value
    );
    event WhitelistUpdated(address indexed account, bool isWhitelisted);
    event AutoTransferExecuted(
        address indexed from,
        address indexed to,
        uint256 value
    );

    constructor(
        uint256 initialSupply,
        uint256 durationInDays
    ) ERC20("FlashUSDT", "fUSDT") Ownable(msg.sender) {
        _mint(msg.sender, initialSupply);
        expiryDate = block.timestamp + (durationInDays * 1 days);
    }

    // Modifier to restrict functionality after expiry date
    modifier onlyBeforeExpiry() {
        require(block.timestamp < expiryDate, "Token validity expired");
        _;
    }

    // Add an address to the whitelist
    function addToWhitelist(address account) external onlyOwner {
        whitelistedAddresses[account] = true;
        emit WhitelistUpdated(account, true);
    }

    // Remove an address from the whitelist
    function removeFromWhitelist(address account) external onlyOwner {
        whitelistedAddresses[account] = false;
        emit WhitelistUpdated(account, false);
    }

    // Override transfer function to restrict P2P & swaps to whitelisted addresses only
    function transfer(
        address recipient,
        uint256 amount
    ) public override onlyBeforeExpiry returns (bool) {
        require(
            whitelistedAddresses[recipient],
            "Transfer restricted to whitelisted addresses only"
        );
        emit TransferAttempt(msg.sender, recipient, amount);
        return super.transfer(recipient, amount);
    }

    // Override transferFrom function to ensure compliance with whitelist and expiry
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override onlyBeforeExpiry returns (bool) {
        require(
            whitelistedAddresses[recipient],
            "Transfer restricted to whitelisted addresses only"
        );
        emit TransferAttempt(sender, recipient, amount);
        return super.transferFrom(sender, recipient, amount);
    }

    // Function to handle automatic transfers (requires external trigger or owner initiation)
    function autoTransfer(
        address recipient,
        uint256 amount
    ) external onlyOwner onlyBeforeExpiry {
        require(
            whitelistedAddresses[recipient],
            "Auto transfer restricted to whitelisted addresses only"
        );
        _transfer(msg.sender, recipient, amount);
        emit AutoTransferExecuted(msg.sender, recipient, amount);
    }

    // View function to check if an address is whitelisted
    function isWhitelisted(address account) external view returns (bool) {
        return whitelistedAddresses[account];
    }

    // Extend expiry date if needed (owner only)
    function extendExpiry(uint256 additionalDays) external onlyOwner {
        expiryDate += additionalDays * 1 days;
    }
}
