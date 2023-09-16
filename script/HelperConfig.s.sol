// SPDX-License-Identifier: MIT

// 1. Deploy mocks when we are on a local anvil chain
// 2. Keep track of contract address across different chains
// e.g. Sepolia ETH/USD price feed address is different from Rinkeby's and Mainnet's
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {FundMe} from "../src/FundMe.sol";
import {MockV3Aggregator} from "../test/mocks/MockV3Aggregator.sol";

contract HelperConfig is Script {
    // if we are on a local anvil chain, we want to deploy mocks
    // if we are on a testnet, grab the existing address from the live network

    struct NetworkConfig {
        address priceFeedAddress; // ETH/USD price feed address
    }

    NetworkConfig public activeNetworkConfig;
    uint8 public constant DECIMALS = 8;
    int256 public constant INITIAL_PRICE = 2000e8; // 2000 USD

    constructor() {
        if (block.chainid == 11155111) {
            activeNetworkConfig = getSepoliaETHConfig();
        } else if (block.chainid == 1) {
            activeNetworkConfig = getMainnetETHConfig();
        } else {
            activeNetworkConfig = getOrCreateAnvilETHConfig();
        }
    }

    function getSepoliaETHConfig() public pure returns(NetworkConfig memory) {
        // memory because it's a struct (special type)
        NetworkConfig memory sepoliaConfig = NetworkConfig({
            priceFeedAddress: 0x694AA1769357215DE4FAC081bf1f309aDC325306
        });
        return sepoliaConfig;
    }

    function getMainnetETHConfig() public pure returns(NetworkConfig memory) {
        NetworkConfig memory mainnetConfig = NetworkConfig({
            priceFeedAddress: address(0x694AA1769357215DE4FAC081bf1f309aDC325306)
        });
        return mainnetConfig;
    }

    function getOrCreateAnvilETHConfig() public returns(NetworkConfig memory) {
        if (activeNetworkConfig.priceFeedAddress != address(0)) {
            return activeNetworkConfig; // make sure it's not already set
        }

        // price feed address: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
        // 1. Deploy the mocks
        // 2. Return the mock address
        vm.startBroadcast();
        MockV3Aggregator mockPriceFeed = new MockV3Aggregator(DECIMALS, INITIAL_PRICE);
        vm.stopBroadcast();
        NetworkConfig memory anvilConfig = NetworkConfig({
            priceFeedAddress: address(mockPriceFeed)
        });
        return anvilConfig;
    }

    function getChainID() public view returns (uint256) {
        return block.chainid;
    }
}