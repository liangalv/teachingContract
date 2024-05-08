//SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Script} from "forge-std/Script.sol";
import {TeachingContract} from "../src/TeachingContract.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployTeachingContract is Script {
    function run() external returns (TeachingContract) {
        HelperConfig helperConfig = new HelperConfig();
        vm.startBroadcast();
        //Instantiate a Teaching contract with params

        vm.stopBroadcast();
        //Return Teaching Contract
    }
}
