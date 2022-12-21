// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {TokenBase} from "../TokenBase.sol";
import {IHTMLRenderer} from "../renderer/interfaces/IHTMLRenderer.sol";
import {NFTDescriptor} from "../lib/utils/NFTDescriptor.sol";
import {IObservability} from "../Observability/Observability.sol";
import {IFixedPriceToken} from "./interfaces/IFixedPriceToken.sol";
import {IHTMLRenderer} from "../renderer/interfaces/IHTMLRenderer.sol";
import {StringsUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import {FixedPriceTokenStorageV1} from "./storage/FixedPriceTokenStorageV1.sol";
import {ITokenFactory} from "../interfaces/ITokenFactory.sol";
import {HTMLRendererProxy} from "../renderer/HTMLRendererProxy.sol";
import {IHTMLRenderer} from "../renderer/interfaces/IHTMLRenderer.sol";
import {IFileStore} from "ethfs/IFileStore.sol";
import {SSTORE2} from "@0xsequence/sstore2/contracts/SSTORE2.sol";

contract FixedPriceToken is
    IFixedPriceToken,
    TokenBase,
    FixedPriceTokenStorageV1
{
    using StringsUpgradeable for uint256;
    using StringsUpgradeable for address;

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

        htmlRenderer = address(new HTMLRendererProxy(_rendererImpl, ""));
        IHTMLRenderer(htmlRenderer).initilize(owner);
        tokenInfo = _tokenInfo;
        saleInfo = _saleInfo;
        _setImports(_imports);
        _setScript(_script);
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
                tokenIdToPreviousBlockHash[tokenId],
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
                tokenIdToPreviousBlockHash[tokenId],
                tokenId.toString()
            );
    }

    function genericDataURI(
        string memory _name,
        string memory _description,
        bytes32 mintedPreviousBlockHash,
        string memory tokenId
    ) public view returns (string memory) {
        NFTDescriptor.TokenURIParams memory params = NFTDescriptor
            .TokenURIParams({
                name: _name,
                description: _description,
                animation_url: IHTMLRenderer(htmlRenderer).generateURI(
                    imports,
                    generateFullScript(mintedPreviousBlockHash, tokenId)
                )
            });
        return NFTDescriptor.constructTokenURI(params);
    }

    function generateFullScript(
        bytes32 mintedPreviousBlockHash,
        string memory tokenId
    ) public view returns (string memory) {
        return
            string.concat(
                '<script>var blockHash="',
                uint256(mintedPreviousBlockHash).toString(),
                '";var tokenId="',
                tokenId,
                '";var timestamp=Number("',
                block.timestamp.toString(),
                '");',
                getScript(),
                "</script>"
            );
    }

    function getScript() public view returns (string memory) {
        return string(SSTORE2.read(scriptPointer));
    }

    //[[[[SCRIPT FUNCTIONS]]]]

    function setScript(string memory script) public onlyOwner {
        _setScript(script);
    }

    //[[[[RENDERER FUNCTIONS]]]]

    function setHTMLRenderer(address _htmlRenderer) external onlyOwner {
        htmlRenderer = _htmlRenderer;
    }

    function addImport(
        IHTMLRenderer.FileType calldata _import
    ) external onlyOwner {
        _addImport(_import);
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
    function _addImport(IHTMLRenderer.FileType memory _import) private {
        imports.push(_import);
    }

    function _setImports(IHTMLRenderer.FileType[] memory _imports) private {
        uint256 numImports = _imports.length - 1;
        for (uint256 i; i < numImports; i++) {
            imports[i] = _imports[i];
        }
    }

    function _setScript(string memory script) private {
        scriptPointer = SSTORE2.write(bytes(script));
    }
}
