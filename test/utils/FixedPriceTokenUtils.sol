// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import {LibHTMLRenderer} from "../../src/libraries/LibHTMLRenderer.sol";
import {InitArgs} from "../../src/tokens/FixedPriceTokenInitilizer.sol";
import {FixedPriceToken} from "../../src/tokens/FixedPriceToken.sol";
import {Observability} from "../../src/observability/Observability.sol";
import {TokenFactory} from "../../src/TokenFactory.sol";
import {FeeManager} from "../../src/FeeManager.sol";
import {TokenProxy} from "../../src/TokenProxy.sol";

abstract contract FixedPriceTokenUtils {
    FixedPriceToken token;
    address factory = address(1);
    address owner = address(2);
    address user = address(3);
    address otherUser = address(4);
    address presaleUser = 0xa471C9508Acf13867282f36cfCe5c41D719ab78B;
    address treasury = address(8);
    address ethfs = 0x5E348d0975A920E9611F8140f84458998A53af94;
    address tokenImplUpgrade;
    uint64 startTime = 0;
    uint64 endTime = 0;

    string base64EncodedScript =
        "bGV0IHBsYW5ldHM9W10seG9mZj0wO2Z1bmN0aW9uIHNldHVwKCl7Y29sb3JNb2RlKEhTQiksY3JlYXRlQ2FudmFzKDQwMCw0MDApLGFuZ2xlTW9kZShERUdSRUVTKTtwbGFuZXRzPVtuZXcgUGxhbmV0KDYwLDIwMCwzMDAsMTIwLDEsODApLG5ldyBQbGFuZXQoODAsMjAwLDIwMCwyMDAsMiw3MCksbmV3IFBsYW5ldCgyMCwyMDAsMTgwLDE0MCw0LDMwMCksbmV3IFBsYW5ldCgxMCwyMDAsMjAwLDE0MCwzLDIxMCksbmV3IFBsYW5ldCgyNiwyMDAsMTQwLDI0MCwxLDExMSksbmV3IFBsYW5ldCgyMDAsMjAwLDIwMCwwLDEsMjIwKSxdfWZ1bmN0aW9uIGRyYXcoKXtiYWNrZ3JvdW5kKDApLGNyZWF0ZUdyaWQoKSxwbGFuZXRzLm1hcCgkPT4kLmRyYXcoKSl9ZnVuY3Rpb24gY3JlYXRlR3JpZCgpe2xldCAkPTMqbm9pc2UoeG9mZis9LjAxKTtmb3IobGV0IHQ9MDt0PDM2MDt0Kz0kKXtsZXQgaT13aWR0aC8yK3dpZHRoKmNvcyh0KSxzPWhlaWdodC8yK3dpZHRoKnNpbih0KTtzdHJva2UoMTAwLDEwMCwxMDApLGxpbmUod2lkdGgvMixoZWlnaHQvMixpLHMpfX1jbGFzcyBQbGFuZXR7Y29uc3RydWN0b3IoJCx0LGkscyxhLGUpe3RoaXMucmFkaXVzPSQsdGhpcy54PXQsdGhpcy55PWksdGhpcy5zY2FsYXI9cyx0aGlzLmFuZ2xlPTAsdGhpcy5zcGVlZD1hLHRoaXMuY29sb3I9ZX1kcmF3KCl7bGV0ICQ9dGhpcy54LXRoaXMucmFkaXVzLHQ9dGhpcy55LXRoaXMucmFkaXVzLGk9dGhpcy54K3RoaXMucmFkaXVzLHM9dGhpcy55K3RoaXMucmFkaXVzLGE9ZHJhd2luZ0NvbnRleHQuY3JlYXRlUmFkaWFsR3JhZGllbnQoJCx0LGkscywyMDAsMjApLGU9Y29sb3IoMTAwLDEwMCwxMDApLGw9Y29sb3IoMTAwLDEwMCwxMDApO2EuYWRkQ29sb3JTdG9wKDAsZS50b1N0cmluZygpKSxhLmFkZENvbG9yU3RvcCguNSxsLnRvU3RyaW5nKCkpLGEuYWRkQ29sb3JTdG9wKDEsZS50b1N0cmluZygpKSxkcmF3aW5nQ29udGV4dC5maWxsU3R5bGU9YSxub1N0cm9rZSgpO2xldCBuPXRoaXMueCt0aGlzLnNjYWxhcipjb3ModGhpcy5hbmdsZSkscj10aGlzLnkrdGhpcy5zY2FsYXIqc2luKHRoaXMuYW5nbGUpO2VsbGlwc2UobixyLHRoaXMucmFkaXVzLHRoaXMucmFkaXVzKSxkcmF3aW5nQ29udGV4dC5maWxsU3R5bGU9IndoaXRlIix0aGlzLmFuZ2xlKz10aGlzLnNwZWVkfX0=";
    string previewBaseURI = "https://example.com/";

    function _setUp() internal {
        address o11y = address(new Observability());
        TokenFactory tokenFactory = new TokenFactory();
        factory = address(tokenFactory);
        address feeManager = address(new FeeManager(1000, treasury));

        address tokenImpl = address(
            new FixedPriceToken(factory, o11y, feeManager, ethfs)
        );

        tokenImplUpgrade = address(
            new FixedPriceToken(factory, o11y, feeManager, ethfs)
        );

        tokenFactory.registerDeployment(tokenImpl);

        tokenFactory.registerUpgrade(tokenImpl, tokenImplUpgrade);

        token = FixedPriceToken(address(new TokenProxy(tokenImpl, "")));

        startTime = uint64(block.timestamp);
        endTime = uint64(block.timestamp + 2 days);
    }

    function _initToken(uint256 maxSupply) internal {
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
            maxSupply: maxSupply,
            artistProofCount: 1,
            // Metadata
            name: "Test",
            symbol: "TST",
            urlEncodedName: "Test",
            urlEncodedDescription: "Test%20description",
            urlEncodedPreviewBaseURI: previewBaseURI,
            base64EncodedScript: base64EncodedScript,
            interactor: address(0),
            imports: imports,
            // Sale info
            presaleStartTime: startTime,
            presaleEndTime: endTime,
            presalePrice: 0.5 ether,
            publicStartTime: startTime,
            publicEndTime: endTime,
            publicPrice: 1 ether,
            maxPresaleMintsPerAddress: 2,
            merkleRoot: 0x5e920a24e45bbcff922c9edd8b1be4d9036c9366ecf8b722bbd9610d9c0c4283
        });

        token.initialize(owner, abi.encode(args));
    }
}
