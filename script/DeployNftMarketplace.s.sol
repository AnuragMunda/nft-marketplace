// SPDF-License-Identifier: MIT

pragma solidity 0.8.27;

import {Script} from "forge-std/Script.sol";
import {NftMarketplace} from "../src/NftMarketplace.sol";

contract DeployNftMarketplace is Script {
    function run() external returns (NftMarketplace) {
        vm.startBroadcast();
        NftMarketplace nftMarketplace = new NftMarketplace();
        vm.stopBroadcast();
        return nftMarketplace;
    }
}