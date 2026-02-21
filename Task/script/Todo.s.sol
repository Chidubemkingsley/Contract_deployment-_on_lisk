// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import {Todo} from "../src/Todo.sol";

contract TodoScript is Script {
    Todo public todo;

    function setUp() public {}

    function run() public {
        // If using .env private key
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        todo = new Todo();

        vm.stopBroadcast();
    }
}