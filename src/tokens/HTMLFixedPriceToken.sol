// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {TokenBase} from "../TokenBase.sol";
import {IHTMLRenderer} from "../renderers/interfaces/IHTMLRenderer.sol";
import {NFTDescriptor} from "../lib/utils/NFTDescriptor.sol";
import {IObservability} from "../Observability/Observability.sol";
import {IHTMLFixedPriceToken} from "./interfaces/IHTMLFixedPriceToken.sol";
import {IHTMLRenderer} from "../renderers/interfaces/IHTMLRenderer.sol";
import {StringsUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import {HTMLFixedPriceTokenStorageV1} from "./storage/HTMLFixedPriceTokenStorageV1.sol";
import {ITokenFactory} from "../interfaces/ITokenFactory.sol";
import {HTMLRendererProxy} from "../renderers/HTMLRendererProxy.sol";
import {IHTMLRenderer} from "../renderers/interfaces/IHTMLRenderer.sol";

contract HTMLFixedPriceToken is
    IHTMLFixedPriceToken,
    TokenBase,
    HTMLFixedPriceTokenStorageV1
{
    using StringsUpgradeable for uint256;

    //[[[[SETUP FUNCTIONS]]]]

    constructor(address _factory, address _o11y) TokenBase(_factory, _o11y) {}

    function initialize(
        address owner,
        bytes calldata data
    ) external initializer {
        if (msg.sender != factory) revert FactoryMustInitilize();

        (
            string memory _script,
            address _rendererImpl,
            TokenInfo memory _tokenInfo,
            SaleInfo memory _saleInfo,
            IHTMLRenderer.FileType[] memory _imports
        ) = abi.decode(
                data,
                (string, address, TokenInfo, SaleInfo, IHTMLRenderer.FileType[])
            );

        if (!(ITokenFactory(factory).isValidDeployment(_rendererImpl)))
            revert ITokenFactory.NotDeployed(_rendererImpl);

        __ERC721_init(_tokenInfo.name, _tokenInfo.symbol);
        _transferOwnership(owner);

        allowedMinters[owner] = true;

        script = _script;

        htmlRenderer = address(new HTMLRendererProxy(_rendererImpl, ""));
        IHTMLRenderer(htmlRenderer).initilize(owner);
        tokenInfo = _tokenInfo;
        saleInfo = _saleInfo;
        _setImports(_imports);
    }

    //[[[[VIEW FUNCTIONS]]]]

    function contractURI(uint256 tokenId) public view returns (string memory) {
        string memory fullName = string(
            abi.encodePacked(name(), " ", tokenId.toString())
        );
        return
            genericDataURI(
                fullName,
                tokenInfo.description,
                tokenIdToSeed[tokenId],
                tokenId.toString()
            );
    }

    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        string memory fullName = string(
            abi.encodePacked(name(), " ", tokenId.toString())
        );
        return
            genericDataURI(
                fullName,
                tokenInfo.description,
                tokenIdToSeed[tokenId],
                tokenId.toString()
            );
    }

    function genericDataURI(
        string memory _name,
        string memory _description,
        uint256 seed,
        string memory tokenId
    ) public view returns (string memory) {
        NFTDescriptor.TokenURIParams memory params = NFTDescriptor
            .TokenURIParams({
                name: _name,
                description: _description,
                animation_url: IHTMLRenderer(htmlRenderer).generateURI(
                    imports,
                    generateScript(seed, tokenId)
                )
            });
        return NFTDescriptor.constructTokenURI(params);
    }

    function generateScript(
        uint256 seed,
        string memory tokenId
    ) public view returns (string memory) {
        return
            string.concat(
                '<script>var seed=Number("',
                seed.toString(),
                '".slice(0,20));var tokenId="',
                tokenId,
                '";var timestamp=Number("',
                block.timestamp.toString(),
                '");',
                script,
                "</script>"
            );
    }

    //[[[[RENDERER FUNCTIONS]]]]

    function setHTMLRenderer(address _htmlRenderer) external onlyOwner {
        htmlRenderer = _htmlRenderer;
    }

    function setImports(
        IHTMLRenderer.FileType[] calldata _imports
    ) external onlyOwner {
        _setImports(_imports);
    }

    //[[[[PURCHASE FUNCTIONS]]]]

    function purchase(uint256 amount) external payable nonReentrant {
        if (
            block.timestamp < saleInfo.startTime ||
            block.timestamp >= saleInfo.endTime
        ) revert SaleNotActive();

        if (msg.value < (amount * saleInfo.price)) revert InvalidPrice();
        if (totalSupply() + amount > tokenInfo.totalSupply) revert SoldOut();

        IObservability(o11y).emitSale(msg.sender, saleInfo.price, amount);

        for (uint256 i = 0; i < amount; i++) {
            _seedAndMint(msg.sender);
        }
    }

    //[[[[PRIVATE FUNCTIONS]]]]

    function _setImports(IHTMLRenderer.FileType[] memory _imports) private {
        uint256 numImports = _imports.length - 1;
        for (uint256 i; i < numImports; i++) {
            imports[i] = _imports[i];
        }
    }
}
