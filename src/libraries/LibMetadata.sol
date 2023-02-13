// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;

import {Base64} from "base64-sol/base64.sol";
import {SSTORE2} from "@0xsequence/sstore2/contracts/SSTORE2.sol";
import {StringsUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

import {LibHTMLRenderer} from "./LibHTMLRenderer.sol";
import {LibStorage, MetadataStorage, TokenStorage} from "./LibStorage.sol";
import "forge-std/console2.sol";

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
        string memory uriEncodedFullName = string.concat(
            ms().urlEncodedName,
            "%20",
            tokenIdString
        );

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
                    LibHTMLRenderer.generateDoubleURLEncodedHTML(
                        getAllScripts(tokenId)
                    ),
                    //","image":"
                    "%22,%22image%22:%22",
                    generatePreviewURI(tokenIdString),
                    //"}
                    "%22%7D"
                )
            );
    }

    function getAllScripts(
        uint256 tokenId
    ) public view returns (LibHTMLRenderer.ScriptRequest[] memory) {
        uint256 importsLength = ms().imports.length;

        LibHTMLRenderer.ScriptRequest[]
            memory scripts = new LibHTMLRenderer.ScriptRequest[](
                importsLength + 2
            );

        uint256 i = 0;
        unchecked {
            do {
                scripts[i] = ms().imports[i];
            } while (++i < importsLength);
        }

        // Add the double url encoded persistence meta script
        scripts[scripts.length - 2] = LibHTMLRenderer.ScriptRequest({
            scriptType: LibHTMLRenderer.ScriptType.JAVASCRIPT_URL_ENCODED,
            name: "",
            data: generateMetaScript(
                tokenId.toString(),
                ts().tokenIdToBlockDifficulty[tokenId]
            ),
            urlEncodedPrefix: new bytes(0),
            urlEncodedSuffix: new bytes(0)
        });

        // Add the base64 encoded token script
        scripts[scripts.length - 1] = LibHTMLRenderer.ScriptRequest({
            scriptType: LibHTMLRenderer.ScriptType.JAVASCRIPT_BASE64,
            name: "",
            data: SSTORE2.read(ms().scriptPointer),
            urlEncodedPrefix: new bytes(0),
            urlEncodedSuffix: new bytes(0)
        });

        return scripts;
    }

    /// @notice generate a url encoded preview URI for the token
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

    /// @notice generate the double url encoded meta script
    function generateMetaScript(
        string memory tokenId,
        uint256 blockDifficulty
    ) public view returns (bytes memory) {
        return
            bytes(
                string.concat(
                    //var persistence={blockDifficulty:"
                    "var%2520persistence=%257BblockDifficulty:%2522",
                    blockDifficulty.toString(),
                    //",tokenId:"
                    "%2522,tokenId:%2522",
                    tokenId,
                    //",timestamp:"
                    "%2522,timestamp:%2522",
                    block.timestamp.toString(),
                    //"};
                    "%2522%257D;"
                )
            );
    }
}
