// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IAccount} from "lib/account-abstraction/contracts/interfaces/IAccount.sol";
import {PackedUserOperation} from "lib/account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import {Ownable} from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {MessageHashUtils} from "lib/openzeppelin-contracts/contracts/utils/cryptography/MessageHashUtils.sol";
import {ECDSA} from "lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";
import {SIG_VALIDATION_SUCCESS, SIG_VALIDATION_FAILED} from "lib/account-abstraction/contracts/core/Helpers.sol";
import {IEntryPoint} from "lib/account-abstraction/contracts/interfaces/IEntryPoint.sol";

contract MinimalAccount is IAccount, Ownable {
    // entrypoint -> this contract
    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/
    error MinimalAccount__NotEntryPoint();
    error MinimalAccount__NeitherEntryPointNorOwner();
    error MinimumAccount_ExecutionFailed();

    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/
    IEntryPoint private immutable i_entryPoint;

    /*//////////////////////////////////////////////////////////////
                               MODIFIERS
    //////////////////////////////////////////////////////////////*/
    modifier requireFromEntryPoint() {
        if (msg.sender != address(i_entryPoint)) {
            revert MinimalAccount__NotEntryPoint();
        }
        _;
    }

    modifier requireFromEntryPointOrOwner() {
        if (msg.sender != address(i_entryPoint) && msg.sender != owner()) {
            revert MinimalAccount__NeitherEntryPointNorOwner();
        }
        _;
    }

    /*//////////////////////////////////////////////////////////////
                               FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    constructor(address entryPoint) Ownable(msg.sender) {
        i_entryPoint = IEntryPoint(entryPoint);
    }

    /*//////////////////////////////////////////////////////////////
                           EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function recieve() external payable {}

    function execute(address dest, uint256 value, bytes calldata functionData) external requireFromEntryPointOrOwner {
        (bool success, bytes memory result) = dest.call{value: value}(functionData);
        if (!success) {
            revert MinimumAccount_ExecutionFailed();
        }
    }

    // A signature is valid, if it is the MinimalAccount's owner
    function validateUserOp(PackedUserOperation calldata userOp, bytes32 userOpHash, uint256 missingAccountFunds)
        external
        requireFromEntryPoint
        returns (uint256 validationData)
    {
        validationData = _validateSignature(userOp, userOpHash);
        // _validateNonce() -> nonce validation
        // missingAccountFunds -> amount money
        _payPrefund(missingAccountFunds);
    }

    // EIP-191 Version of the signed hash
    function _validateSignature(PackedUserOperation calldata userOp, bytes32 userOpHash)
        internal
        view
        returns (uint256 validationData)
    {
        bytes32 ethSignedMessageHash = MessageHashUtils.toEthSignedMessageHash(userOpHash);

        address signer = ECDSA.recover(ethSignedMessageHash, userOp.signature);

        if (signer != owner()) {
            return SIG_VALIDATION_FAILED;
        }
        return SIG_VALIDATION_SUCCESS;
    }

    function _payPrefund(uint256 missingAccountFunds) internal {
        if (missingAccountFunds != 0) {
            (bool success,) = payable(msg.sender).call{value: missingAccountFunds, gas: type(uint256).max}("");
            (success);
            //ignore failure (its EntryPoint's job to verify, not account.)
        }
    }

    /*//////////////////////////////////////////////////////////////
                                GETTERS
    //////////////////////////////////////////////////////////////*/
    function getEntryPoint() public view returns (address) {
        return address(i_entryPoint);
    }
}
