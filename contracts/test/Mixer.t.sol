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
import {IncrementalMerkleTree} from "src/IncrementalMerkleTree.sol";
import {Test, console} from "forge-std/Test.sol";
import {Poseidon2, Field} from "@poseidon/src/Poseidon2.sol";
import {stdJson} from "forge-std/StdJson.sol";

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

    // function _getCommitment() public returns (bytes32 _commitment, bytes32 _nullifier, bytes32 _secret) {
    //     string[] memory inputs = new string[](3);
    //     inputs[0] = "npx";
    //     inputs[1] = "tsx";
    //     inputs[2] = "js-scripts/generateCommitment.js";
    //     // use ffi to run scripts in the CLI to create the commitment
    //     bytes memory result = vm.ffi(inputs);

    //     //ABI decode the result
    //     (_commitment, _nullifier, _secret) = abi.decode(result, (bytes32, bytes32, bytes32));
    // }

    function _getCommitment() public returns (bytes32 commitment, bytes32 nullifier, bytes32 secret) {
        string[] memory inputs = new string[](3);
        inputs[0] = "npx";
        inputs[1] = "tsx";
        inputs[2] = "js-scripts/generateCommitment.js";

        bytes memory result = vm.ffi(inputs);

        (commitment, nullifier, secret) = abi.decode(result, (bytes32, bytes32, bytes32));

        // 🔴 Poseidon2 happens HERE
        // commitment = Field.toBytes32(hasher.hash_2(Field.toField(nullifier), Field.toField(secret)));
    }

    function _getProof(bytes32 _nullifier, bytes32 _secret, address _recipient, bytes32[] memory leaves)
        public
        returns (bytes memory proof, bytes32[] memory publicInputs)
    {
        string[] memory inputs = new string[](6 + leaves.length);
        inputs[0] = "npx";
        inputs[1] = "tsx";
        inputs[2] = "js-scripts/generateProof.js";
        inputs[3] = vm.toString(_nullifier);
        inputs[4] = vm.toString(_secret);
        inputs[5] = vm.toString(bytes32(uint256(uint160(_recipient))));

        // we are rehash the nullifier here (not in the js) because poseidon2 dont have js lib

        for (uint256 i = 0; i < leaves.length; i++) {
            inputs[6 + i] = vm.toString(leaves[i]);
        }
        // use ffi to run scripts in the CLI to create the commitment
        bytes memory result = vm.ffi(inputs);

        //ABI decode the result
        (proof, publicInputs) = abi.decode(result, (bytes, bytes32[]));
    }

    function testMakeDeposit() public {
        //make commitment
        (bytes32 _commitment,,) = _getCommitment();
        console.log("Commitment : ");
        console.logBytes32(_commitment);
        // make deposit
        vm.expectEmit(true, false, false, true);
        emit Mixer.Deposit(_commitment, 0, block.timestamp);
        mixer.deposit{value: mixer.DENOMINATION()}(_commitment);
    }

    function testMakeWithdrawal() public {
        // make a deposit

        (bytes32 _commitment, bytes32 _nullifier, bytes32 _secret) = _getCommitment();

        // make deposit
        vm.expectEmit(true, false, false, true);
        emit Mixer.Deposit(_commitment, 0, block.timestamp);
        mixer.deposit{value: mixer.DENOMINATION()}(_commitment);

        bytes32[] memory leaves = new bytes32[](1);
        leaves[0] = _commitment;
        //create a proof
        (bytes memory _proof, bytes32[] memory _publicInputs) = _getProof(_nullifier, _secret, recipient, leaves);

        //make a withdrawal
        assertTrue(verifier.verify(_proof, _publicInputs));
        assertEq(recipient.balance, 0);
        assertEq(address(mixer).balance, mixer.DENOMINATION());
        mixer.withdraw(_proof, _publicInputs[0], _publicInputs[1], payable(address(uint160(uint256(_publicInputs[2])))));
        assertEq(recipient.balance, mixer.DENOMINATION());
        assertEq(address(mixer).balance, 0);
    }

    function testAnotherAddressSendProof() public {
        // make a commitment
        (bytes32 _commitment, bytes32 _nullifier, bytes32 _secret) = _getCommitment();

        // make deposit
        vm.expectEmit(true, false, false, true);
        emit Mixer.Deposit(_commitment, 0, block.timestamp);
        mixer.deposit{value: mixer.DENOMINATION()}(_commitment);

        bytes32[] memory leaves = new bytes32[](1);
        leaves[0] = _commitment;

        (bytes memory _proof, bytes32[] memory _publicInputs) = _getProof(_nullifier, _secret, recipient, leaves);
        address attacker = makeAddr("attacker");
        vm.prank(attacker);
        vm.expectRevert();
        mixer.withdraw(_proof, _publicInputs[0], _publicInputs[1], payable(attacker));
    }
}
