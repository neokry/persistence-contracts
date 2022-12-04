// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {Base64} from "base64-sol/base64.sol";
import {ILibraryStorage} from "./interfaces/ILibraryStorage.sol";

library HTMLGeneratorETHFS {
    struct HTMLURIParams {
        address libraryStorage;
        string libraryName;
        string script;
        string seed;
    }

    /**
     * @notice Construct an html URI.
     */
    function constructHTMLURI(
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
                                ILibraryStorage(params.libraryStorage)
                                    .readLibrary(params.libraryName),
                                'var seed=Number("',
                                params.seed,
                                '".slice(0,25));',
                                params.script,
                                "</script></head><body><main></main></body></html>"
                            )
                        )
                    )
                )
            );
    }
}
