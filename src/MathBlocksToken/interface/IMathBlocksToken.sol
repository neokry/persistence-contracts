//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMathBlocksToken {
    event Purcahsed(uint256 price);
    event Withdrawn(uint256 amount);

    struct TokenInfo {
        string name;
        string symbol;
        string description;
        string script;
        address fundsRecipent;
        uint256 price;
        uint256 endsAtTimestamp;
    }

    error FactoryMustInitilize();
    error SaleHasEnded();
    error InvalidPrice();
    error SenderNotMinter();
    error FundsSendFailure();

    function initialize(address owner, TokenInfo memory info) external;

    function genericDataURI(
        string memory _name,
        string memory _description,
        uint256 seed
    ) external view returns (string memory);

    function constructAnimationURL(
        uint256 seed
    ) external view returns (string memory);

    function purchase(uint256 amount) external payable;

    function withdraw() external returns (bool);

    function safeMint(address to) external;
}
