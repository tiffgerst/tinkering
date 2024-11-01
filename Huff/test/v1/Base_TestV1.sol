// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {HorseStore} from "../../src/horseStoreV1/HorseStore.sol";
import {Test, console2} from "forge-std/Test.sol";
import {IHorseStore} from "../../src/horseStoreV1/IHorseStore.sol";

abstract contract Base_TestV1 is Test {
    IHorseStore public horseStore;

    function setUp() public virtual {
        horseStore = IHorseStore(address(new HorseStore()));
    }

    function testReadValue() public {
        uint256 value = horseStore.readNumberOfHorses();
        assertEq(value, 0);
    }

    function testUpdateValue(uint256 numberOfHorses) public {
        horseStore.updateHorseNumber(numberOfHorses);
        uint256 value = horseStore.readNumberOfHorses();
        assertEq(value, numberOfHorses);
    }
}