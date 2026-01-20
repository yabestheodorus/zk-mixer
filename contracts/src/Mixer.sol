// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title Mixer
 * @author Yabes
 * @notice A simple ETH mixer using Merkle trees and zero-knowledge proofs for private deposits and withdrawals.
 * @dev Implements an incremental Merkle tree to store commitments, integrates a Poseidon hasher, and verifies ZK proofs via an external verifier contract.
 */

import {IncrementalMerkleTree} from "./IncrementalMerkleTree.sol";
import {IVerifier} from "./Verifier.sol";
import {Poseidon2} from "@poseidon/src/Poseidon2.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract Mixer is IncrementalMerkleTree, ReentrancyGuard {
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

    /**
     * @notice Constructor to initialize the mixer
     * @param _verifier The external zero-knowledge proof verifier contract
     * @param _hasher The Poseidon2 hasher used for the Merkle tree
     * @param _merkleTreeDepth Depth of the incremental Merkle tree
     */
    constructor(IVerifier _verifier, Poseidon2 _hasher, uint32 _merkleTreeDepth)
        IncrementalMerkleTree(_merkleTreeDepth, _hasher)
    {
        i_verifier = _verifier;
    }

    /**
     * @notice Deposit ETH into the mixer with a zero-knowledge commitment
     * @param _commitment The Poseidon hash of the nullifier and secret
     * @dev Requires msg.value to equal the fixed denomination
     *      Inserts the commitment into the on-chain incremental Merkle tree
     */
    function deposit(bytes32 _commitment) external payable nonReentrant {
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
     * @notice Withdraw ETH from the mixer privately using a zero-knowledge proof
     * @param _proof The zero-knowledge proof generated off-chain
     * @param _root The Merkle root used in the proof
     * @param _nullifierHash The nullifier hash corresponding to the deposited commitment
     * @param _recipient The recipient address for the withdrawn ETH
     * @dev Validates the root exists on-chain, the nullifier is unused, and the proof is valid.
     *      Marks the nullifier as used and transfers ETH to the recipient.
     */
    function withdraw(bytes calldata _proof, bytes32 _root, bytes32 _nullifierHash, address payable _recipient)
        external
        nonReentrant
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
