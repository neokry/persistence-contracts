// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IFileSystemAdapter} from "../../../src/fileSystemAdapters/interfaces/IFileSystemAdapter.sol";

contract MockFileSystem is IFileSystemAdapter {
    function getFile(
        string calldata fileName
    ) external pure override returns (string memory) {
        return fileName;
    }
}
