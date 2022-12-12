// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.12;

import {MathBlocksToken, IMathBlocksToken} from "./MathBlocksToken.sol";
import {Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {Observability, IObservability} from "../Observability/Observability.sol";

contract MathBlocksFactory is Ownable2Step {
    mapping(address => address[]) userToDeployedClones;

    /// @notice Observability contract for data processing.
    address public immutable o11y;

    /// @notice platform implementation.
    address public implementation;

    address public defaultHTMLRenderer;

    /// @notice Deploys implementation contract.
    constructor(address _defaultHTMLRenderer) {
        o11y = address(new Observability());
        defaultHTMLRenderer = _defaultHTMLRenderer;
        implementation = address(new MathBlocksToken(address(this), o11y));
    }

    // @notice Sets implementation contract
    function setImplementation(address _implementation) external onlyOwner {
        IObservability(o11y).emitFactoryImplementationSet(
            implementation,
            _implementation
        );
        implementation = _implementation;
    }

    /// @notice Deploy a new token clone with the sender as the owner.
    function create(
        string memory _name,
        string memory _symbol,
        string memory _description,
        string memory _script,
        uint256 _price,
        address _fundsRecipent,
        uint256 _startsAtTimestamp,
        uint256 _endsAtTimestamp
    ) external returns (address clone) {
        clone = Clones.clone(implementation);
        userToDeployedClones[msg.sender].push(clone);

        IObservability(o11y).emitCloneDeployed(msg.sender, clone);

        IMathBlocksToken.TokenInfo memory info = IMathBlocksToken.TokenInfo({
            name: _name,
            symbol: _symbol,
            description: _description,
            script: _script,
            price: _price,
            fundsRecipent: _fundsRecipent,
            startsAtTimestamp: _startsAtTimestamp,
            endsAtTimestamp: _endsAtTimestamp
        });

        // Initialize clone.
        MathBlocksToken(clone).initialize(
            msg.sender,
            defaultHTMLRenderer,
            info
        );
    }
}
