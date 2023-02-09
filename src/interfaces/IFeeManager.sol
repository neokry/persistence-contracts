// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IFeeManager {
    function getWithdrawFeesBPS(
        address sender
    ) external view returns (address payable, uint256);
}
