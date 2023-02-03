// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {IFeeManager} from "./interfaces/IFeeManager.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract FeeManager is Ownable, IFeeManager {
    mapping(address => uint256) public feeOverride;
    uint256 public defaultFeeBPS;

    event FeeOverrideSet(address indexed, uint256 indexed);

    error FeeTooHigh(uint256 amountBPS);

    constructor(uint256 _defaultFeeBPS, address feeManagerAdmin) {
        defaultFeeBPS = _defaultFeeBPS;
        _transferOwnership(feeManagerAdmin);
    }

    function setDefaultFee(uint256 amountBPS) external onlyOwner {
        if (amountBPS > 2000) revert FeeTooHigh(amountBPS);
        defaultFeeBPS = amountBPS;
    }

    function setFeeOverride(
        address mediaContract,
        uint256 amountBPS
    ) external onlyOwner {
        if (amountBPS > 2000) revert FeeTooHigh(amountBPS);
        feeOverride[mediaContract] = amountBPS;
        emit FeeOverrideSet(mediaContract, amountBPS);
    }

    function getWithdrawFeesBPS(
        address mediaContract
    ) external view returns (address payable, uint256) {
        if (feeOverride[mediaContract] > 0) {
            return (payable(owner()), feeOverride[mediaContract]);
        }
        return (payable(owner()), defaultFeeBPS);
    }
}
