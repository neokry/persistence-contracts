// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
//import "../src/MathBlocksToken/MathBlocksFactory.sol";
//import "../src/HTMLRenderers/MathCastlesRenderer.sol";
import "forge-std/console2.sol";

contract Deploy is Script {
    /*
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY_DEV");
        vm.startBroadcast(deployerPrivateKey);

        IHTMLRenderer renderer = new MathCastlesRenderer(
            0x16cc845d144A283D1b0687FBAC8B0601cC47A6C3,
            "p5.js 1.4.2"
        );

        MathBlocksFactory factory = new MathBlocksFactory(address(renderer));
        console2.log("factory:");
        console2.log(address(factory));

        console2.log("implementation:");
        console2.log(address(factory.implementation()));

        vm.stopBroadcast();
    }
    */
}
