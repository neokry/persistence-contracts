// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

import {TokenFactory} from "../src/TokenFactory.sol";
import {IToken} from "../src/tokens/interfaces/IToken.sol";
import {IFixedPriceToken} from "../src/tokens/interfaces/IFixedPriceToken.sol";
import {InitArgs} from "../src/tokens/FixedPriceTokenInitilizer.sol";
import {LibHTMLRenderer} from "../src/libraries/LibHTMLRenderer.sol";

contract Mint is Script {
    using Strings for uint256;

    string configFile;

    function _getKey(string memory key) internal view returns (address result) {
        (result) = abi.decode(vm.parseJson(configFile, key), (address));
    }

    function run() public {
        uint256 chainID = vm.envUint("CHAIN_ID");
        console.log("CHAIN_ID", chainID);
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        configFile = vm.readFile(
            string.concat("./addresses/", Strings.toString(chainID), ".json")
        );

        address owner = 0xa471C9508Acf13867282f36cfCe5c41D719ab78B;
        address factory = _getKey("Factory");
        address tokenImpl = _getKey("FixedPriceTokenImpl");

        vm.startBroadcast(deployerPrivateKey);

        string
            memory base64EncodedScript = "bGV0IHBsYW5ldHM9W10seG9mZj0wO2Z1bmN0aW9uIHNldHVwKCl7Y29sb3JNb2RlKEhTQiksY3JlYXRlQ2FudmFzKDQwMCw0MDApLGFuZ2xlTW9kZShERUdSRUVTKTtwbGFuZXRzPVtuZXcgUGxhbmV0KDYwLDIwMCwzMDAsMTIwLDEsODApLG5ldyBQbGFuZXQoODAsMjAwLDIwMCwyMDAsMiw3MCksbmV3IFBsYW5ldCgyMCwyMDAsMTgwLDE0MCw0LDMwMCksbmV3IFBsYW5ldCgxMCwyMDAsMjAwLDE0MCwzLDIxMCksbmV3IFBsYW5ldCgyNiwyMDAsMTQwLDI0MCwxLDExMSksbmV3IFBsYW5ldCgyMDAsMjAwLDIwMCwwLDEsMjIwKSxdfWZ1bmN0aW9uIGRyYXcoKXtiYWNrZ3JvdW5kKDApLGNyZWF0ZUdyaWQoKSxwbGFuZXRzLm1hcCgkPT4kLmRyYXcoKSl9ZnVuY3Rpb24gY3JlYXRlR3JpZCgpe2xldCAkPTMqbm9pc2UoeG9mZis9LjAxKTtmb3IobGV0IHQ9MDt0PDM2MDt0Kz0kKXtsZXQgaT13aWR0aC8yK3dpZHRoKmNvcyh0KSxzPWhlaWdodC8yK3dpZHRoKnNpbih0KTtzdHJva2UoMTAwLDEwMCwxMDApLGxpbmUod2lkdGgvMixoZWlnaHQvMixpLHMpfX1jbGFzcyBQbGFuZXR7Y29uc3RydWN0b3IoJCx0LGkscyxhLGUpe3RoaXMucmFkaXVzPSQsdGhpcy54PXQsdGhpcy55PWksdGhpcy5zY2FsYXI9cyx0aGlzLmFuZ2xlPTAsdGhpcy5zcGVlZD1hLHRoaXMuY29sb3I9ZX1kcmF3KCl7bGV0ICQ9dGhpcy54LXRoaXMucmFkaXVzLHQ9dGhpcy55LXRoaXMucmFkaXVzLGk9dGhpcy54K3RoaXMucmFkaXVzLHM9dGhpcy55K3RoaXMucmFkaXVzLGE9ZHJhd2luZ0NvbnRleHQuY3JlYXRlUmFkaWFsR3JhZGllbnQoJCx0LGkscywyMDAsMjApLGU9Y29sb3IoMTAwLDEwMCwxMDApLGw9Y29sb3IoMTAwLDEwMCwxMDApO2EuYWRkQ29sb3JTdG9wKDAsZS50b1N0cmluZygpKSxhLmFkZENvbG9yU3RvcCguNSxsLnRvU3RyaW5nKCkpLGEuYWRkQ29sb3JTdG9wKDEsZS50b1N0cmluZygpKSxkcmF3aW5nQ29udGV4dC5maWxsU3R5bGU9YSxub1N0cm9rZSgpO2xldCBuPXRoaXMueCt0aGlzLnNjYWxhcipjb3ModGhpcy5hbmdsZSkscj10aGlzLnkrdGhpcy5zY2FsYXIqc2luKHRoaXMuYW5nbGUpO2VsbGlwc2UobixyLHRoaXMucmFkaXVzLHRoaXMucmFkaXVzKSxkcmF3aW5nQ29udGV4dC5maWxsU3R5bGU9IndoaXRlIix0aGlzLmFuZ2xlKz10aGlzLnNwZWVkfX0=";
        string
            memory previewBaseURI = "https://goerli.persistence.wtf/api/preview/";

        LibHTMLRenderer.ScriptRequest[]
            memory imports = new LibHTMLRenderer.ScriptRequest[](2);

        imports[0] = LibHTMLRenderer.ScriptRequest({
            name: "p5-1.5.0.min.js.gz",
            scriptType: LibHTMLRenderer.ScriptType.JAVASCRIPT_GZIP,
            data: new bytes(0),
            urlEncodedPrefix: new bytes(0),
            urlEncodedSuffix: new bytes(0)
        });

        imports[1] = LibHTMLRenderer.ScriptRequest({
            name: "gunzipScripts-0.0.1.js",
            scriptType: LibHTMLRenderer.ScriptType.JAVASCRIPT_BASE64,
            data: new bytes(0),
            urlEncodedPrefix: new bytes(0),
            urlEncodedSuffix: new bytes(0)
        });

        InitArgs memory args = InitArgs({
            // Token info
            fundsRecipent: owner,
            maxSupply: 10,
            artistProofCount: 1,
            // Metadata
            symbol: "TST",
            name: "Test",
            urlEncodedName: "Test",
            urlEncodedDescription: "Test%20description",
            urlEncodedPreviewBaseURI: previewBaseURI,
            base64EncodedScript: base64EncodedScript,
            interactor: address(0),
            imports: imports,
            // Sale info
            presaleStartTime: 0,
            presaleEndTime: 0,
            presalePrice: 0,
            publicPrice: 1 ether,
            publicStartTime: 0,
            publicEndTime: 0,
            maxPresaleMintsPerAddress: 1,
            merkleRoot: bytes32(0)
        });

        address clone = TokenFactory(factory).create(
            tokenImpl,
            abi.encode(args)
        );

        IToken(clone).safeMint(owner);

        console2.log("clone:", clone);

        vm.stopBroadcast();
    }
}
