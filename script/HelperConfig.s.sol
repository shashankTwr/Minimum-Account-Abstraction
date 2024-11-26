// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";

contract HelperConfig is Script {
    error HelperConfig__InvalidChainId();

    struct NetworkConfig {
        address entryPoint;
        address account;
    }

    uint256 constant ETH_SEPOLIA_CHAIN_ID = 11155111;
    uint256 constant LOCAL_ANVIL_CHAIN_ID = 31337;
    uint256 constant ZKSYNC_SEPOLIA_CHAIN_ID = 300;
    address constant BURNER_WALLET = 0x0Abc0Cfa05c66A1d13bB67a31c3d93A0d8DAacBE;
    address constant FOUNDRY_DEFAULT_SENDER = 0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38;

    NetworkConfig public localNetworkConfig;
    mapping(uint256 chainId => NetworkConfig) public networkConfigs;

    constructor() {
        networkConfigs[ETH_SEPOLIA_CHAIN_ID] = getEthSepoliaConfig();
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

    function getEthSepoliaConfig() public pure returns (NetworkConfig memory) {
        return NetworkConfig({entryPoint: 0x0576a174D229E3cFA37253523E645A78A0C91B57, account: BURNER_WALLET});
    }

    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
        if (localNetworkConfig.entryPoint != address(0)) {
            return localNetworkConfig;
        }

        // deploy a mock entry point contract

        return NetworkConfig({entryPoint: address(0), account: FOUNDRY_DEFAULT_SENDER});
    }

    function getZkSyncSepoliaConfig() public pure returns (NetworkConfig memory) {
        return NetworkConfig({entryPoint: address(0), account: BURNER_WALLET});
    }
}
