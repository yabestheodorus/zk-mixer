// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title Mixer
 * @author Yabes Theodorus
 * @notice Short description of contract
 * @dev Created 2026
 */

import {IncrementalMerkleTree} from "./IncrementalMerkleTree.sol";
import {IVerifier} from "./Verifier.sol";
import {Poseidon2} from "@poseidon/src/Poseidon2.sol";

contract Mixer is IncrementalMerkleTree {
    error Mixer__CommitmentAlreadyAdded(bytes32 commitment);
    error Mixer__DepositAmountNotCorrect(uint256 amount, uint256 expectedAmount);
    error Mixer__UnknownRoot(bytes32 root);
    error Mixer__NullifierHasAlreadyUsed(bytes32 nullifierHash);
    error Mixer__InvalidProof();
    error Mixer__PaymentFailed(address recipient, uint256 amount);

    IVerifier public immutable i_verifier;
    mapping(bytes32 commitment => bool isUsed) private s_commitment;
    mapping(bytes32 => bool) s_nullifierHashes;
    uint256 public constant DENOMINATION = 0.001 ether;

    event Deposit(bytes32 indexed _commitment, uint32 insertedIndex, uint256 timestamp);
    event Withdrawal(address indexed recipient, bytes32 nullifierHash);

    constructor(IVerifier _verifier, Poseidon2 _hasher, uint8 _merkleTreeDepth)
        IncrementalMerkleTree(_merkleTreeDepth, _hasher)
    {
        i_verifier = _verifier;
    }

    /**
     * @notice Deposit funds into the mixer
     * @param _commitment the poseidon commitment of the nullifier and secret (generated off-chain)
     */
    function deposit(bytes32 _commitment) external payable {
        // check whether the commitment has already been used so we can prevent a deposit to being added twice
        if (s_commitment[_commitment]) {
            revert Mixer__CommitmentAlreadyAdded(_commitment);
        }

        // allow the user to send ETH and make sure it is of the correct fixed amount (denomination)
        if (msg.value != DENOMINATION) {
            revert Mixer__DepositAmountNotCorrect(msg.value, DENOMINATION);
        }
        // add the commitment to the onchain incremental merkle tree containing all the commitments
        uint32 insertedIndex = _insert(_commitment);

        s_commitment[_commitment] = true;

        emit Deposit(_commitment, insertedIndex, block.timestamp);
    }

    /**
     * @notice Withdraw funds from te mixer in a private way
     * @param _proof the proof that user has the right to withdraw (they know a valid commitment)
     */
    function withdraw(bytes calldata _proof, bytes32 _root, bytes32 _nullifierHash, address payable _recipient)
        external
    {
        // check that the root that was used in the proof matches the root on-chain
        if (!isKnownRoot(_root)) {
            revert Mixer__UnknownRoot(_root);
        }
        // check that the nullifier hasn't been used yet before
        if (s_nullifierHashes[_nullifierHash]) {
            revert Mixer__NullifierHasAlreadyUsed(_nullifierHash);
        }
        // check that the proof is valid by calling verifier contract
        bytes32[] memory publicInputs = new bytes32[](3);
        publicInputs[0] = _root;
        publicInputs[1] = _nullifierHash;
        publicInputs[2] = bytes32(uint256(uint160(address(_recipient))));

        if (!i_verifier.verify(_proof, publicInputs)) {
            revert Mixer__InvalidProof();
        }
        s_nullifierHashes[_nullifierHash] = true;
        // send them the funds
        (bool success,) = _recipient.call{value: DENOMINATION}("");
        if (!success) {
            revert Mixer__PaymentFailed(_recipient, DENOMINATION);
        }

        emit Withdrawal(_recipient, _nullifierHash);
    }
}
