// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {SchoolToken, SchoolManagementSystem} from "../src/school_management.sol";

contract SchoolSystemScript is Script {
    SchoolToken public token;
    SchoolManagementSystem public sms;

    // Tuition fees configuration (in STKN wei units)
    uint256 constant FEE_LEVEL_100 = 100 * 10**18;  // 100 STKN
    uint256 constant FEE_LEVEL_200 = 150 * 10**18;  // 150 STKN
    uint256 constant FEE_LEVEL_300 = 200 * 10**18;  // 200 STKN
    uint256 constant FEE_LEVEL_400 = 250 * 10**18;  // 250 STKN
    uint256 constant INITIAL_SUPPLY = 1000000;       // 1,000,000 STKN (total supply before decimals)

    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);

        // Step 1: Deploy SchoolToken with initial supply
        token = new SchoolToken(INITIAL_SUPPLY);
        
        // Step 2: Deploy SchoolManagementSystem with token address and tuition fees
        sms = new SchoolManagementSystem(
            address(token),
            FEE_LEVEL_100,
            FEE_LEVEL_200,
            FEE_LEVEL_300,
            FEE_LEVEL_400
        );

        // Optional: Transfer some tokens to the school management system for operations
        // This will fund the treasury for paying staff salaries
        uint256 treasuryFunding = 50000 * 10**18; // 50,000 STKN
        token.transfer(address(sms), treasuryFunding);

        vm.stopBroadcast();

        // Log deployment addresses for reference
        console.log("SchoolToken deployed to:", address(token));
        console.log("SchoolManagementSystem deployed to:", address(sms));
        console.log("Treasury funded with:", treasuryFunding / 10**18, "STKN");
    }
}