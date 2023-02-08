// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;
import {IInteractor} from "./interfaces/IInteractor.sol";
import {IERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/interfaces/IERC721Upgradeable.sol";

///@notice This interactor allows a user to interact with a token if they are the owner of that token
contract SpecificTokenHolderInteractor is IInteractor {
    ///@notice Token contract => Interaction data pointer
    mapping(address => address) public interactionData;

    ///@notice This function returns the validation data for the interactor
    function getValidationData() external pure returns (bytes memory) {
        return new bytes(0);
    }

    /// @notice This function returns true if the user is the owner of the token
    function isValid(
        address user,
        address tokenContract,
        uint256 tokenId,
        bytes memory validationData
    ) public view override returns (bool) {
        return user == IERC721Upgradeable(tokenContract).ownerOf(tokenId);
    }

    function interact(bytes memory data) public {
        token
    }
}
