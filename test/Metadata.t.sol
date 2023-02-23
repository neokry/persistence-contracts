// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "forge-std/Test.sol";
import {Base64URIDecoder} from "./utils/Base64URIDecoder.sol";
import {TokenFactory} from "../src/TokenFactory.sol";

import {FixedPriceTokenUtils} from "./utils/FixedPriceTokenUtils.sol";

contract HTMLRendererTest is Test, FixedPriceTokenUtils {
    function setUp() public {
        _setUp();

        vm.prank(factory);
        _initToken(10);
    }

    function testFork_tokenURI() public {
        vm.prank(owner);
        token.safeMint(owner);
        token.tokenURI(0);
    }
}
