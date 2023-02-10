// SPDX-License-Identifier: MIT

/**                                                                                                                    
`7MM"""Mq.`7MM"""YMM  `7MM"""Mq.   .M"""bgd `7MMF' .M"""bgd MMP""MM""YMM `7MM"""YMM  `7MN.   `7MF' .g8"""bgd `7MM"""YMM  
  MM   `MM. MM    `7    MM   `MM. ,MI    "Y   MM  ,MI    "Y P'   MM   `7   MM    `7    MMN.    M .dP'     `M   MM    `7  
  MM   ,M9  MM   d      MM   ,M9  `MMb.       MM  `MMb.          MM        MM   d      M YMb   M dM'       `   MM   d    
  MMmmdM9   MMmmMM      MMmmdM9     `YMMNq.   MM    `YMMNq.      MM        MMmmMM      M  `MN. M MM            MMmmMM    
  MM        MM   Y  ,   MM  YM.   .     `MM   MM  .     `MM      MM        MM   Y  ,   M   `MM.M MM.           MM   Y  , 
  MM        MM     ,M   MM   `Mb. Mb     dM   MM  Mb     dM      MM        MM     ,M   M     YMM `Mb.     ,'   MM     ,M 
.JMML.    .JMMmmmmMMM .JMML. .JMM.P"Ybmmd"  .JMML.P"Ybmmd"     .JMML.    .JMMmmmmMMM .JML.    YM   `"bmmmd'  .JMMmmmmMMM 
 */

pragma solidity ^0.8.16;

