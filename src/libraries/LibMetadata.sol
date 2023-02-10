// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;

import {Base64} from "base64-sol/base64.sol";
import {SSTORE2} from "@0xsequence/sstore2/contracts/SSTORE2.sol";
import {StringsUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

import {LibHTMLRenderer} from "./LibHTMLRenderer.sol";
import {LibStorage, MetadataStorage, TokenStorage} from "./LibStorage.sol";

library LibMetadata {
    using StringsUpgradeable for uint256;

    function ms() internal pure returns (MetadataStorage storage) {
        return LibStorage.metadataStorage();
    }

    function ts() internal pure returns (TokenStorage storage) {
        return LibStorage.tokenStorage();
    }

    /// @notice contruct a generic data URI from token data
    function genericDataURI(
        uint256 tokenId
    ) public view returns (string memory) {
        string memory tokenIdString = tokenId.toString();
        string memory uriEncodedFullName = string(
            abi.encodePacked(ms().urlEncodedName, "%20", tokenId)
        );
        uint256 blockDifficulty = ts().tokenIdToBlockDifficulty[tokenId];

        LibHTMLRenderer.ScriptRequest[] memory imports = ms().imports;

        imports[imports.length] = LibHTMLRenderer.ScriptRequest({
            scriptType: LibHTMLRenderer.ScriptType.JAVASCRIPT_BASE64,
            name: "",
            data: generateFullScript(tokenIdString, blockDifficulty),
            urlEncodedPrefix: new bytes(0),
            urlEncodedSuffix: new bytes(0)
        });

        return
            string(
                abi.encodePacked(
                    "data:application/json,",
                    //{"name":"
                    "%7B%22name%22:%22",
                    uriEncodedFullName,
                    //","description":"
                    "%22,%22description%22:%22",
                    ms().urlEncodedDescription,
                    //'","animation_url":"',
                    "%22,%22animation_url%22:%22",
                    LibHTMLRenderer.generateURLSafeHTML(
                        imports,
                        ms().bufferSize
                    ),
                    //","image":"
                    "%22,%22image%22:%22",
                    generatePreviewURI(tokenIdString),
                    //"}
                    "%22%7D"
                )
            );
    }

    /// @notice generate a preview URI for the token
    function generatePreviewURI(
        string memory tokenId
    ) public view returns (string memory) {
        return
            string.concat(
                ms().urlEncodedPreviewBaseURI,
                uint256(uint160(address(this))).toHexString(20),
                "/",
                tokenId
            );
    }

    /// @notice generate the full script for the token
    function generateFullScript(
        string memory tokenId,
        uint256 blockDifficulty
    ) public view returns (bytes memory) {
        return
            bytes(
                string.concat(
                    '<script>var persistence={blockDifficulty:"',
                    blockDifficulty.toString(),
                    '",tokenId:"',
                    tokenId,
                    '",timestamp:"',
                    block.timestamp.toString(),
                    '"};',
                    string(SSTORE2.read(ms().scriptPointer)),
                    "</script>"
                )
            );
    }
}
