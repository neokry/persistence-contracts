// SPDX-License-Identifier: GPL-3.0 AND MIT
pragma solidity ^0.8.16;

import {WithStorage} from "../libraries/LibStorage.sol";
import {IHTMLRenderer} from "../renderer/interfaces/IHTMLRenderer.sol";
import {HTMLRendererProxy} from "../renderer/HTMLRendererProxy.sol";

struct InitArgs {
    // Token info
    address fundsRecipent;
    address htmlRendererImpl;
    uint256 maxSupply;
    uint16 artistProofCount;
    // Metadata
    string name;
    string symbol;
    string description;
    string previewBaseURI;
    string script;
    address interactor;
    IHTMLRenderer.ExternalScript[] imports;
    // Sale info
    uint64 presaleStartTime;
    uint64 presaleEndTime;
    uint112 presalePrice;
    uint64 publicStartTime;
    uint64 publicEndTime;
    uint112 publicPrice;
}

contract FixedPriceTokenInitilizer is WithStorage {
    function _init(
        address owner,
        address factory,
        address o11y,
        address feeManager,
        bytes memory rawArgs
    ) internal returns (InitArgs memory args) {
        args = abi.decode(rawArgs, (InitArgs));

        ts().factory = factory;
        ts().o11y = o11y;
        ts().feeManager = feeManager;
        ts().fundsRecipent = args.fundsRecipent;
        ts().interactor = args.interactor;
        ts().maxSupply = args.maxSupply;
        ts().allowedMinters[owner] = true;
        ts().htmlRenderer = address(
            new HTMLRendererProxy(args.htmlRendererImpl, "")
        );

        ms().name = args.name;
        ms().symbol = args.symbol;
        ms().description = args.description;
        ms().previewBaseURI = args.previewBaseURI;

        fixedPriceSaleInfo().presaleStartTime = args.presaleStartTime;
        fixedPriceSaleInfo().presaleEndTime = args.presaleEndTime;
        fixedPriceSaleInfo().presalePrice = args.presalePrice;
        fixedPriceSaleInfo().publicStartTime = args.publicStartTime;
        fixedPriceSaleInfo().publicEndTime = args.publicEndTime;
        fixedPriceSaleInfo().publicPrice = args.publicPrice;

        _addManyImports(args.imports);

        IHTMLRenderer(ts().htmlRenderer).initilize(owner);
    }

    function constructInitalProps(
        InitArgs memory args
    ) external pure returns (bytes memory) {
        return abi.encode(args);
    }

    function _addManyImports(
        IHTMLRenderer.ExternalScript[] memory _imports
    ) private {
        uint256 numImports = _imports.length;
        for (uint256 i; i < numImports; ++i) {
            ms().imports.push(_imports[i]);
        }
    }
}
