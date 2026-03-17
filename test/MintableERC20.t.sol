// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Test} from "forge-std/Test.sol";

import {MintableERC20} from "../src/MintableERC20.sol";

contract MintableERC20Test is Test {
    address private owner = makeAddr("owner");
    address private recipient = makeAddr("recipient");
    MintableERC20 private token;

    function setUp() public {
        token = new MintableERC20("Example Stablecoin", "EXUSD", 6, owner);
    }

    function test_ConstructorSetsMetadataAndOwner() public view {
        assertEq(token.name(), "Example Stablecoin");
        assertEq(token.symbol(), "EXUSD");
        assertEq(token.decimals(), 6);
        assertEq(token.owner(), owner);
    }

    function test_OwnerCanMint() public {
        vm.prank(owner);
        token.mint(recipient, 1_250_000);

        assertEq(token.balanceOf(recipient), 1_250_000);
        assertEq(token.totalSupply(), 1_250_000);
    }

    function test_NonOwnerCannotMint() public {
        address attacker = makeAddr("attacker");

        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", attacker));
        vm.prank(attacker);
        token.mint(recipient, 1);
    }
}
