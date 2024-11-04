// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {BaseTest} from "../BaseTest.t.sol";
import {TryAssembly} from "../../src/TryAssembly.sol";

contract TryAssemblyTest is BaseTest {
    function setUp() public override {
        super.setUp();
        nftMarketplace = new TryAssembly();
    }
}
