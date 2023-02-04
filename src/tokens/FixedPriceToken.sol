// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {TokenBase} from "../TokenBase.sol";
import {IHTMLRenderer} from "../renderer/interfaces/IHTMLRenderer.sol";
import {IObservability} from "../observability/Observability.sol";
import {IFixedPriceToken} from "./interfaces/IFixedPriceToken.sol";
import {IHTMLRenderer} from "../renderer/interfaces/IHTMLRenderer.sol";
import {StringsUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import {FixedPriceTokenStorageV1} from "./storage/FixedPriceTokenStorageV1.sol";
import {FixedPriceTokenStorageV2} from "./storage/FixedPriceTokenStorageV2.sol";
import {ITokenFactory} from "../interfaces/ITokenFactory.sol";
import {HTMLRendererProxy} from "../renderer/HTMLRendererProxy.sol";
import {IHTMLRenderer} from "../renderer/interfaces/IHTMLRenderer.sol";
import {IFileStore} from "ethfs/IFileStore.sol";
import {SSTORE2} from "@0xsequence/sstore2/contracts/SSTORE2.sol";
import {Base64} from "base64-sol/base64.sol";
import {IInteractor} from "../interactors/interfaces/IInteractor.sol";

contract FixedPriceToken is
    IFixedPriceToken,
    TokenBase,
    FixedPriceTokenStorageV1,
    FixedPriceTokenStorageV2
{
    using StringsUpgradeable for uint256;

    //[[[[SETUP FUNCTIONS]]]]

    constructor(
        address _factory,
        address _o11y,
        address _feeManager
    ) TokenBase(_factory, _o11y, _feeManager) {}

    /// @notice Initializes the token
    function initialize(
        address owner,
        bytes calldata data
    ) external initializer {
        if (msg.sender != factory) revert FactoryMustInitilize();

        (
            string memory _script,
            string memory _previewBaseURI,
            address _rendererImpl,
            address _interactor,
            TokenInfo memory _tokenInfo,
            SaleInfo memory _saleInfo,
            IHTMLRenderer.FileType[] memory _imports
        ) = abi.decode(
                data,
                (
                    string,
                    string,
                    address,
                    address,
                    TokenInfo,
                    SaleInfo,
                    IHTMLRenderer.FileType[]
                )
            );

        if (!(ITokenFactory(factory).isValidDeployment(_rendererImpl)))
            revert ITokenFactory.NotDeployed(_rendererImpl);

        htmlRenderer = address(new HTMLRendererProxy(_rendererImpl, ""));
        allowedMinters[owner] = true;
        tokenInfo = _tokenInfo;
        saleInfo = _saleInfo;

        IHTMLRenderer(htmlRenderer).initilize(owner);

        _setInteractor(_interactor);
        __ERC721_init(_tokenInfo.name, _tokenInfo.symbol);
        _transferOwnership(owner);
        _addManyImports(_imports);
        _setScript(_script);
        _setPreviewBaseURI(_previewBaseURI);
        _mintArtistProofs(_saleInfo.artistProofCount);
    }

    //[[[[VIEW FUNCTIONS]]]]

    /// @notice a helper function for generating inital contract props
    function constructInitalProps(
        string memory _script,
        string memory _previewBaseURI,
        address _rendererImpl,
        address _interactor,
        TokenInfo memory _tokenInfo,
        SaleInfo memory _saleInfo,
        IHTMLRenderer.FileType[] memory _imports
    ) public pure returns (bytes memory) {
        return
            abi.encode(
                _script,
                _previewBaseURI,
                _rendererImpl,
                _interactor,
                _tokenInfo,
                _saleInfo,
                _imports
            );
    }

    /// @notice returns token metadata for a given token id
    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        string memory tokenIdString = tokenId.toString();
        string memory fullName = string(
            abi.encodePacked(name(), " ", tokenIdString)
        );
        string memory animationURL = tokenHTML(tokenId);
        string memory image = generatePreviewURI(tokenIdString);
        return
            genericDataURI(
                fullName,
                tokenInfo.description,
                animationURL,
                image
            );
    }

    /// @notice contruct a generic data URI from token data
    function genericDataURI(
        string memory _name,
        string memory _description,
        string memory _animationURL,
        string memory _image
    ) public pure returns (string memory) {
        return
            string.concat(
                "data:application/json;base64,",
                Base64.encode(
                    bytes(
                        string.concat(
                            '{"name":"',
                            _name,
                            '", "description":"',
                            _description,
                            '", "animation_url": "',
                            _animationURL,
                            '", "image": "',
                            _image,
                            '"}'
                        )
                    )
                )
            );
    }

    /// @notice generate a preview URI for the token
    function generatePreviewURI(
        string memory tokenId
    ) public view returns (string memory) {
        return
            string.concat(
                previewBaseURI,
                uint256(uint160(address(this))).toHexString(20),
                "/",
                tokenId
            );
    }

    /// @notice generate the html for the token
    function tokenHTML(uint256 tokenId) public view returns (string memory) {
        return
            IHTMLRenderer(htmlRenderer).generateURI(
                imports,
                generateFullScript(tokenId)
            );
    }

    /// @notice generate the full script for the token
    function generateFullScript(
        uint256 tokenId
    ) public view returns (string memory) {
        return
            string.concat(
                '<script>var persistence={blockHash:"',
                uint256(tokenIdToPreviousBlockHash[tokenId]).toString(),
                '",tokenId:"',
                tokenId.toString(),
                '",timestamp:"',
                block.timestamp.toString(),
                '",rawInteractionState:"',
                getInteractionState(tokenId),
                '"};',
                getScript(),
                "</script>"
            );
    }

    /// @notice get the script for the contract
    function getScript() public view returns (string memory) {
        return string(SSTORE2.read(scriptPointer));
    }

    /// @notice get the interaction state for the token
    function getInteractionState(
        uint256 tokenId
    ) public view returns (string memory) {
        if (interactionState[tokenId] == address(0)) return "";
        return string(SSTORE2.read(interactionState[tokenId]));
    }

    //[[[[SCRIPT FUNCTIONS]]]]

    /// @notice set the script for the contract
    function setScript(string memory script) public onlyOwner {
        _setScript(script);
    }

    // [[[ INTERACTION FUNCTIONS ]]]

    /// @notice sets the interactor for the contract
    function setInteractor(address _interactor) public onlyOwner {
        _setInteractor(_interactor);
    }

    /// @notice sets the interaction state for the token if authorized with the interactor
    function setInteractionState(
        uint256 tokenId,
        bytes memory validationData,
        string memory state
    ) public {
        if (interactor == address(0)) revert InteractorNotSet();
        if (!_exists(tokenId)) revert InvalidTokenId();
        if (
            !IInteractor(interactor).isValid(
                msg.sender,
                address(this),
                tokenId,
                validationData
            )
        ) revert InvalidInteraction();

        _setInteractionState(tokenId, state);
    }

    //[[[[PREVIEW FUNCTIONS]]]]

    /// @notice get the preview base URI for the token
    function setPreviewBaseURL(string memory uri) public onlyOwner {
        _setPreviewBaseURI(uri);
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
        _addManyImports(_imports);
    }

    /// @notice set a single import to the token for a given index
    function setImport(
        uint256 index,
        IHTMLRenderer.FileType calldata _import
    ) external onlyOwner {
        _setImport(index, _import);
    }

    //[[[[PURCHASE FUNCTIONS]]]]

    /// @notice purchase a number of tokens
    function purchase(uint256 amount) external payable nonReentrant {
        if (
            block.timestamp < saleInfo.startTime ||
            block.timestamp >= saleInfo.endTime
        ) revert SaleNotActive();

        if (msg.value < (amount * saleInfo.price)) revert InvalidPrice();
        if (totalSupply() + amount > tokenInfo.maxSupply) revert SoldOut();
        if (amount < 1) revert InvalidAmount();

        _seedAndMintMany(msg.sender, amount);
        IObservability(o11y).emitSale(msg.sender, saleInfo.price, amount);
    }

    //[[[[PRIVATE FUNCTIONS]]]]
    /// @notice adds a single import
    function _addImport(IHTMLRenderer.FileType memory _import) private {
        imports.push(_import);
    }

    /// @notice adds many imports
    function _addManyImports(IHTMLRenderer.FileType[] memory _imports) private {
        uint256 numImports = _imports.length;
        for (uint256 i = 0; i < numImports; i++) {
            _addImport(_imports[i]);
        }
    }

    /// @notice sets a single import for the given index
    function _setImport(
        uint256 index,
        IHTMLRenderer.FileType memory _import
    ) private {
        imports[index] = _import;
    }

    /// @notice store the script and ovverwrite the script pointer
    function _setScript(string memory script) private {
        scriptPointer = SSTORE2.write(bytes(script));
    }

    /// @notice set the interactor for this contract
    function _setInteractor(address _interactor) internal {
        interactor = _interactor;
    }

    /// @notice set the interaction state for the token
    function _setInteractionState(
        uint256 tokenId,
        string memory state
    ) internal {
        interactionState[tokenId] = SSTORE2.write(bytes(state));
    }

    /// @notice set the preview base URI
    function _setPreviewBaseURI(string memory _previewBaseURI) private {
        previewBaseURI = _previewBaseURI;
    }

    /// @notice mint the artist proofs
    function _mintArtistProofs(uint16 amount) private {
        if (proofsMinted) revert ProofsMinted();

        for (uint256 i = 0; i < amount; i++) {
            _seedAndMint(owner());
        }

        proofsMinted = true;
    }
}
