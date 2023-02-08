// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {SSTORE2} from "@0xsequence/sstore2/contracts/SSTORE2.sol";
import {StringsUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

import {IObservability} from "../observability/Observability.sol";
import {IFixedPriceToken} from "./interfaces/IFixedPriceToken.sol";
import {IHTMLRenderer} from "../renderer/interfaces/IHTMLRenderer.sol";
import {InitArgs} from "./FixedPriceTokenInitilizer.sol";
import {TokenBase} from "../TokenBase.sol";
import {WithStorage} from "../libraries/LibStorage.sol";
import {LibMetadata} from "../libraries/LibMetadata.sol";
import {LibFixedPriceToken} from "../libraries/LibFixedPriceToken.sol";
import {FixedPriceTokenInitilizer} from "./FixedPriceTokenInitilizer.sol";

contract FixedPriceToken is
    IFixedPriceToken,
    WithStorage,
    FixedPriceTokenInitilizer,
    TokenBase
{
    using StringsUpgradeable for uint256;

    //[[[[SETUP FUNCTIONS]]]]

    constructor(
        address _factory,
        address _o11y,
        address _feeManager
    ) TokenBase(_factory, _o11y, _feeManager) {}

    function initialize(
        address owner,
        bytes calldata data
    ) external initializer {
        InitArgs memory args = _init(owner, data);

        __ERC721_init(args.name, args.symbol);
        _transferOwnership(owner);
        _mintArtistProofs(args.artistProofCount);
    }

    //[[[[VIEW FUNCTIONS]]]]

    /// @notice returns token metadata for a given token id
    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        string memory tokenIdString = tokenId.toString();
        string memory animationURL = IHTMLRenderer(ts().htmlRenderer)
            .generateURI(
                ms().imports,
                LibMetadata.generateFullScript(tokenIdString)
            );
        return LibMetadata.genericDataURI(tokenIdString, animationURL, image);
    }

    //[[[[SCRIPT FUNCTIONS]]]]

    /// @notice set the script for the contract
    function setScript(string memory script) public onlyOwner {
        ms().scriptPointer = SSTORE2.write(bytes(script));
    }

    // [[[ INTERACTION FUNCTIONS ]]]

    /// @notice sets the interactor for the contract
    function setInteractor(address _interactor) public onlyOwner {
        ms().interactor = _interactor;
    }

    //[[[[PREVIEW FUNCTIONS]]]]

    /// @notice get the preview base URI for the token
    function setPreviewBaseURL(string memory uri) public onlyOwner {
        previewBaseURI = uri;
    }

    //[[[[RENDERER FUNCTIONS]]]]

    /// @notice set the html renderer for the token
    function setHTMLRenderer(address _htmlRenderer) external onlyOwner {
        htmlRenderer = _htmlRenderer;
    }

    /// @notice add multiple imports to the token
    function addManyImports(
        IHTMLRenderer.FileType[] calldata _imports
    ) external onlyOwner {
        uint256 numImports = _imports.length;
        for (uint256 i = 0; i < numImports; ++i) {
            ts().imports.push(_import);
        }
    }

    /// @notice set a single import to the token for a given index
    function setImport(
        uint256 index,
        IHTMLRenderer.FileType calldata _import
    ) external onlyOwner {
        ts().imports[index] = _import;
    }

    //[[[[PURCHASE FUNCTIONS]]]]

    /// @notice purchase a number of tokens
    function purchase(uint256 amount) external payable nonReentrant {
        LibFixedPriceToken.validatePresale(amount, totalSupply());
        _seedAndMintMany(msg.sender, amount);
        IObservability(o11y).emitSale(msg.sender, saleInfo.price, amount);
    }
}
