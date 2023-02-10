// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface IInteractor {
    function isValid(
        address user,
        address tokenContract,
        uint256 tokenId,
        bytes memory validationData
    ) external view returns (bool);
}
