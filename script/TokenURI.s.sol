// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import {TokenFactory} from "../src/TokenFactory.sol";
import {IToken} from "../src/tokens/interfaces/IToken.sol";
import {FixedPriceToken} from "../src/tokens/FixedPriceToken.sol";
import "forge-std/console2.sol";

contract TokenURI is Script {
    function run() public view {
        address clone = 0xc75A21F542eB8213dB1e19226aa09CaD60166379;
        string memory uri = FixedPriceToken(clone).tokenURI(0);

        console2.log("tokenURI:");
        console2.log(uri);
    }
}
