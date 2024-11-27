// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {
    IAccount,
    ACCOUNT_VALIDATION_SUCCESS_MAGIC
} from "lib/foundry-era-contracts/src/system-contracts/contracts/interfaces/IAccount.sol";
import {
    Transaction,
    MemoryTransactionHelper,
    EIP_712_TX_TYPE
} from "lib/foundry-era-contracts/src/system-contracts/contracts//libraries/MemoryTransactionHelper.sol";
import {SystemContractsCaller} from
    "lib/foundry-era-contracts/src/system-contracts/contracts/libraries/SystemContractsCaller.sol";
import {
    NONCE_HOLDER_SYSTEM_CONTRACT,
    BOOTLOADER_FORMAL_ADDRESS
} from "lib/foundry-era-contracts/src/system-contracts/contracts/Constants.sol";
import {INonceHolder} from "lib/foundry-era-contracts/src/system-contracts/contracts/interfaces/INonceHolder.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/* 
* Lifecycle of a type 113(0x71) transaction
* msg.sender is the bootloader system contract
* Phase 1 Validation
* 1. The user sends the transaction to the "zkSync API client"(sort of a "light node")
* 2. The zkSync API client checks to see the nonce is unique by querying the NonceHolder system contract
* 3. The zkSync API client calls the `validateTransaction` which must update Nonce
* 4. The zkSync API client checks the nonce is updated
* 5. The zkSync API client calls payForTransaction or PrepareForPaymaster & validateAndPayForPlayMasterTransaction
* 6. the zkSync API client verifies that bootloader gets paid
*
* 
* 
* Phase 2 Execution
* 7. the zkSync API client passes the validated transaction to the main node/ sequencer (both are same currently)
* 8. main node will call the executeTransaction
* 9. If a paymaster is used postTransaction is called
*/

contract ZkMinimalAccount is IAccount, Ownable {
    using MemoryTransactionHelper for Transaction;

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/
    error ZkMinimalAccount__NotEnoughBalance();
    error ZkMinimalAccount__NotFromBootLoader();

    /*//////////////////////////////////////////////////////////////
                                MODIFIER
    //////////////////////////////////////////////////////////////*/
    modifier requireFromBootLoader() {
        if (msg.sender != BOOTLOADER_FORMAL_ADDRESS) {
            revert ZkMinimalAccount__NotFromBootLoader();
        }
        _;
    }

    /*//////////////////////////////////////////////////////////////
                               FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    constructor() Ownable(msg.sender) {}

    /*//////////////////////////////////////////////////////////////
                           EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    /*
    /// @notice Must increase the nonce
    /// @notice Must validate the transaction (check the owner signed the transaction)
    /// @param _txHash
    /// @param _suggestedSignedHash )
    /// @param _transaction Structure used to represent a zkSync transaction.
    /// @return magic The magic value that should be equal to the signature of this function
    /// if the user agrees to proceed with the transaction
    */
    function validateTransaction(
        bytes32, /* _txHash */
        bytes32, /* _suggestedSignedHash */
        Transaction calldata _transaction
    ) external payable requireFromBootLoader returns (bytes4 magic) {
        // Call nonceholder
        // increment nonce
        // call(x,y,z) -> system contract call
        SystemContractsCaller.systemCallWithPropagatedRevert(
            uint32(gasleft()),
            address(NONCE_HOLDER_SYSTEM_CONTRACT),
            0,
            abi.encodeCall(INonceHolder.incrementMinNonceIfEquals, (_transaction.nonce))
        );

        // check for fee to pay
        uint256 totalRequiredBalance = _transaction.totalRequiredBalance();
        if (totalRequiredBalance > address(this).balance) {
            revert ZkMinimalAccount__NotEnoughBalance();
        }

        // check the signature
        bytes32 txHash = _transaction.encodeHash();
        bytes32 convertedHash = MessageHashUtils.toEthSignedMessageHash(txHash);
        address signer = ECDSA.recover(convertedHash, _transaction.signature);
        bool isValidSignature = signer == owner();
        // return the "magic" number
        if (isValidSignature) {
            magic = ACCOUNT_VALIDATION_SUCCESS_MAGIC;
        } else {
            magic = bytes4(0);
        }
    }

    function executeTransaction(
        bytes32, /* _txHash */
        bytes32, /* _suggestedSignedHash */
        Transaction calldata _transaction
    ) external payable {}

    /* 
    // you signed a tx
    // send a signed tx to your friend
    // they can send it by calling this function

    // There is no point in providing possible signed hash in the `executeTransactionFromOutside` method,
    // since it typically should not be trusted.
    function executeTransactionFromOutside(Transaction calldata _transaction) external payable {}

    function payForTransaction(bytes32 _txHash, bytes32 _suggestedSignedHash, Transaction calldata _transaction)
        external
        payable
    {}

    // Called when u are a paymaster
    function prepareForPaymaster(bytes32 _txHash, bytes32 _possibleSignedHash, Transaction calldata _transaction)
        external
        payable
    {} */

    /*//////////////////////////////////////////////////////////////
                           INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/
}