import {ERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import {Ownable2StepUpgradeable} from "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {CountersUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import {SSTORE2} from "@0xsequence/sstore2/contracts/SSTORE2.sol";

import {IToken} from "./tokens/interfaces/IToken.sol";
import {IObservability} from "./observability/Observability.sol";
import {ITokenFactory} from "./interfaces/ITokenFactory.sol";

import {IFeeManager} from "./interfaces/IFeeManager.sol";
import {WithStorage, TokenStorage, MetadataStorage} from "./libraries/LibStorage.sol";
import {UUPS} from "./vendor/proxy/UUPS.sol";
import {VersionedContract} from "./VersionedContract.sol";
import {LibToken} from "./libraries/LibToken.sol";
import {LibHTMLRenderer} from "./libraries/LibHTMLRenderer.sol";
import {LibMetadata} from "./libraries/LibMetadata.sol";

abstract contract TokenBase is
    IToken,
    WithStorage,
    ERC721Upgradeable,
    ReentrancyGuardUpgradeable,
    Ownable2StepUpgradeable,
    VersionedContract,
    UUPS
{
    using CountersUpgradeable for CountersUpgradeable.Counter;

    address public immutable factory;
    address public immutable o11y;
    address public immutable feeManager;
    address public immutable ethFS;

    CountersUpgradeable.Counter private _tokenIdCounter;

    //[[[[MODIFIERS]]]]

    /// @notice restricts to only users with minter role
    modifier onlyAllowedMinter() {
        if (!ts().allowedMinters[msg.sender]) revert SenderNotMinter();
        _;
    }

    //[[[[SETUP FUNCTIONS]]]]

    constructor(
        address _factory,
        address _o11y,
        address _feeManager,
        address _ethFS
    ) {
        factory = _factory;
        o11y = _o11y;
        feeManager = _feeManager;
        ethFS = _ethFS;
    }

    //[[[[VIEW FUNCTIONS]]]]

    /// @notice returns token metadata for a given token id
    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        return LibMetadata.genericDataURI(tokenId);
    }

    /// @notice gets the total supply of tokens
    function totalSupply() public view returns (uint256) {
        return _tokenIdCounter.current();
    }

    function feeForAmount(
        uint256 amount
    ) external view returns (address payable, uint256) {
        return LibToken.feeForAmount(amount);
    }

    function generatePreviewURI(
        string memory tokenId
    ) external view returns (string memory) {
        return LibMetadata.generatePreviewURI(tokenId);
    }

    function tokenInfo() public view returns (TokenInfo memory info) {
        info.factory = ts().factory;
        info.o11y = ts().o11y;
        info.feeManager = ts().feeManager;
        info.fundsRecipent = ts().fundsRecipent;
        info.interactor = ts().interactor;
        info.artistProofsMinted = ts().artistProofsMinted;
        info.maxSupply = ts().maxSupply;
    }

    function metadataInfo() public view returns (MetadataInfo memory info) {
        info.symbol = ms().symbol;
        info.urlEncodedName = ms().urlEncodedName;
        info.urlEncodedDescription = ms().urlEncodedDescription;
        info.urlEncodedPreviewBaseURI = ms().urlEncodedPreviewBaseURI;
        info.scriptPointer = ms().scriptPointer;
        info.imports = ms().imports;
    }

    //[[[SET FUNCTIONS]]]

    /// @notice set the script for the contract
    function setScript(string memory script) public onlyOwner {
        ms().scriptPointer = SSTORE2.write(bytes(script));
    }

    /// @notice sets the interactor for the contract
    function setInteractor(address _interactor) public onlyOwner {
        ts().interactor = _interactor;
    }

    /// @notice get the preview base URI for the token
    function setPreviewBaseURL(string memory uri) public onlyOwner {
        ms().urlEncodedPreviewBaseURI = uri;
    }

    //[[[IMPORT FUNCTIONS]]]

    /// @notice add multiple imports to the token
    function addManyImports(
        LibHTMLRenderer.ScriptRequest[] calldata _imports
    ) external onlyOwner {
        uint256 numImports = _imports.length;
        uint256 i = 0;
        unchecked {
            do {
                ms().imports.push(_imports[i]);
            } while (++i < numImports);
        }
    }

    /// @notice set a single import to the token for a given index
    function setImport(
        uint256 index,
        LibHTMLRenderer.ScriptRequest calldata _import
    ) external onlyOwner {
        ms().imports[index] = _import;
    }

    //[[[[WITHDRAW FUNCTIONS]]]]

    /// @notice withdraws the funds from the contract
    function withdraw() external nonReentrant returns (bool) {
        return LibToken.withdraw();
    }

    /// @notice sets the funds recipent for token funds
    function setFundsRecipent(address fundsRecipent) external onlyOwner {
        ts().fundsRecipent = fundsRecipent;
    }

    //[[[[MINT FUNCTIONS]]]]

    /// @notice sets the minter role for the given user
    function setMinter(address user, bool isAllowed) public onlyOwner {
        ts().allowedMinters[user] = isAllowed;
    }

    /// @notice mint a token for the given address
    function safeMint(address to) public onlyAllowedMinter {
        if (totalSupply() >= ts().maxSupply) revert MaxSupplyReached();
        _seedAndMint(to);
    }

    //[[[[PRIVATE FUNCTIONS]]]]

    /// @notice seeds the token id and mints the token
    function _seedAndMint(address to) internal {
        ts().tokenIdToBlockDifficulty[_tokenIdCounter.current()] = block
            .difficulty;

        _mint(to, _tokenIdCounter.current());
        _tokenIdCounter.increment();
    }

    function _seedAndMintMany(address to, uint256 amount) internal {
        unchecked {
            do {
                _seedAndMint(to);
            } while (--amount > 0);
        }
    }

    /// @notice mint the artist proofs
    function _mintArtistProofs(uint16 amount) internal {
        if (ts().artistProofsMinted) revert ProofsMinted();

        _seedAndMintMany(owner(), amount);

        ts().artistProofsMinted = true;
    }

    /// @notice checks if an upgrade is valid
    function _authorizeUpgrade(address newImpl) internal override onlyOwner {
        if (
            !ITokenFactory(ts().factory).isValidUpgrade(
                _getImplementation(),
                newImpl
            )
        ) {
            revert ITokenFactory.InvalidUpgrade(newImpl);
        }
    }
}
