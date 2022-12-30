// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IFileStore} from "ethfs/IFileStore.sol";
import {IContentStore} from "ethfs/IContentStore.sol";
import {File, Content} from "ethfs/File.sol";

contract MockFileSystem is IFileStore {
    function getFile(
        string calldata fileName
    ) external pure override returns (File memory) {
        Content[] memory contents = new Content[](1);
        contents[0] = Content({checksum: 0x0, pointer: address(0)});
        return File({contents: contents, size: 5});
    }

    function contentStore() external view override returns (IContentStore) {}

    function files(
        string memory filename
    ) external view override returns (bytes32 checksum) {}

    function fileExists(
        string memory filename
    ) external view override returns (bool) {}

    function getChecksum(
        string memory filename
    ) external view override returns (bytes32 checksum) {}

    function createFile(
        string memory filename,
        bytes32[] memory checksums
    ) external override returns (File memory file) {}

    function createFile(
        string memory filename,
        bytes32[] memory checksums,
        bytes memory extraData
    ) external override returns (File memory file) {}

    function deleteFile(string memory filename) external override {}
}
