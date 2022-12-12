// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import {ERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import {StringsUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import {Ownable2StepUpgradeable} from "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import {CountersUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import {IMathBlocksToken} from "./interface/IMathBlocksToken.sol";
import {IHTMLRenderer} from "../HTMLRenderers/interface/IHTMLRenderer.sol";
import {NFTDescriptor} from "./NFTDescriptor.sol";
import {Observability, IObservability} from "../Observability/Observability.sol";

contract MathBlocksToken is
    IMathBlocksToken,
    ERC721Upgradeable,
    ReentrancyGuardUpgradeable,
    Ownable2StepUpgradeable
{
    using StringsUpgradeable for uint256;
    using CountersUpgradeable for CountersUpgradeable.Counter;

    CountersUpgradeable.Counter private _tokenIdCounter;

    mapping(uint256 => uint256) public tokenIdToSeed;
    mapping(address => bool) public allowedMinters;

    address public immutable factory;
    address public immutable o11y;
    uint256 internal immutable FUNDS_SEND_GAS_LIMIT = 210_000;

    address htmlRenderer;
    TokenInfo public tokenInfo;

    //[[[[MODIFIERS]]]]
    modifier onlyAllowedMinter() {
        if (!allowedMinters[msg.sender]) revert SenderNotMinter();
        _;
    }

    //[[[[SETUP FUNCTIONS]]]]

    constructor(address _factory, address _o11y) {
        factory = _factory;
        o11y = _o11y;
    }

    function initialize(
        address owner,
        address _htmlRenderer,
        TokenInfo calldata info
    ) external initializer {
        if (msg.sender != factory) revert FactoryMustInitilize();

        __ERC721_init(info.name, info.symbol);
        _transferOwnership(owner);
        allowedMinters[owner] = true;
        tokenInfo = info;
        htmlRenderer = _htmlRenderer;
    }

    //[[[[VIEW FUNCTIONS]]]]

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
                animation_url: constructAnimationURL(seed, tokenId)
            });
        return NFTDescriptor.constructTokenURI(params);
    }

    function constructAnimationURL(
        uint256 seed,
        string memory tokenId
    ) public view returns (string memory) {
        IHTMLRenderer.HTMLURIParams memory params = IHTMLRenderer
            .HTMLURIParams({
                script: tokenInfo.script,
                seed: seed.toString(),
                tokenId: tokenId,
                timestamp: block.timestamp.toString()
            });
        return IHTMLRenderer(htmlRenderer).generateHTMLURI(params);
    }

    //[[[[RENDERER FUNCTIONS]]]]

    function setHTMLRenderer(address _htmlRenderer) external onlyOwner {
        htmlRenderer = _htmlRenderer;
    }

    //[[[[PURCHASE FUNCTIONS]]]]

    function purchase(uint256 amount) external payable nonReentrant {
        if (
            block.timestamp < tokenInfo.startsAtTimestamp ||
            block.timestamp >= tokenInfo.endsAtTimestamp
        ) revert SaleNotActive();

        if (msg.value < (amount * tokenInfo.price)) revert InvalidPrice();

        IObservability(o11y).emitSale(msg.sender, tokenInfo.price, amount);

        for (uint256 i = 0; i < amount; i++) {
            _seedAndMint(msg.sender);
        }
    }

    //[[[[WITHDRAW FUNCTIONS]]]]

    function withdraw() external nonReentrant returns (bool) {
        uint256 amount = address(this).balance;

        (bool successFunds, ) = tokenInfo.fundsRecipent.call{
            value: amount,
            gas: FUNDS_SEND_GAS_LIMIT
        }("");

        if (!successFunds) revert FundsSendFailure();

        IObservability(o11y).emitFundsWithdrawn(
            msg.sender,
            tokenInfo.fundsRecipent,
            amount
        );
        return successFunds;
    }

    function setFundsRecipent(address fundsRecipent) external onlyOwner {
        tokenInfo.fundsRecipent = fundsRecipent;
    }

    //[[[[MINT FUNCTIONS]]]]

    function setMinter(address user, bool isAllowed) public onlyOwner {
        allowedMinters[user] = isAllowed;
    }

    function safeMint(address to) public onlyAllowedMinter {
        _seedAndMint(to);
    }

    //[[[[PRIVATE FUNCTIONS]]]]

    function _seedAndMint(address to) private {
        uint256 tokenId = _tokenIdCounter.current();

        tokenIdToSeed[tokenId] = uint256(
            keccak256(abi.encodePacked(blockhash(block.number - 1), tokenId))
        );

        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }
}
