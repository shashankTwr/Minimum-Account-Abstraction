// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {MinimalAccount} from "../src/ethereum/MinimalAccount.sol";
import {PackedUserOperation} from "lib/account-abstraction/contracts/interfaces/PackedUserOperation.sol";

contract SendPackedUserOp is Script {
    function run() public {}

    function generatedSignedUserOperation(bytes memory callData, address sender) public returns (PackedUserOperation) {
        // 1. Generate the unsigned data
        uint256 nonce = vm.getNonce(sender);
        PackedUserOperation memory unsignedUserOp = _generateUnsignedUserOperation(callData, sender, nonce);
        // 2. Sign it and return it
    }

    function _generateUnsignedUserOperation(bytes memory callData, address sender, uint256 nonce)
        internal
        pure
        returns (PackedUserOperation)
    {
        uint128 verificationGasLimit = 16777216;
        uint128 callGasLimit = verificationGasLimit;
        uint256 maxPriorityFeePerGas = 256;
        uint256 maxFeePerGas = maxPriorityFeePerGas;

        return PackedUserOperation({
            sender: sender,
            nonce: nonce,
            initCode: hex"",
            callData: callData,
            accountGasLimits: bytes32(uint256(verificationGasLimit) << 128 | callGasLimit),
            preVerificationGas: verificationGasLimit,
            gasFees: bytes32(uint256(maxPriorityFeePerGas) << 128 | maxFeePerGas),
            paymasterAndData: hex"",
            signature: hex""
        });
    }
}
