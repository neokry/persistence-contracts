//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IHTMLRenderer {
    struct HTMLURIParams {
        string script;
        string seed;
    }

    function generateHTMLURI(
        HTMLURIParams memory params
    ) external view returns (string memory);
}
