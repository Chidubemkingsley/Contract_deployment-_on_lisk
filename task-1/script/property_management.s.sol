// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import {PropertyToken, PropertyManagement} from "../src/property_management.sol";

contract PropertyManagementScript is Script {
    PropertyToken      public propertyToken;
    PropertyManagement public propertyManagement;

    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = 0x89f545254ca9cdfa2241d2ef7d6cfa9cbee2c7f4cbfaacc81222666bbe8ba313;

        vm.startBroadcast(deployerPrivateKey);

        // Deploy token with 1,000,000 initial supply
        propertyToken = new PropertyToken(1_000_000);

        // Deploy management contract with token address
        propertyManagement = new PropertyManagement(address(propertyToken));

        vm.stopBroadcast();
    }
}// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import {PropertyToken, PropertyManagement} from "../src/PropertyManagement.sol";

contract PropertyManagementScript is Script {
    PropertyToken      public propertyToken;
    PropertyManagement public propertyManagement;

    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        // Deploy token with 1,000,000 initial supply
        propertyToken = new PropertyToken(1_000_000);

        // Deploy management contract with token address
        propertyManagement = new PropertyManagement(address(propertyToken));

        vm.stopBroadcast();
    }
}