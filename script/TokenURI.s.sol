// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import {TokenFactory} from "../src/TokenFactory.sol";
import {IToken} from "../src/tokens/interfaces/IToken.sol";
import {FixedPriceToken} from "../src/tokens/FixedPriceToken.sol";
import {IHTMLRenderer} from "../src/renderer/interfaces/IHTMLRenderer.sol";
import {HTMLRendererStorageV1} from "../src/renderer/storage/HTMLRendererStorageV1.sol";
import "forge-std/console2.sol";

contract TokenURI is Script {
    function run() public view {
        address clone = 0xBf92F07FFDF7588543eB1fF96383D6202e341E55;
        string memory uri = FixedPriceToken(clone).generateFullScript(0);

        console2.log("tokenURI:");
        console2.log(uri);
    }
}
