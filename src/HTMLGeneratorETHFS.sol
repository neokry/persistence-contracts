// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {Base64} from "base64-sol/base64.sol";
import {ILibraryStorage} from "./interfaces/ILibraryStorage.sol";
import {IFileStore} from "ethfs/IFileStore.sol";

library HTMLGeneratorETHFS {
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
        IFileStore fileStore = IFileStore(
            0x5E348d0975A920E9611F8140f84458998A53af94
        );

        string memory gunzip = string.concat(
            '<script src="data:text/javascript;base64,',
            fileStore.getFile("gunzipScripts-0.0.1.js").read(),
            '"></script>'
        );

        string memory p5 = string.concat(
            '<script type="text/javascript+gzip" src="data:text/javascript;base64,',
            fileStore.getFile("p5.min.js.gz").read(),
            '"></script>'
        );

        return
            string(
                abi.encodePacked(
                    "data:text/html;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '<html><head><style type="text/css"> *{padding: 0; margin: 0;}</style>',
                                p5,
                                gunzip,
                                '<script>var seed=Number("',
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
