// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Test} from "forge-std/Test.sol";

import {DeployAndDistributeBase, Recipient, TokenConfig} from "../script/DeployAndDistribute.s.sol";
import {MintableERC20} from "../src/MintableERC20.sol";

contract DeployAndDistributeHarness is DeployAndDistributeBase {
    TokenConfig private _storedConfig;
    Recipient[] private _storedRecipients;

    constructor(TokenConfig memory config_, Recipient[] memory recipients_) {
        _storedConfig = config_;

        for (uint256 i = 0; i < recipients_.length; ++i) {
            _storedRecipients.push(recipients_[i]);
        }
    }

    function _tokenConfig() internal view override returns (TokenConfig memory) {
        return _storedConfig;
    }

    function _recipients() internal view override returns (Recipient[] memory recipients) {
        recipients = new Recipient[](_storedRecipients.length);

        for (uint256 i = 0; i < _storedRecipients.length; ++i) {
            recipients[i] = _storedRecipients[i];
        }
    }
}

contract DeployAndDistributeTest is Test {
    function test_ValidateRejectsEmptyRecipients() public {
        Recipient[] memory recipients = new Recipient[](0);
        DeployAndDistributeHarness harness = new DeployAndDistributeHarness(_defaultConfig(), recipients);

        vm.expectRevert(DeployAndDistributeBase.EmptyRecipients.selector);
        harness.validate();
    }

    function test_ValidateRejectsZeroRecipientAddress() public {
        Recipient[] memory recipients = new Recipient[](1);
        recipients[0] = Recipient({to: address(0), amount: 10 ether});

        DeployAndDistributeHarness harness = new DeployAndDistributeHarness(_defaultConfig(), recipients);

        vm.expectRevert(abi.encodeWithSelector(DeployAndDistributeBase.ZeroRecipientAddress.selector, 0));
        harness.validate();
    }

    function test_ValidateRejectsZeroRecipientAmount() public {
        Recipient[] memory recipients = new Recipient[](1);
        recipients[0] = Recipient({to: makeAddr("recipient"), amount: 0});

        DeployAndDistributeHarness harness = new DeployAndDistributeHarness(_defaultConfig(), recipients);

        vm.expectRevert(abi.encodeWithSelector(DeployAndDistributeBase.ZeroRecipientAmount.selector, 0));
        harness.validate();
    }

    function test_ValidateRejectsDuplicateRecipients() public {
        address duplicate = makeAddr("duplicate");
        Recipient[] memory recipients = new Recipient[](2);
        recipients[0] = Recipient({to: duplicate, amount: 10 ether});
        recipients[1] = Recipient({to: duplicate, amount: 20 ether});

        DeployAndDistributeHarness harness = new DeployAndDistributeHarness(_defaultConfig(), recipients);

        vm.expectRevert(abi.encodeWithSelector(DeployAndDistributeBase.DuplicateRecipient.selector, duplicate));
        harness.validate();
    }

    function test_DeployForTestMintsAndTransfersOwnership() public {
        Recipient[] memory recipients = _defaultRecipients();
        DeployAndDistributeHarness harness = new DeployAndDistributeHarness(_defaultConfig(), recipients);

        (MintableERC20 token, uint256 totalAmount) = harness.deployForTest(_defaultConfig(), recipients);

        assertEq(address(token.owner()), _defaultConfig().finalOwner);
        assertEq(token.balanceOf(recipients[0].to), recipients[0].amount);
        assertEq(token.balanceOf(recipients[1].to), recipients[1].amount);
        assertEq(token.totalSupply(), totalAmount);
    }

    function test_ValidateReturnsTotalMintAmount() public {
        Recipient[] memory recipients = _defaultRecipients();
        DeployAndDistributeHarness harness = new DeployAndDistributeHarness(_defaultConfig(), recipients);

        (,, uint256 totalAmount) = harness.validate();

        assertEq(totalAmount, recipients[0].amount + recipients[1].amount);
    }

    function _defaultConfig() internal pure returns (TokenConfig memory) {
        return TokenConfig({
            name: "Example Stablecoin",
            symbol: "EXUSD",
            decimals: 18,
            finalOwner: address(0x9999999999999999999999999999999999999999)
        });
    }

    function _defaultRecipients() internal pure returns (Recipient[] memory recipients) {
        recipients = new Recipient[](2);
        recipients[0] = Recipient({to: address(0x1111111111111111111111111111111111111111), amount: 1_000_000 ether});
        recipients[1] = Recipient({to: address(0x2222222222222222222222222222222222222222), amount: 2_500_000 ether});
    }
}
