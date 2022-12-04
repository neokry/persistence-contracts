// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.9;

interface IObservabilityEvents {
    event CloneDeployed(
        address indexed factory,
        address indexed owner,
        address indexed clone
    );

    event FactoryImplementationSet(
        address indexed factory,
        address indexed oldImplementation,
        address indexed newImplementation
    );

    event Sale(
        address indexed clone,
        address indexed to,
        uint256 indexed pricePerToken,
        uint256 amount
    );

    event FundsWithdrawn(
        address indexed clone,
        address indexed withdrawnBy,
        address indexed withdrawnTo,
        uint256 amount
    );
}

interface IObservability {
    function emitCloneDeployed(address owner, address clone) external;

    function emitFactoryImplementationSet(
        address oldImplementation,
        address newImplementation
    ) external;

    function emitSale(
        address to,
        uint256 pricePerToken,
        uint256 amount
    ) external;

    function emitFundsWithdrawn(
        address withdrawnBy,
        address withdrawnTo,
        uint256 amount
    ) external;
}
