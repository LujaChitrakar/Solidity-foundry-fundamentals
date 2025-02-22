// SPDX-License-Identifier:MIT

pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";
import {SimpleStorage} from "../src/SimpleStorage.sol";

contract SimpleStorageTest is Test {
    SimpleStorage simpleStorage;
    function setUp() external {
        simpleStorage = new SimpleStorage();
    }

    function testFavoriteNumber() public {
        assertEq(simpleStorage.myFavoriteNumber(), 0);
    }
}
