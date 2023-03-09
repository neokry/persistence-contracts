// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import {LibHTMLRenderer} from "./libraries/LibHTMLRenderer.sol";

contract HTMLPreview {
    address immutable ethFS;

    constructor(address _ethFS) {
        ethFS = _ethFS;
    }

    function generateHTML(
        LibHTMLRenderer.ScriptRequest[] calldata scripts
    ) public view returns (string memory) {
        return
            string(
                LibHTMLRenderer.generateDoubleURLEncodedHTML(scripts, ethFS)
            );
    }
}
