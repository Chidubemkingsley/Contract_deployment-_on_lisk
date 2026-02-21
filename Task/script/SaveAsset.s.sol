// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {SaveAsset} from "../src/SaveAsset.sol";

contract DeploySaveAsset is Script {
    SaveAsset public saveAsset;

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        // Get token address from .env file
        address tokenAddress = vm.envAddress("TOKEN_ADDRESS");
        
        console.log("=========================================");
        console.log(" Starting SaveAsset Deployment");
        console.log("=========================================");
        console.log("Deployer address:", deployer);
        console.log("Token address to use:", tokenAddress);
        console.log("=========================================");
        
        // Verify token address is not zero
        require(tokenAddress != address(0), " Token address cannot be zero address");
        
        vm.startBroadcast(deployerPrivateKey);

        // Deploy SaveAsset contract
        saveAsset = new SaveAsset(tokenAddress);

        vm.stopBroadcast();

        console.log("\n Deployment Successful!");
        console.log("=========================================");
        console.log(" Contract Addresses:");
        console.log("   SaveAsset Contract:", address(saveAsset));
        console.log("   Token Contract:", tokenAddress);
        console.log("=========================================");
        
        console.log("\n Initial Contract State:");
        console.log("   Contract ETH Balance:", saveAsset.getContractBalance(), "wei");
        
        // CANNOT check ERC20 balance directly - no function for it!
        // To check contract's ERC20 balance, you'd need to:
        // 1. Import IERC20
        // 2. Call token.balanceOf(address(saveAsset))
        
        console.log("\n To check contract's ERC20 balance later:");
        console.log("   cast call", tokenAddress, "\"balanceOf(address)\"", address(saveAsset));
        
        console.log("\n User Functions Available:");
        console.log("   getUserSavings() - Check your ETH savings");
        console.log("   getErc20SavingsBalance() - Check your ERC20 savings");
        console.log("=========================================");
    }
}