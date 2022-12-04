// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {Base64} from "base64-sol/base64.sol";
import {ILibraryStorage} from "./ILibraryStorage.sol";
import {IHTMLRenderer} from "./interface/IHTMLRenderer.sol";

contract MathCastlesRenderer is IHTMLRenderer {
    address immutable libraryStorage;
    string libraryName;

    constructor(address _libraryStorage, string memory _libraryName) {
        libraryStorage = _libraryStorage;
        libraryName = _libraryName;
    }

    /**
     * @notice Construct an html URI.
     */
    function generateHTMLURI(
        HTMLURIParams memory params
    ) public view returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "data:text/html;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '<html><head><style type="text/css"> *{padding: 0; margin: 0;}</style><script>',
                                ILibraryStorage(libraryStorage).readLibrary(
                                    libraryName
                                ),
                                'var seed=Number("',
                                params.seed,
                                '".slice(0,20));',
                                params.script,
                                "</script></head><body><main></main></body></html>"
                            )
                        )
                    )
                )
            );
    }
}
