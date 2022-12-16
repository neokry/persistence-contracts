// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

interface IHTMLRenderer {
    struct FileType {
        string name;
        address fileSystem;
        uint8 fileType;
    }

    function generateURI(
        FileType[] calldata imports,
        string calldata script
    ) external view returns (string memory);
}
