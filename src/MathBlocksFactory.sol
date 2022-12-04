// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.9;

import "./MathBlocksToken.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";

contract MathBlocksFactory is Ownable2Step {
    event CloneDeployed(address owner, address clone);

    mapping(address => address[]) userToDeployedClones;

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
        string memory _script,
        uint256 _price,
        uint256 _endsAtTimestamp
    ) external returns (address clone) {
        clone = Clones.clone(implementation);
        userToDeployedClones[msg.sender].push(clone);

        emit CloneDeployed(msg.sender, clone);

        // Initialize clone.
        MathBlocksToken(clone).initialize(
            msg.sender,
            _name,
            _symbol,
            _description,
            _script,
            _price,
            _endsAtTimestamp
        );
    }
}
