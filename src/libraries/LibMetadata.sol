// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;

import {Base64} from "base64-sol/base64.sol";
import {SSTORE2} from "@0xsequence/sstore2/contracts/SSTORE2.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

import {IHTMLRenderer} from "../renderer/interfaces/IHTMLRenderer.sol";
import {LibStorage, MetadataStorage, TokenStorage} from "./LibStorage.sol";

library LibMetadata {
    using Strings for uint256;

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
        string memory fullName = string(
            abi.encodePacked(ms().name, " ", tokenId)
        );
        bytes32 blockHash = ts().tokenIdToPreviousBlockHash[tokenId];

        return
            string.concat(
                "data:application/json;base64,",
                Base64.encode(
                    bytes(
                        string.concat(
                            '{"name":"',
                            fullName,
                            '", "description":"',
                            ms().description,
                            '", "animation_url": "',
                            IHTMLRenderer(ts().htmlRenderer).generateURI(
                                ms().imports,
                                generateFullScript(tokenIdString, blockHash)
                            ),
                            '", "image": "',
                            generatePreviewURI(tokenIdString),
                            '"}'
                        )
                    )
                )
            );
    }

    /// @notice generate a preview URI for the token
    function generatePreviewURI(
        string memory tokenId
    ) public view returns (string memory) {
        return
            string.concat(
                ms().previewBaseURI,
                uint256(uint160(address(this))).toHexString(20),
                "/",
                tokenId
            );
    }

    /// @notice generate the full script for the token
    function generateFullScript(
        string memory tokenId,
        bytes32 blockHash
    ) public view returns (bytes memory) {
        return
            bytes(
                string.concat(
                    '<script>var persistence={blockHash:"',
                    uint256(blockHash).toString(),
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
