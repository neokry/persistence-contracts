// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {HTMLPreview} from "../src/HTMLPreview.sol";

contract DeployHTML is Script {
    using Strings for uint256;

    string configFile;

    function _getKey(string memory key) internal view returns (address result) {
        (result) = abi.decode(
            vm.parseJson(configFile, string.concat(".", key)),
            (address)
        );
    }

    function run() public {
        uint256 chainID = vm.envUint("CHAIN_ID");
        console.log("CHAIN_ID", chainID);
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        configFile = vm.readFile(
            string.concat("./addresses/", Strings.toString(chainID), ".json")
        );

        address ethfs = _getKey("ETHFS");

        console2.log("~~~~~~~~~~ EthFS ADDRESS ~~~~~~~~~~~");
        console2.logAddress(ethfs);

        vm.startBroadcast(deployerPrivateKey);

        address htmlPreview = address(new HTMLPreview(ethfs));

        vm.stopBroadcast();

        string memory filePath = string(
            abi.encodePacked(
                "deploys/",
                chainID.toString(),
                ".html-preview.txt"
            )
        );

        vm.writeLine(
            filePath,
            string(
                abi.encodePacked("HTMLPreview: ", addressToString(htmlPreview))
            )
        );
    }

    function addressToString(
        address _addr
    ) private pure returns (string memory) {
        bytes memory s = new bytes(40);
        for (uint256 i = 0; i < 20; i++) {
            bytes1 b = bytes1(
                uint8(uint256(uint160(_addr)) / (2 ** (8 * (19 - i))))
            );
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2 * i] = char(hi);
            s[2 * i + 1] = char(lo);
        }
        return string(abi.encodePacked("0x", string(s)));
    }

    function char(bytes1 b) private pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }
}
