// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.12;

import {IObservability, IObservabilityEvents} from "./interface/IObservability.sol";

contract Observability is IObservability, IObservabilityEvents {
    function emitCloneDeployed(address owner, address clone) external override {
        emit CloneDeployed(msg.sender, owner, clone);
    }

    function emitFactoryImplementationSet(
        address oldImplementation,
        address newImplementation
    ) external override {
        emit FactoryImplementationSet(
            msg.sender,
            oldImplementation,
            newImplementation
        );
    }

    function emitSale(
        address to,
        uint256 pricePerToken,
        uint256 amount
    ) external override {
        emit Sale(msg.sender, to, pricePerToken, amount);
    }

    function emitFundsWithdrawn(
        address withdrawnBy,
        address withdrawnTo,
        uint256 amount
    ) external override {
        emit FundsWithdrawn(msg.sender, withdrawnBy, withdrawnTo, amount);
    }
}
