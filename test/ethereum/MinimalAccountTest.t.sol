// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {MinimalAccount} from "../../src/ethereum/MinimalAccount.sol";
import {DeployMinimalAccount} from "../../script/DeployMinimalAccount.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

contract MinimalAccountTest is Test {
    HelperConfig helperConfig;
    MinimalAccount minimalAccount;
    ERC20Mock usdc;

    uint256 constant MINT_AMOUNT = 1e18;
    address RANDOM_USER = makeAddr("RANDOM_USER");

    function setUp() public {
        DeployMinimalAccount deployMinimal = new DeployMinimalAccount();
        (helperConfig, minimalAccount) = deployMinimal.deployMinimalAccount();
        usdc = new ERC20Mock();
    }

    // USDC Mint
    // msg.sender -> MinimalAccount
    // approve some ammount
    // USDC contract
    // come from the entrypoint
    function testOwnerCanExecuteCommands() public {
        // Arrange
        assertEq(usdc.balanceOf(address(minimalAccount)), 0);
        address dest = address(usdc);
        uint256 value = 0;
        bytes memory functionData =
            abi.encodeWithSelector(ERC20Mock.mint.selector, address(minimalAccount), MINT_AMOUNT);
        // Act
        vm.prank(minimalAccount.owner());
        minimalAccount.execute(dest, value, functionData);
        // make minimalAccount mint USDC

        // Assert
        assertEq(usdc.balanceOf(address(minimalAccount)), MINT_AMOUNT);
    }

    function testNonOwnerCannotExecuteCommands() public {
        // Arrange
        assertEq(usdc.balanceOf(address(minimalAccount)), 0);
        address dest = address(usdc);
        uint256 value = 0;
        bytes memory functionData =
            abi.encodeWithSelector(ERC20Mock.mint.selector, address(minimalAccount), MINT_AMOUNT);
        // Act
        vm.prank(RANDOM_USER);
        vm.expectRevert(MinimalAccount.MinimalAccount__NeitherEntryPointNorOwner.selector);
        minimalAccount.execute(dest, value, functionData);
    }

    function testValidationOfUserOps() public {}
}
