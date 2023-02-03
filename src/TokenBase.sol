// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {ERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import {Ownable2StepUpgradeable} from "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {IToken} from "./tokens/interfaces/IToken.sol";
import {IObservability} from "./observability/Observability.sol";
import {UUPS} from "./lib/proxy/UUPS.sol";
import {ITokenFactory} from "./interfaces/ITokenFactory.sol";
import {VersionedContract} from "./VersionedContract.sol";
import {IFeeManager} from "./interfaces/IFeeManager.sol";
import "forge-std/console2.sol";

abstract contract TokenBase is
    IToken,
    ERC721Upgradeable,
    ReentrancyGuardUpgradeable,
    Ownable2StepUpgradeable,
    VersionedContract,
    UUPS
{
    mapping(uint256 => bytes32) public tokenIdToPreviousBlockHash;
    mapping(address => bool) public allowedMinters;

    address public immutable factory;
    address public immutable o11y;
    address public immutable feeManager;
    uint256 internal immutable FUNDS_SEND_GAS_LIMIT = 210_000;

    uint256 private _tokenIdCounter;

    TokenInfo public tokenInfo;

    //[[[[MODIFIERS]]]]
    /// @notice restricts to only users with minter role
    modifier onlyAllowedMinter() {
        if (!allowedMinters[msg.sender]) revert SenderNotMinter();
        _;
    }

    //[[[[SETUP FUNCTIONS]]]]

    constructor(address _factory, address _o11y, address _feeManager) {
        factory = _factory;
        o11y = _o11y;
        feeManager = _feeManager;
    }

    //[[[[VIEW FUNCTIONS]]]]

    /// @notice gets the total supply of tokens
    function totalSupply() public view returns (uint256) {
        return _tokenIdCounter;
    }

    //[[[[WITHDRAW FUNCTIONS]]]]

    function feeForAmount(
        uint256 amount
    ) public returns (address payable, uint256) {
        (address payable recipient, uint256 bps) = IFeeManager(feeManager)
            .getWithdrawFeesBPS(address(this));
        return (recipient, (amount * bps) / 10_000);
    }

    /// @notice withdraws the funds from the contract
    function withdraw() external nonReentrant returns (bool) {
        uint256 amount = address(this).balance;

        (address payable feeRecipent, uint256 protocolFee) = feeForAmount(
            amount
        );

        // Pay protocol fee
        if (protocolFee > 0) {
            (bool successFee, ) = feeRecipent.call{
                value: protocolFee,
                gas: FUNDS_SEND_GAS_LIMIT
            }("");

            if (!successFee) revert FundsSendFailure();
            amount -= protocolFee;
        }

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

    /// @notice sets the funds recipent for token funds
    function setFundsRecipent(address fundsRecipent) external onlyOwner {
        tokenInfo.fundsRecipent = fundsRecipent;
    }

    //[[[[MINT FUNCTIONS]]]]

    /// @notice sets the minter role for the given user
    function setMinter(address user, bool isAllowed) public onlyOwner {
        allowedMinters[user] = isAllowed;
    }

    /// @notice mint a token for the given address
    function safeMint(address to) public onlyAllowedMinter {
        if (totalSupply() >= tokenInfo.maxSupply) revert MaxSupplyReached();
        _seedAndMint(to);
    }

    //[[[[PRIVATE FUNCTIONS]]]]

    /// @notice seeds the token id and mints the token
    function _seedAndMint(address to) internal {
        uint256 tokenId;

        // Will never realistically overflow
        unchecked {
            tokenId = _tokenIdCounter++;
        }

        tokenIdToPreviousBlockHash[tokenId] = blockhash(block.number - 1);
        _mint(to, tokenId);
    }

    function _seedAndMintMany(address to, uint256 amount) internal {
        // Will never realistically overflow
        unchecked {
            _tokenIdCounter += amount;
        }

        uint256 tokenId;
        do {
            tokenId = _tokenIdCounter + amount;
            tokenIdToPreviousBlockHash[tokenId] = blockhash(block.number - 1);
            _mint(to, tokenId);
            amount -= 1;
        } while (amount > 0);

        /*
        for (i; i < _tokenIdCounter; ++i) {
            tokenIdToPreviousBlockHash[i] = blockhash(block.number - 1);
            _mint(to, i);
        }
        */
    }

    /// @notice checks if an upgrade is valid
    function _authorizeUpgrade(address newImpl) internal override onlyOwner {
        if (
            !ITokenFactory(factory).isValidUpgrade(
                _getImplementation(),
                newImpl
            )
        ) {
            revert ITokenFactory.InvalidUpgrade(newImpl);
        }
    }
}
