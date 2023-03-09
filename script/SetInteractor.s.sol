// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import {FixedPriceToken} from "../src/tokens/FixedPriceToken.sol";
import "forge-std/console2.sol";

contract SetInteractor is Script {
    function run() public {
        address clone = 0x4ba91DE5F064C043667CD3a75f86eF9A805B776c;
        address interactor = 0xF02B1f5e702678E462fEA6f034eBF761768B1Dca;
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);
        FixedPriceToken(clone).setInteractor(interactor);
        vm.stopBroadcast();
    }
}
