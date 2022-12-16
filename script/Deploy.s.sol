// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
//import "../src/MathBlocksToken/MathBlocksFactory.sol";
//import "../src/HTMLRenderers/ETHFSRenderer.sol";
import "forge-std/console2.sol";

contract Deploy is Script {
    function run() public {
        /*
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        IHTMLRenderer renderer = new ETHFSRenderer(
            0x5E348d0975A920E9611F8140f84458998A53af94,
            "p5.min.js.gz",
            "gunzipScripts-0.0.1.js"
        );

        MathBlocksFactory factory = new MathBlocksFactory(address(renderer));

        console2.log("renderer:");
        console2.log(address(renderer));

        console2.log("factory:");
        console2.log(address(factory));

        console2.log("o11y:");
        console2.log(address(factory.o11y()));

        console2.log("implementation:");
        console2.log(address(factory.implementation()));

        vm.stopBroadcast();
        */
    }
}
