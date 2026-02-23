// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {PropertyToken, PropertyManagement} from "../src/property_management.sol";

contract PropertyDeploymentScript is Script {
    PropertyToken public propertyToken;
    PropertyManagement public propertyManagement;

    function run() public {
        // Load private key from .env
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        // Start broadcasting transactions
        vm.startBroadcast(deployerPrivateKey);

        // Step 1: Deploy PropertyToken with initial supply (e.g., 1,000,000 tokens)
        uint256 initialSupply = 1_000_000;
        propertyToken = new PropertyToken(initialSupply);
        
        console.log("PropertyToken deployed to:", address(propertyToken));
        console.log("PropertyToken name:", propertyToken.name());
        console.log("PropertyToken symbol:", propertyToken.symbol());

        // Step 2: Deploy PropertyManagement, passing the token address
        propertyManagement = new PropertyManagement(address(propertyToken));
        
        console.log("PropertyManagement deployed to:", address(propertyManagement));
        console.log("PropertyManagement token address:", address(propertyManagement.token()));
        
        // Optional: Grant AGENT_ROLE to deployer if needed
        // bytes32 AGENT_ROLE = propertyManagement.AGENT_ROLE();
        // propertyManagement.grantRole(AGENT_ROLE, msg.sender);
        // console.log("Granted AGENT_ROLE to deployer");

        vm.stopBroadcast();
    }
}