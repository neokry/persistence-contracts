// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

interface IHTMLRenderer {
    struct ExternalScript {
        string name;
        uint8 scriptType;
    }

    function initilize(address owner) external;

    /// @notice Returns the HTML for the given script and imports
    function generateURI(
        ExternalScript[] calldata imports,
        bytes calldata script
    ) external view returns (string memory);
}
