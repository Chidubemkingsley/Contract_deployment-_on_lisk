// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {ERC20} from "../src/ERC20.sol";

contract ERC20Script is Script {
    ERC20 public erc20;

    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);

        // Deploy ERC20 token
        erc20 = new ERC20();
        
        // Optional: Mint initial tokens to deployer
        uint256 initialMintAmount = 1_000_000 * 10**18; // 1 million tokens
        erc20.mint(msg.sender, initialMintAmount);

        vm.stopBroadcast();

        // Log deployment information
        console.log("ERC20 Token deployed to:", address(erc20));
        console.log("Token Name:", erc20.name());
        console.log("Token Symbol:", erc20.symbol());
        console.log("Token Decimals:", erc20.decimals());
        console.log("Initial Total Supply:", erc20.totalSupply());
        console.log("Deployer Balance:", erc20.balanceOf(msg.sender));
    }
}