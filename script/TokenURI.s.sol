// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import {TokenFactory} from "../src/TokenFactory.sol";
import {IToken} from "../src/tokens/interfaces/IToken.sol";
import {FixedPriceToken} from "../src/tokens/FixedPriceToken.sol";
import "forge-std/console2.sol";

contract TokenURI is Script {
    function run() public view {
        address clone = 0xb22d18bb856A2a4917468085734494c591D06A62;
        string memory uri = FixedPriceToken(clone).tokenURI(0);

        console2.log("tokenURI:");
        console2.log(uri);
    }
}
