//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IFileSystemAdapter {
    function getFile(
        string calldata fileName
    ) external view returns (string memory);
}
