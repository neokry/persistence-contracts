// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.9;

import "./MathBlocksToken.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";

contract MathBlocksFactory is Ownable2Step {
    /// @notice platform implementation.
    address public implementation;

    /// @notice Deploys implementation contract.
    constructor() {
        implementation = address(new MathBlocksToken(address(this)));
    }

    // @notice Sets implementation contract
    function setImplementation(address _implementation) external onlyOwner {
        implementation = _implementation;
    }

    /// @notice Deploy a new token clone with the sender as the owner.
    function create(
        string memory _name,
        string memory _symbol,
        string memory _description,
        string memory _baseURL,
        uint256 _price,
        uint256 _endsAtTimestamp
    ) external returns (address clone) {
        clone = Clones.clone(implementation);

        // Initialize clone.
        MathBlocksToken(clone).initialize(
            msg.sender,
            _name,
            _symbol,
            _description,
            _baseURL,
            _price,
            _endsAtTimestamp
        );
    }
}
