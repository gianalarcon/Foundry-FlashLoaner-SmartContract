// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import "solmate/tokens/ERC20.sol";
import "solmate/utils/ReentrancyGuard.sol";

contract Flashloaner is ReentrancyGuard {
    ERC20 public immutable damnValToken;
    uint256 public poolBalance;

    address owner;

    modifier onlyOwner() {
        require(msg.sender == owner, "No owner");
        _;
    }

    error TokenAddressCannotBeZero();

    constructor(address tokenAddress) {
        if (tokenAddress == address(0)) revert TokenAddressCannotBeZero();
        damnValToken = ERC20(tokenAddress);
    }

    error MustDepositOneTokenMinimum();

    function depositTokens(uint256 amount) external nonReentrant {
        if (amount == 0) revert MustDepositOneTokenMinimum();
        damnValToken.transferFrom(msg.sender, address(this), amount);
        poolBalance = poolBalance + amount;
    }

    error MustBorrowOneTokenMinimum();
    error NotEnoughTokenInPool();
    error FlashLoanHasNotBeenPaidBack();

    function flashLoan(uint borrowAmount) external nonReentrant {
        if (borrowAmount == 0) revert MustBorrowOneTokenMinimum();

        uint256 balanceBefore = damnValToken.balanceOf(address(this));
        if (balanceBefore < borrowAmount) revert NotEnoughTokenInPool();

        // Ensure by the protocol via the 'depositToken' function
        assert(poolBalance == balanceBefore);

        damnValToken.transfer(msg.sender, borrowAmount);

        IReceiver(msg.sender).receiveTokens(
            address(damnValToken),
            borrowAmount
        );

        uint256 balanceAfter = damnValToken.balanceOf(address(this));
        if (balanceAfter < balanceBefore) revert FlashLoanHasNotBeenPaidBack();
        poolBalance = balanceAfter;
    }

    function updateOwner(address newOwner) public onlyOwner {
        owner = newOwner;
    }

    function echoSender() public view returns (address) {
        return msg.sender;
    }
}

interface IReceiver {
    function receiveTokens(address tokenAddress, uint256 amount) external;
}
