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
    address treasury = address(8);
    address ethfs = address(9);
    address tokenImplUpgrade;
    uint64 startTime = 0;
    uint64 endTime = 0;
    string script = "let x = 1;";
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

    function _initToken() internal {
        LibHTMLRenderer.ScriptRequest[]
            memory imports = new LibHTMLRenderer.ScriptRequest[](1);

        imports[0] = LibHTMLRenderer.ScriptRequest({
            name: "Test",
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
            urlEncodedDescription: "Test description",
            urlEncodedPreviewBaseURI: previewBaseURI,
            script: script,
            interactor: address(0),
            imports: imports,
            // Sale info
            presaleStartTime: 0,
            presaleEndTime: 0,
            presalePrice: 0,
            publicPrice: 1 ether,
            publicStartTime: startTime,
            publicEndTime: endTime
        });

        token.initialize(owner, abi.encode(args));
    }
}
