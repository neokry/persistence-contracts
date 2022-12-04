// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {Base64} from "base64-sol/base64.sol";
import {ILibraryStorage} from "./interfaces/ILibraryStorage.sol";

library HTMLGeneratorMC {
    struct HTMLURIParams {
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
                                ILibraryStorage(
                                    0x16cc845d144A283D1b0687FBAC8B0601cC47A6C3
                                ).readLibrary("p5.js 1.4.2"),
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
