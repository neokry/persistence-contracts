//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface IMathBlocksToken {
    struct TokenInfo {
        string name;
        string symbol;
        string description;
        string script;
        address fundsRecipent;
        uint256 price;
        uint256 startsAtTimestamp;
        uint256 endsAtTimestamp;
    }

    error FactoryMustInitilize();
    error SaleNotActive();
    error InvalidPrice();
    error SenderNotMinter();
    error FundsSendFailure();

    function initialize(
        address owner,
        address htmlRenderer,
        TokenInfo memory info
    ) external;

    function genericDataURI(
        string memory _name,
        string memory _description,
        uint256 seed,
        string memory tokenId
    ) external view returns (string memory);

    function constructAnimationURL(
        uint256 seed,
        string memory tokenId
    ) external view returns (string memory);

    function purchase(uint256 amount) external payable;

    function withdraw() external returns (bool);

    function safeMint(address to) external;
}
