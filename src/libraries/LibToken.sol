// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;

import {LibStorage, TokenStorage} from "./LibStorage.sol";
import {IToken} from "../tokens/interfaces/IToken.sol";
import {IFeeManager} from "../interfaces/IFeeManager.sol";
import {IObservability} from "../observability/interface/IObservability.sol";

library LibToken {
    function ts() internal pure returns (TokenStorage storage) {
        return LibStorage.tokenStorage();
    }

    function feeForAmount(
        uint256 amount
    ) public view returns (address payable, uint256) {
        (address payable recipient, uint256 bps) = IFeeManager(ts().feeManager)
            .getWithdrawFeesBPS(address(this));
        return (recipient, (amount * bps) / 10_000);
    }

    /// @notice withdraws the funds from the contract
    function withdraw() external returns (bool) {
        uint256 FUNDS_SEND_GAS_LIMIT = 210_000;
        uint256 amount = address(this).balance;

        (address payable feeRecipent, uint256 protocolFee) = feeForAmount(
            amount
        );

        // Pay protocol fee
        if (protocolFee > 0) {
            (bool successFee, ) = feeRecipent.call{
                value: protocolFee,
                gas: FUNDS_SEND_GAS_LIMIT
            }("");

            if (!successFee) revert IToken.FundsSendFailure();
            amount -= protocolFee;
        }

        (bool successFunds, ) = ts().fundsRecipent.call{
            value: amount,
            gas: FUNDS_SEND_GAS_LIMIT
        }("");

        if (!successFunds) revert IToken.FundsSendFailure();

        IObservability(ts().o11y).emitFundsWithdrawn(
            msg.sender,
            ts().fundsRecipent,
            amount
        );
        return successFunds;
    }
}
