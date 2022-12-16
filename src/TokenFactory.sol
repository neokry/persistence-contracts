// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import {IToken} from "./tokens/interfaces/IToken.sol";
import {Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {Observability, IObservability} from "./Observability/Observability.sol";
import {TokenProxy} from "./TokenProxy.sol";
import {ITokenFactory} from "./interfaces/ITokenFactory.sol";

contract TokenFactory is Ownable2Step, ITokenFactory {
    mapping(address => bool) isToken;
    mapping(address => bool) private deployments;
    mapping(address => mapping(address => bool)) private upgrades;

    /// @notice Observability contract for data processing.
    address public immutable o11y;

    /// @notice Deploys implementation contract.
    constructor() {
        o11y = address(new Observability());
    }

    /// @notice Deploy a new token clone with the sender as the owner.
    function create(
        address tokenImpl,
        bytes calldata data
    ) external returns (address clone) {
        clone = address(new TokenProxy(tokenImpl, ""));
        isToken[clone] = true;

        if (!deployments[tokenImpl]) revert NotDeployed(tokenImpl);
        IObservability(o11y).emitCloneDeployed(msg.sender, clone);

        // Initialize clone.
        IToken(clone).initialize(msg.sender, data);
    }

    function isValidDeployment(address impl) external view returns (bool) {
        return deployments[impl];
    }

    function registerDeployment(address impl) external onlyOwner {
        deployments[impl] = true;
        IObservability(o11y).emitDeploymentTargetRegistererd(impl);
    }

    function unregisterDeployment(address impl) external onlyOwner {
        delete deployments[impl];
        IObservability(o11y).emitDeploymentTargetUnregistered(impl);
    }

    /// @notice If an upgraded implementation has been registered for its original implementation
    /// @param prevImpl The address of the original implementation
    /// @param newImpl The address of the upgraded implementation
    function isValidUpgrade(
        address prevImpl,
        address newImpl
    ) external view returns (bool) {
        return upgrades[prevImpl][newImpl];
    }

    /// @notice Registers an implementation as a valid upgrade
    /// @param prevImpl The address of the original implementation
    /// @param newImpl The address of the implementation valid to upgrade to
    function registerUpgrade(
        address prevImpl,
        address newImpl
    ) external onlyOwner {
        upgrades[prevImpl][newImpl] = true;

        IObservability(o11y).emitUpgradeRegistered(prevImpl, newImpl);
    }

    /// @notice Unregisters an implementation
    /// @param prevImpl The address of the implementation to revert back to
    /// @param newImpl The address of the implementation to unregister
    function unregisterUpgrade(
        address prevImpl,
        address newImpl
    ) external onlyOwner {
        delete upgrades[prevImpl][newImpl];

        IObservability(o11y).emitUpgradeUnregistered(prevImpl, newImpl);
    }
}
