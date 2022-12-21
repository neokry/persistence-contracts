// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "forge-std/console2.sol";

import {TokenFactory} from "../src/TokenFactory.sol";
import {FixedPriceToken} from "../src/tokens/FixedPriceToken.sol";
import {HTMLRenderer} from "../src/renderer/HTMLRenderer.sol";
import {ETHFSAdapter} from "../src/fileSystemAdapters/ETHFSAdapter.sol";

contract Deploy is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Deploy Contracts

        TokenFactory factory = new TokenFactory();

        console2.log("factory:");
        console2.log(address(factory));

        HTMLRenderer renderer = new HTMLRenderer(address(factory));

        console2.log("renderer:");
        console2.log(address(renderer));

        FixedPriceToken impl = new FixedPriceToken(
            address(factory),
            address(factory.o11y())
        );

        console2.log("impl:");
        console2.log(address(impl));

        ETHFSAdapter ethFSAdapter = new ETHFSAdapter(
            0x5E348d0975A920E9611F8140f84458998A53af94
        );

        console2.log("ethFS:");
        console2.log(address(ethFSAdapter));

        // Register deployments

        factory.registerDeployment(address(renderer));
        factory.registerDeployment(address(impl));

        vm.stopBroadcast();
    }
}
