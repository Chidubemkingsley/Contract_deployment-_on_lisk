// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {SaveEther} from "../src/SaveEther.sol";

contract SaveEtherScript is Script {
    SaveEther public saveEther;

    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);

        // Deploy SaveEther contract
        saveEther = new SaveEther();

        vm.stopBroadcast();

        // Log deployment information
        console.log("SaveEther contract deployed to:", address(saveEther));
        console.log("Initial contract balance:", saveEther.getContractBalance());
        console.log("Deployer savings:", saveEther.getUserSavings());
        
        // Optional: Make an initial deposit
        // uint256 initialDeposit = 0.01 ether;
        // vm.deal(deployerPrivateKey, 1 ether); // Fund deployer if needed
        // saveEther.deposit{value: initialDeposit}();
        // console.log("Initial deposit made:", initialDeposit);
    }
}