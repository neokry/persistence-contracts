// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;

abstract contract FixedPriceTokenStorageV2 {
    /// @notice interactor address for the contract
    address public interactor;

    /// @notice interaction state for the token
    ///@dev tokenId => sstore2 storage pointer
    mapping(uint256 => address) public interactionState;
}
