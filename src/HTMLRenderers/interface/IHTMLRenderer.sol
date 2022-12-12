//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface IHTMLRenderer {
    struct HTMLURIParams {
        string script;
        string seed;
        string tokenId;
        string timestamp;
    }

    function generateHTMLURI(
        HTMLURIParams memory params
    ) external view returns (string memory);
}
