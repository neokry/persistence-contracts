// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";

import "./HTMLGeneratorETHFS.sol";
import "./NFTDescriptor.sol";

contract MathBlocksToken is ERC721Upgradeable, Ownable2StepUpgradeable {
    event Purcahsed(uint256 price);
    event Withdrawn(uint256 amount);

    struct TokenInfo {
        string name;
        string symbol;
        string description;
        string script;
        uint256 price;
        uint256 endsAtTimestamp;
    }

    using StringsUpgradeable for uint256;
    using CountersUpgradeable for CountersUpgradeable.Counter;

    CountersUpgradeable.Counter private _tokenIdCounter;
    mapping(uint256 => uint256) public _tokenIdToSeed;

    address public immutable factory;

    string public description;
    string public script;
    uint256 public price;
    uint256 public endsAtTimestamp;

    error FactoryMustInitilize();
    error SaleHasEnded();
    error InvalidPrice();

    constructor(address _factory) {
        factory = _factory;
    }

    function initialize(
        address owner,
        string memory _name,
        string memory _symbol,
        string memory _description,
        string memory _script,
        uint256 _price,
        uint256 _endsAtTimestamp
    ) external initializer {
        if (msg.sender != factory) revert FactoryMustInitilize();

        __ERC721_init(_name, _symbol);
        _transferOwnership(owner);

        script = _script;
        description = _description;
        price = _price;
        endsAtTimestamp = _endsAtTimestamp;
    }

    function tokenInfo() public view returns (TokenInfo memory) {
        return
            TokenInfo({
                name: name(),
                symbol: symbol(),
                description: description,
                script: script,
                price: price,
                endsAtTimestamp: endsAtTimestamp
            });
    }

    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        string memory fullName = string(
            abi.encodePacked(name(), " ", tokenId.toString())
        );
        return genericDataURI(fullName, description, _tokenIdToSeed[tokenId]);
    }

    function genericDataURI(
        string memory _name,
        string memory _description,
        uint256 seed
    ) public view returns (string memory) {
        NFTDescriptor.TokenURIParams memory params = NFTDescriptor
            .TokenURIParams({
                name: _name,
                description: _description,
                animation_url: constructAnimationURL(seed)
            });
        return NFTDescriptor.constructTokenURI(params);
    }

    function constructAnimationURL(
        uint256 seed
    ) public view returns (string memory) {
        HTMLGeneratorETHFS.HTMLURIParams memory params = HTMLGeneratorETHFS
            .HTMLURIParams({script: script, seed: seed.toString()});
        return HTMLGeneratorETHFS.constructHTMLURI(params);
    }

    function purchase(uint256 amount) public payable {
        if (endsAtTimestamp < block.timestamp) revert SaleHasEnded();
        if (msg.value < (amount * price)) revert InvalidPrice();

        for (uint256 i = 0; i < amount; i++) {
            _seedAndMint(msg.sender);
            emit Purcahsed(price);
        }
    }

    function withdraw() public onlyOwner returns (bool) {
        uint256 amount = address(this).balance;
        (bool successFunds, ) = msg.sender.call{value: amount}("");
        emit Withdrawn(amount);
        return successFunds;
    }

    function safeMint(address to) public onlyOwner {
        _seedAndMint(to);
    }

    function _seedAndMint(address to) private {
        uint256 tokenId = _tokenIdCounter.current();

        _tokenIdToSeed[tokenId] = uint256(
            keccak256(abi.encodePacked(blockhash(block.number - 1), tokenId))
        );

        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }
}
