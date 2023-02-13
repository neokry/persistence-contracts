// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "forge-std/Test.sol";
import {Base64URIDecoder} from "./utils/Base64URIDecoder.sol";
import {TokenFactory} from "../src/TokenFactory.sol";

import {FixedPriceTokenUtils} from "./utils/FixedPriceTokenUtils.sol";

contract HTMLRendererTest is Test, FixedPriceTokenUtils {
    function setUp() public {
        string memory GOERLI_RPC_URL = vm.envString("GOERLI_RPC_URL");
        vm.createSelectFork(GOERLI_RPC_URL);

        _setUp();

        vm.prank(factory);
        _initToken();
    }

    function testMetadata() public {
        vm.prank(owner);
        token.safeMint(owner);

        emit log_string(token.tokenURI(0));
    }
}
