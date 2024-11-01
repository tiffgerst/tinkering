// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Base_TestV1, IHorseStore} from "./Base_TestV1.sol";
import {HorseStoreYul} from "../../src/horseStoreV1/HorseStoreYul.sol";

contract HorseStoreSolc is Base_TestV1 {
    function setUp() public override {
        horseStore = IHorseStore(address(new HorseStoreYul()));
    }
}