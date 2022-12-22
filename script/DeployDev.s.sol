// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "forge-std/console2.sol";

import {TokenFactory} from "../src/TokenFactory.sol";
import {FixedPriceToken} from "../src/tokens/FixedPriceToken.sol";
import {HTMLRenderer} from "../src/renderer/HTMLRenderer.sol";
import {MathCastlesAdapter} from "../src/fileSystemAdapters/MathCastlesAdapter.sol";

contract Deploy is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY_DEV");
        vm.startBroadcast(deployerPrivateKey);

        // Deploy Contracts
        TokenFactory factory = new TokenFactory();

        console2.log("factory:");
        console2.log(address(factory));

        HTMLRenderer renderer = new HTMLRenderer(address(factory));

        console2.log("renderer:");
        console2.log(address(renderer));

        address o11y = address(factory.o11y());

        console2.log("o11y:");
        console2.log(address(o11y));

        FixedPriceToken impl = new FixedPriceToken(address(factory), o11y);

        console2.log("impl:");
        console2.log(address(impl));

        MathCastlesAdapter mcAdapter = new MathCastlesAdapter(
            0x16cc845d144A283D1b0687FBAC8B0601cC47A6C3
        );

        console2.log("mcAdapter:");
        console2.log(address(mcAdapter));

        // Register deployments
        factory.registerDeployment(address(renderer));
        factory.registerDeployment(address(impl));

        vm.stopBroadcast();
    }
}
