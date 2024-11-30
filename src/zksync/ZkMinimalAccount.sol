// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

// zksync era imports
import {
    IAccount,
    ACCOUNT_VALIDATION_SUCCESS_MAGIC
} from "lib/foundry-era-contracts/src/system-contracts/contracts/interfaces/IAccount.sol";
import {
    Transaction,
    MemoryTransactionHelper
} from "lib/foundry-era-contracts/src/system-contracts/contracts/libraries/MemoryTransactionHelper.sol";
import {SystemContractsCaller} from
    "lib/foundry-era-contracts/src/system-contracts/contracts/libraries/SystemContractsCaller.sol";
import {
    NONCE_HOLDER_SYSTEM_CONTRACT,
    BOOTLOADER_FORMAL_ADDRESS,
    DEPLOYER_SYSTEM_CONTRACT
} from "lib/foundry-era-contracts/src/system-contracts/contracts/Constants.sol";
import {INonceHolder} from "lib/foundry-era-contracts/src/system-contracts/contracts/interfaces/INonceHolder.sol";
import {Utils} from "lib/foundry-era-contracts/src/system-contracts/contracts/libraries/Utils.sol";

//0z imports
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
    error ZkMinimalAccount__ExecutionFailed();
    error ZkMinimalAccount__NeitherFromBootLoaderNorOwner();
    error ZkMinimalAccount__FailedToPay();
    error ZkMinimalAccount__ValidationFailed();

    /*//////////////////////////////////////////////////////////////
                                MODIFIER
    //////////////////////////////////////////////////////////////*/
    modifier requireFromBootLoader() {
        if (msg.sender != BOOTLOADER_FORMAL_ADDRESS) {
            revert ZkMinimalAccount__NotFromBootLoader();
        }
        _;
    }

    modifier requireFromBootLoaderOrOwner() {
        if (msg.sender != BOOTLOADER_FORMAL_ADDRESS && msg.sender != owner()) {
            revert ZkMinimalAccount__NeitherFromBootLoaderNorOwner();
        }
        _;
    }

    /*//////////////////////////////////////////////////////////////
                               FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    constructor() Ownable(msg.sender) {}
    receive() external payable {}

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
        return _validateTransaction(_transaction);
    }

    function executeTransaction(
        bytes32, /* _txHash */
        bytes32, /* _suggestedSignedHash */
        Transaction calldata _transaction
    ) external payable {
        _executeTransaction(_transaction);
    }

    // you signed a tx
    // send a signed tx to your friend
    // they can send it by calling this function

    // There is no point in providing possible signed hash in the `executeTransactionFromOutside` method,
    // since it typically should not be trusted.
    function executeTransactionFromOutside(Transaction calldata _transaction) external payable {
        bytes4 magic = _validateTransaction(_transaction);
        if (magic != bytes4(0)) {
            revert ZkMinimalAccount__ValidationFailed();
        }
        _executeTransaction(_transaction);
    }

    function payForTransaction(
        bytes32, /* _txHash */
        bytes32, /* _suggestedSignedHash */
        Transaction calldata _transaction
    ) external payable {
        bool success = _transaction.payToTheBootloader();
        if (!success) {
            revert ZkMinimalAccount__FailedToPay();
        }
        _executeTransaction(_transaction);
    }

    // Called when u are a paymaster
    function prepareForPaymaster(
        bytes32, /* _txHash */
        bytes32, /* _possibleSignedHash */
        Transaction calldata _transaction
    ) external payable {}

    /*//////////////////////////////////////////////////////////////
                           INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    function _validateTransaction(Transaction calldata _transaction) internal returns (bytes4 magic) {
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
        return magic;
    }

    function _executeTransaction(Transaction calldata _transaction) internal requireFromBootLoaderOrOwner {
        address to = address(uint160(_transaction.to)); //uint256 to add
        uint128 value = Utils.safeCastToU128(_transaction.value);
        bytes memory data = _transaction.data;

        if (to == address(DEPLOYER_SYSTEM_CONTRACT)) {
            uint32 gas = Utils.safeCastToU32(gasleft());
            SystemContractsCaller.systemCallWithPropagatedRevert(gas, to, value, data);
        } else {
            bool success;
            assembly {
                success := call(gas(), to, value, add(data, 0x20), mload(data), 0, 0)
            }
            if (!success) {
                revert ZkMinimalAccount__ExecutionFailed();
            }
        }
    }
}
