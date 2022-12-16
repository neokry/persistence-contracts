//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IToken {
    struct TokenInfo {
        string name;
        string symbol;
        string description;
        address fundsRecipent;
        uint256 totalSupply;
    }

    error FactoryMustInitilize();
    error SenderNotMinter();
    error FundsSendFailure();

    function withdraw() external returns (bool);

    function safeMint(address to) external;

    function initialize(address owner, bytes calldata data) external;
}
