// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import {Base64} from "base64-sol/base64.sol";
import {IFileStore} from "ethfs/IFileStore.sol";
import {IHTMLRenderer} from "./interface/IHTMLRenderer.sol";

contract ETHFSRenderer is IHTMLRenderer {
    address immutable fileStoreAddress;
    string libraryName;
    string gzipName;

    constructor(
        address _fileStoreAddress,
        string memory _libraryName,
        string memory _gzipName
    ) {
        fileStoreAddress = _fileStoreAddress;
        libraryName = _libraryName;
        gzipName = _gzipName;
    }

    /**
     * @notice Construct an html URI.
     */
    function generateHTMLURI(
        HTMLURIParams memory params
    ) public view returns (string memory) {
        IFileStore fileStore = IFileStore(fileStoreAddress);

        string memory gunzip = string.concat(
            '<script src="data:text/javascript;base64,',
            fileStore.getFile(gzipName).read(),
            '"></script>'
        );

        string memory p5 = string.concat(
            '<script type="text/javascript+gzip" src="data:text/javascript;base64,',
            fileStore.getFile(libraryName).read(),
            '"></script>'
        );

        return
            string.concat(
                "data:text/html;base64,",
                Base64.encode(
                    bytes(
                        string.concat(
                            '<html><head><style type="text/css"> *{padding: 0; margin: 0;}</style>',
                            p5,
                            gunzip,
                            '<script>var seed=Number("',
                            params.seed,
                            '".slice(0,20));var tokenId="',
                            params.tokenId,
                            '";var timestamp=Number("',
                            params.timestamp,
                            '");',
                            params.script,
                            "</script></head><body><main></main></body></html>"
                        )
                    )
                )
            );
    }
}

//0x5E348d0975A920E9611F8140f84458998A53af94
//"gunzipScripts-0.0.1.js"
//"p5.min.js.gz"
