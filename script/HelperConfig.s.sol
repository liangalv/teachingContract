//SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Script} from "forge-std/Script.sol";

//Import Mocks for registrar, LINK etc
/*

*/

contract HelperConfig is Script {
    
    NetworkConfig public activeNetworkConfig;
    RegistrationParams private sep_params = new RegistrationParams{
        name: "Course Registration Upkeep",
        encryptedEmail: 0x0,
        upkeepContract: 0x0,
        gasLimit: 5000000,
        adminAddress: 0x0,
        triggerType: 0, //conditional upkeep 
        checkData: 0x0,
        triggerConfig: 0x0, //condtional upkeep
        offchainConfig: 0x0, //future param
        amount: 1000000000000000000
    };

    struct RegistrationParams {
        string name;
        bytes encryptedEmail;
        address upkeepContract;
        uint32 gasLimit;
        address adminAddress;
        uint8 triggerType;
        bytes checkData;
        bytes triggerConfig;
        bytes offchainConfig;
        uint96 amount;
    }
    
    struct NetworkConfig {
        //ChainlinkVRF
        address vrfCoordinatorAddress;
        uint64 subscriptionid;
        bytes32 gasLane;
        uint32 callbackGasLimit;
        //Automation Registrar
        RegistrationParams params;
        address linkTokenAddress;
        address registrarAddress;
    }

    constructor() {
        if (block.chainid == 11155111) {
            activeNetworkConfig = getSepoliaEthConfig();
        } else {
            activeNetworkConfig = getOrCreateAnvilEthConfig();
        }
    }

    function getSepoliaEthConfig() public pure returns (NetworkConfig memory sepoliaNetworkConfig) {
        /**
         * //ChainlinkVRF
        address vrfCoordinatorAddress;
        uint64 subscriptionid;
        bytes32 gasLane;
        uint32 callbackGasLimit;
        //Automation Registrar
        RegistrationParams params;
        address linkTokenAddress;
        address registrarAddress;
         */
        
        sepoliaNetworkConfig = NetworkConfig({
            vrfCoordinatorAddress : 0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625,
            subscriptionId : 0x0,
            
        });
    }

    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory anvilNetworkConfig) {
        // Check to see if we set an active network config
        if (activeNetworkConfig.priceFeed != address(0)) {
            return activeNetworkConfig;
        }
        vm.startBroadcast();
        MockV3Aggregator mockPriceFeed = new MockV3Aggregator(
            DECIMALS,
            INITIAL_PRICE
        );
        vm.stopBroadcast();
        emit HelperConfig__CreatedMockPriceFeed(address(mockPriceFeed));

        anvilNetworkConfig = NetworkConfig({priceFeed: address(mockPriceFeed)});
    }
}


}
