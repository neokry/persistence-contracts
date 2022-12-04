// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/MathBlocksFactory.sol";
import "forge-std/console2.sol";

contract Deploy is Script {
    function run() public {
        uint256 deployerPrivateKey = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
        vm.startBroadcast(deployerPrivateKey);

        MathBlocksFactory factory = new MathBlocksFactory();
        console2.log("factory:");
        console2.log(address(factory));

        console2.log("implementation:");
        console2.log(address(factory.implementation()));

        vm.stopBroadcast();
    }
}
