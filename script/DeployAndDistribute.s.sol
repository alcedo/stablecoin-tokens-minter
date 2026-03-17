// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Script, console2} from "forge-std/Script.sol";

import {MintableERC20} from "../src/MintableERC20.sol";

struct TokenConfig {
    string name;
    string symbol;
    uint8 decimals;
    address finalOwner;
}

struct Recipient {
    address to;
    uint256 amount;
}

abstract contract DeployAndDistributeBase is Script {
    error EmptyTokenName();
    error EmptyTokenSymbol();
    error ZeroFinalOwner();
    error EmptyRecipients();
    error ZeroRecipientAddress(uint256 index);
    error ZeroRecipientAmount(uint256 index);
    error DuplicateRecipient(address recipient);

    function _tokenConfig() internal view virtual returns (TokenConfig memory);

    function _recipients() internal view virtual returns (Recipient[] memory);

    function validate()
        public
        view
        returns (TokenConfig memory tokenConfig, Recipient[] memory recipients, uint256 totalAmount)
    {
        tokenConfig = _tokenConfig();
        recipients = _recipients();
        totalAmount = validateInputs(tokenConfig, recipients);
    }

    function validateInputs(TokenConfig memory tokenConfig, Recipient[] memory recipients)
        public
        pure
        returns (uint256 totalAmount)
    {
        if (bytes(tokenConfig.name).length == 0) {
            revert EmptyTokenName();
        }
        if (bytes(tokenConfig.symbol).length == 0) {
            revert EmptyTokenSymbol();
        }
        if (tokenConfig.finalOwner == address(0)) {
            revert ZeroFinalOwner();
        }
        if (recipients.length == 0) {
            revert EmptyRecipients();
        }

        for (uint256 i = 0; i < recipients.length; ++i) {
            Recipient memory recipient = recipients[i];

            if (recipient.to == address(0)) {
                revert ZeroRecipientAddress(i);
            }
            if (recipient.amount == 0) {
                revert ZeroRecipientAmount(i);
            }

            totalAmount += recipient.amount;

            for (uint256 j = i + 1; j < recipients.length; ++j) {
                if (recipient.to == recipients[j].to) {
                    revert DuplicateRecipient(recipient.to);
                }
            }
        }
    }

    function deployForTest(TokenConfig memory tokenConfig, Recipient[] memory recipients)
        public
        returns (MintableERC20 token, uint256 totalAmount)
    {
        totalAmount = validateInputs(tokenConfig, recipients);
        token = _deployAndDistribute(tokenConfig, recipients, address(this), false);
    }

    function run() external returns (MintableERC20 token) {
        (TokenConfig memory tokenConfig, Recipient[] memory recipients, uint256 totalAmount) = validate();

        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        address broadcaster = vm.addr(privateKey);

        _logPreflight(tokenConfig, recipients.length, totalAmount, broadcaster);

        vm.startBroadcast(privateKey);
        token = _deployAndDistribute(tokenConfig, recipients, broadcaster, true);
        vm.stopBroadcast();

        console2.log("Deployment complete.");
        console2.log("Token address:");
        console2.logAddress(address(token));
    }

    function _deployAndDistribute(
        TokenConfig memory tokenConfig,
        Recipient[] memory recipients,
        address temporaryOwner,
        bool emitLogs
    ) internal returns (MintableERC20 token) {
        token = new MintableERC20(tokenConfig.name, tokenConfig.symbol, tokenConfig.decimals, temporaryOwner);

        if (emitLogs) {
            console2.log("Token deployed at:");
            console2.logAddress(address(token));
        }

        for (uint256 i = 0; i < recipients.length; ++i) {
            Recipient memory recipient = recipients[i];
            token.mint(recipient.to, recipient.amount);

            if (emitLogs) {
                console2.log("Minted recipient:");
                console2.logAddress(recipient.to);
                console2.log("Minted amount:");
                console2.logUint(recipient.amount);
            }
        }

        if (tokenConfig.finalOwner != temporaryOwner) {
            token.transferOwnership(tokenConfig.finalOwner);
        }
    }

    function _logPreflight(
        TokenConfig memory tokenConfig,
        uint256 recipientCount,
        uint256 totalAmount,
        address broadcaster
    ) internal view {
        console2.log("Chain ID:");
        console2.logUint(block.chainid);
        console2.log("Broadcaster:");
        console2.logAddress(broadcaster);
        console2.log("Token name:");
        console2.log(tokenConfig.name);
        console2.log("Token symbol:");
        console2.log(tokenConfig.symbol);
        console2.log("Token decimals:");
        console2.logUint(tokenConfig.decimals);
        console2.log("Final owner:");
        console2.logAddress(tokenConfig.finalOwner);
        console2.log("Recipient count:");
        console2.logUint(recipientCount);
        console2.log("Total mint amount:");
        console2.logUint(totalAmount);
    }
}

contract DeployAndDistribute is DeployAndDistributeBase {
    function _tokenConfig() internal pure override returns (TokenConfig memory config) {
        // Edit these values before running the wrapper or the script directly.
        config = TokenConfig({name: "Example Stablecoin", symbol: "EXUSD", decimals: 18, finalOwner: address(0)});
    }

    function _recipients() internal pure override returns (Recipient[] memory recipients) {
        // Add recipients before running. Validation intentionally rejects an empty list.
        recipients = new Recipient[](0);
    }
}
