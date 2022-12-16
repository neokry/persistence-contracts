// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ILibraryStorage} from "../interfaces/ILibraryStorage.sol";
import {IFileSystemAdapter} from "./interfaces/IFileSystemAdapter.sol";

contract MathCastlesAdapter is IFileSystemAdapter {
    address immutable libraryStorage;

    constructor(address _libraryStorage) {
        libraryStorage = _libraryStorage;
    }

    function getFile(
        string calldata fileName
    ) external view returns (string memory) {
        return ILibraryStorage(libraryStorage).readLibrary(fileName);
    }
}
