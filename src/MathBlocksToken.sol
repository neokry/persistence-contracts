// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "./NFTDescriptor.sol";

contract MathBlocksToken is ERC721Upgradeable, Ownable2StepUpgradeable {
    using StringsUpgradeable for uint256;
    using CountersUpgradeable for CountersUpgradeable.Counter;

    CountersUpgradeable.Counter private _tokenIdCounter;
    mapping(uint256 => uint256) public _tokenIdToSeed;

    address public immutable factory;

    string public description;
    string public baseURL;
    uint256 public price;
    uint256 public endsAtTimestamp;

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
        string memory _baseURL,
        uint256 _price,
        uint256 _endsAtTimestamp
    ) external {
        __ERC721_init(_name, _symbol);
        _transferOwnership(owner);
        baseURL = _baseURL;
        description = _description;
        price = _price;
        endsAtTimestamp = _endsAtTimestamp;
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
        return string(abi.encodePacked(baseURL, "?seed=", seed.toString()));
    }

    function purchase(uint256 amount) public payable {
        if (block.timestamp < endsAtTimestamp) revert SaleHasEnded();
        if (msg.value < (amount * price)) revert InvalidPrice();

        for (uint256 i = 0; i < amount; i++) {
            _seedAndMint(msg.sender);
        }
    }

    function withdraw() public returns (bool) {
        (bool successFunds, ) = msg.sender.call{value: address(this).balance}(
            ""
        );
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
