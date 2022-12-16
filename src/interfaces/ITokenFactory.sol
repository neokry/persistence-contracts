//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface ITokenFactory {
    error InvalidUpgrade(address impl);
    error NotDeployed(address impl);

    function create(
        address tokenImpl,
        bytes calldata data
    ) external returns (address clone);

    function isValidDeployment(address impl) external view returns (bool);

    function registerDeployment(address impl) external;

    function unregisterDeployment(address impl) external;

    function isValidUpgrade(
        address prevImpl,
        address newImpl
    ) external returns (bool);

    function registerUpgrade(address prevImpl, address newImpl) external;

    function unregisterUpgrade(address prevImpl, address newImpl) external;
}
