// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "forge-std/console2.sol";

import {TokenFactory} from "../src/TokenFactory.sol";
import {FixedPriceToken} from "../src/tokens/FixedPriceToken.sol";
import {HTMLRenderer} from "../src/renderer/HTMLRenderer.sol";
import {ETHFSAdapter} from "../src/fileSystemAdapters/ETHFSAdapter.sol";
import {FeeManager} from "../src/FeeManager.sol";

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

        address feeManager = address(
            new FeeManager(1000, 0xa471C9508Acf13867282f36cfCe5c41D719ab78B)
        );

        console2.log("feeManager:");
        console2.log(feeManager);

        FixedPriceToken impl = new FixedPriceToken(
            address(factory),
            o11y,
            feeManager
        );

        console2.log("impl:");
        console2.log(address(impl));

        ETHFSAdapter ethFSAdapter = new ETHFSAdapter(
            0x9746fD0A77829E12F8A9DBe70D7a322412325B91
        );

        console2.log("ethFS:");
        console2.log(address(ethFSAdapter));

        // Register deployments
        factory.registerDeployment(address(renderer));
        factory.registerDeployment(address(impl));

        vm.stopBroadcast();
    }
}
