// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {ERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import {Ownable2StepUpgradeable} from "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import {IToken} from "./tokens/interfaces/IToken.sol";
import {IObservability} from "./observability/Observability.sol";
import {ITokenFactory} from "./interfaces/ITokenFactory.sol";
import {IFeeManager} from "./interfaces/IFeeManager.sol";
import {WithStorage} from "./libraries/LibStorage.sol";
import {UUPS} from "./vendor/proxy/UUPS.sol";
import {VersionedContract} from "./VersionedContract.sol";
import {LibToken} from "./libraries/LibToken.sol";

abstract contract TokenBase is
    IToken,
    WithStorage,
    ERC721Upgradeable,
    ReentrancyGuardUpgradeable,
    Ownable2StepUpgradeable,
    VersionedContract,
    UUPS
{
    uint256 private _tokenIdCounter;

    //[[[[MODIFIERS]]]]
    /// @notice restricts to only users with minter role
    modifier onlyAllowedMinter() {
        if (!ts().allowedMinters[msg.sender]) revert SenderNotMinter();
        _;
    }

    //[[[[SETUP FUNCTIONS]]]]

    constructor(address _factory, address _o11y, address _feeManager) {
        ts().factory = _factory;
        ts().o11y = _o11y;
        ts().feeManager = _feeManager;
    }

    //[[[[VIEW FUNCTIONS]]]]

    /// @notice gets the total supply of tokens
    function totalSupply() public view returns (uint256) {
        return _tokenIdCounter;
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
        ts().tokenIdToPreviousBlockHash[_tokenIdCounter] = blockhash(
            block.number - 1
        );

        // Will never realistically overflow
        unchecked {
            _mint(to, _tokenIdCounter++);
        }
    }

    function _seedAndMintMany(address to, uint256 amount) internal {
        for (uint i = 0; i < amount; ++i) {
            _seedAndMint(to);
        }
    }

    /// @notice mint the artist proofs
    function _mintArtistProofs(uint16 amount) private {
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
