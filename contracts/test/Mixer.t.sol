// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title Mixer.t
 * @author Yabes Theodorus
 * @notice Short description of contract
 * @dev Created 2026
 */

import {Mixer} from "src/Mixer.sol";
import {HonkVerifier} from "src/Verifier.sol";
import {IncrementalMerkleTree, Poseidon2} from "src/IncrementalMerkleTree.sol";
import {Test, console} from "forge-std/Test.sol";

contract MixerTest is Test {
    Mixer public mixer;
    HonkVerifier public verifier;
    Poseidon2 public hasher;

    address public recipient = makeAddr("recipient");

    function setUp() public {
        //deploy the verifier
        verifier = new HonkVerifier();
        //deploy the hasher contract
        hasher = new Poseidon2();
        //deploy the mixer
        mixer = new Mixer(verifier, hasher, 20);
    }

    function _getCommitment() public returns (bytes32) {
        string[] memory inputs = new string[](3);
        inputs[0] = "npx";
        inputs[1] = "tsx";
        inputs[2] = "js-scripts/generateCommitment.js";
        // use ffi to run scripts in the CLI to create the commitment
        bytes memory result = vm.ffi(inputs);

        //ABI decode the result
        bytes32 _commitment = abi.decode(result, (bytes32));
        console.log("Commitment : ");
        console.logBytes32(_commitment);
        return _commitment;
    }

    function testMakeDeposit() public {
        //make commitment
        // make deposit
        bytes32 _commitment = _getCommitment();
        mixer.deposit(_commitment);
    }
}
