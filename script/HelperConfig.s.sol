// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script, console2} from "forge-std/Script.sol";
import {EntryPoint} from "lib/account-abstraction/contracts/core/EntryPoint.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

struct NetworkConfig {
    address entryPoint;
    address account;
}

contract HelperConfig is Script {
    error HelperConfig__InvalidChainId();

    uint256 constant ETH_MAINNET_CHAIN_ID = 1;
    uint256 constant ETH_SEPOLIA_CHAIN_ID = 11155111;
    uint256 constant ZKSYNC_MAINNET_CHAIN_ID = 324;
    uint256 constant ZKSYNC_SEPOLIA_CHAIN_ID = 300;
    uint256 constant ARBITRUM_SEPOLIA_CHAIN_ID = 421614;
    uint256 constant ARBITRUM_MAINNET_CHAIN_ID = 42_161;

    uint256 constant LOCAL_ANVIL_CHAIN_ID = 31337;

    address constant BURNER_WALLET = 0x0Abc0Cfa05c66A1d13bB67a31c3d93A0d8DAacBE;
    address constant ANVIL_DEFAULT_ACCOUNT = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;

    NetworkConfig public localNetworkConfig;
    mapping(uint256 chainId => NetworkConfig) public networkConfigs;

    constructor() {
        networkConfigs[ETH_MAINNET_CHAIN_ID] = getEthMainnetConfig();
        networkConfigs[ETH_SEPOLIA_CHAIN_ID] = getEthSepoliaConfig();
        networkConfigs[ARBITRUM_SEPOLIA_CHAIN_ID] = getArbSepoliaConfig();
        networkConfigs[ARBITRUM_MAINNET_CHAIN_ID] = getArbMainnetConfig();
        networkConfigs[ZKSYNC_SEPOLIA_CHAIN_ID] = getZkSyncConfig();
        networkConfigs[ZKSYNC_MAINNET_CHAIN_ID] = getZkSyncConfig();
    }

    function getConfig() public returns (NetworkConfig memory) {
        return getConfigByChainId(block.chainid);
    }

    function getConfigByChainId(uint256 chainId) public returns (NetworkConfig memory) {
        if (chainId == LOCAL_ANVIL_CHAIN_ID) {
            return getOrCreateAnvilEthConfig();
        } else if (networkConfigs[chainId].account != address(0)) {
            return networkConfigs[chainId];
        } else {
            revert HelperConfig__InvalidChainId();
        }
    }

    function getArbMainnetConfig() public pure returns (NetworkConfig memory) {
        return NetworkConfig({
            entryPoint: 0x0000000071727De22E5E9d8BAf0edAc6f37da032,
            // usdc: 0xaf88d065e77c8cC2239327C5EDb3A432268e5831,
            account: BURNER_WALLET
        });
    }

    function getArbSepoliaConfig() public pure returns (NetworkConfig memory) {
        return (NetworkConfig({entryPoint: 0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789, account: BURNER_WALLET}));
    }

    function getEthMainnetConfig() public pure returns (NetworkConfig memory) {
        // This is v7
        return NetworkConfig({
            entryPoint: 0x0000000071727De22E5E9d8BAf0edAc6f37da032,
            // usdc: 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48,
            account: BURNER_WALLET
        });
        // https://blockscan.com/address/0x0000000071727De22E5E9d8BAf0edAc6f37da032
    }

    function getEthSepoliaConfig() public pure returns (NetworkConfig memory) {
        return NetworkConfig({entryPoint: 0x0576a174D229E3cFA37253523E645A78A0C91B57, account: BURNER_WALLET});
    }

    function getZkSyncConfig() public pure returns (NetworkConfig memory) {
        return NetworkConfig({
            entryPoint: address(0), // supports native AA, so no entry point needed
            // usdc: 0x1d17CBcF0D6D143135aE902365D2E5e2A16538D4,
            account: BURNER_WALLET
        });
    }

    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
        if (localNetworkConfig.entryPoint != address(0)) {
            return localNetworkConfig;
        }

        // deploy a mock entry point contract
        console2.log("Deploying mocks..");
        vm.startBroadcast(ANVIL_DEFAULT_ACCOUNT);
        ERC20Mock usdc = new ERC20Mock();
        EntryPoint entryPoint = new EntryPoint();
        vm.stopBroadcast();

        localNetworkConfig = NetworkConfig({entryPoint: address(entryPoint), account: ANVIL_DEFAULT_ACCOUNT});

        return localNetworkConfig;
    }
}
