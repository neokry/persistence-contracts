// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;
import {IInteractor} from "./interfaces/IInteractor.sol";
import {IERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/interfaces/IERC721Upgradeable.sol";

///@notice This interactor allows a user to interact with a token if they are the owner of any token in the contract
contract GeneralTokenHolderInteractor is IInteractor {
    ///@notice This function returns the validation data for the interactor
    function getValidationData(
        uint256 userTokenId
    ) external pure returns (bytes memory) {
        return abi.encode(userTokenId);
    }

    ///@notice This function returns true if the user is the owner of the token passed into validationData
    function isValid(
        address user,
        address tokenContract,
        uint256 tokenId,
        bytes memory validationData
    ) external view override returns (bool) {
        uint256 userTokenId = abi.decode(validationData, (uint256));
        return user == IERC721Upgradeable(tokenContract).ownerOf(userTokenId);
    }
}
