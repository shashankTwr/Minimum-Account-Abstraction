// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {IAccount} from "lib/foundry-era-contracts/src/system-contracts/contracts/interfaces/IAccount.sol";
import {Transaction} from
    "lib/foundry-era-contracts/src/system-contracts/contracts//libraries/MemoryTransactionHelper.sol";

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

contract ZkMinimalAccount is IAccount {
    function validateTransaction(bytes32 _txHash, bytes32 _suggestedSignedHash, Transaction calldata _transaction)
        external
        payable
        returns (bytes4 magic)
    {}

    function executeTransaction(bytes32 _txHash, bytes32 _suggestedSignedHash, Transaction calldata _transaction)
        external
        payable
    {}

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
    {}
}
