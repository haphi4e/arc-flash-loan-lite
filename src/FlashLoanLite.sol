// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

interface IFlashBorrower {
    function onFlashLoan(uint256 amount, uint256 fee, bytes calldata data) external;
}

contract FlashLoanLite {
    IERC20 public immutable usdc;
    address public owner;
    uint256 public feeBps = 9; // 0.09%
    uint256 public totalLoaned;

    event FlashLoan(address indexed borrower, uint256 amount, uint256 fee);

    constructor(address _usdc) {
        require(_usdc != address(0), "BAD_USDC");
        usdc = IERC20(_usdc);
        owner = msg.sender;
    }

    modifier onlyOwner() { require(msg.sender == owner, "NOT_OWNER"); _; }

    function deposit(uint256 amount) external {
        require(usdc.transferFrom(msg.sender, address(this), amount), "DEPOSIT_FAILED");
    }

    function flashLoan(uint256 amount, bytes calldata data) external {
        uint256 balBefore = usdc.balanceOf(address(this));
        require(amount <= balBefore, "INSUFFICIENT");
        uint256 fee = (amount * feeBps) / 10000;
        require(usdc.transfer(msg.sender, amount), "LEND_FAILED");
        IFlashBorrower(msg.sender).onFlashLoan(amount, fee, data);
        require(usdc.balanceOf(address(this)) >= balBefore + fee, "NOT_REPAID");
        totalLoaned += amount;
        emit FlashLoan(msg.sender, amount, fee);
    }

    function withdraw(uint256 amount) external onlyOwner {
        require(usdc.transfer(msg.sender, amount), "WITHDRAW_FAILED");
    }

    function setFee(uint256 _feeBps) external onlyOwner { feeBps = _feeBps; }
}
