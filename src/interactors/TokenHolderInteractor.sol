// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {IInteractor} from "./interfaces/IInteractor.sol";
import {SSTORE2} from "@0xsequence/sstore2/contracts/SSTORE2.sol";
import {IERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/interfaces/IERC721Upgradeable.sol";

///@notice This interactor allows a user to interact with a token if they are the owner of that token
contract TokenHolderInteractor {
    error InvalidInteraction();

    struct InitalArgs {
        address tokenContract;
        bool fullDataMode;
        uint256 maxSupply;
    }

    address public tokenContract;
    bool public fullDataMode;
    uint256 public maxSupply;

    ///@notice Token contract => Interaction data pointer
    mapping(uint256 => address) public tokenToDataPointer;

    function init(bytes memory data) external {
        InitalArgs memory args = abi.decode(data, (InitalArgs));
        tokenContract = args.tokenContract;
        fullDataMode = args.fullDataMode;
        maxSupply = args.maxSupply;
    }

    function getData(uint256 tokenId) external view returns (bytes memory) {
        if (!fullDataMode) return SSTORE2.read(tokenToDataPointer[tokenId]);

        for (uint256 i = 0; i < maxSupply; ++i) {
            SSTORE2.read(tokenToDataPointer[i]);
        }
    }

    /// @notice This function returns true if the user is the owner of the token
    function interact(uint256 tokenId, bytes memory data) external {
        if (msg.sender != IERC721Upgradeable(tokenContract).ownerOf(tokenId))
            revert InvalidInteraction();

        tokenToDataPointer[tokenId] = SSTORE2.write(data);
    }
}
