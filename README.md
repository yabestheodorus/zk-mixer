# Mixer Contract

A privacy-preserving ETH mixer built with Solidity using incremental Merkle trees, Poseidon hashing, and zero-knowledge proofs.

---

## Table of Contents

- [Overview](#overview)  
- [Features](#features)  
- [Installation](#installation)  
- [Usage](#usage)  
- [Smart Contract Details](#smart-contract-details)  
- [Events](#events)  
- [Errors](#errors)  
- [Testing](#testing)  
- [License](#license)  

---

## Overview

The `Mixer` contract allows users to deposit and withdraw ETH privately. It leverages:

- **Incremental Merkle Trees** to store commitments  
- **Poseidon2 hash function** for secure commitments  
- **Zero-Knowledge Proofs (ZKPs)** to verify withdrawals without revealing the underlying deposit  

This design ensures that deposited funds can be withdrawn anonymously while preventing double-spending through nullifiers.

---

## Features

- Fixed deposit denomination (`0.001 ETH`)  
- Private withdrawals via ZK proofs  
- Incremental Merkle tree for efficient proof verification  
- Nullifier tracking to prevent double withdrawals  
- Secure ETH transfers with reentrancy protection  

---

## Installation

```bash
git clone https://github.com/YabesTheodorus/mixer.git
cd mixer
forge install
npm install
```

Dependencies:

- [OpenZeppelin Contracts](https://github.com/OpenZeppelin/openzeppelin-contracts) (`ReentrancyGuard`)  
- [Poseidon2](https://github.com/YabesTheodorus/poseidon)  
- [Noir / Barretenberg](https://github.com/AztecProtocol/barretenberg) for zero-knowledge proofs  

---

## Usage

### Deposit ETH

```solidity
bytes32 commitment = /* Poseidon hash of nullifier and secret */;
mixer.deposit{value: 0.001 ether}(commitment);
```

### Withdraw ETH

```solidity
bytes calldata proof = /* generated off-chain */;
bytes32 root = /* Merkle root used in proof */;
bytes32 nullifierHash = /* nullifier hash */;
address payable recipient = msg.sender;

mixer.withdraw(proof, root, nullifierHash, recipient);
```

---

## Smart Contract Details

- **Constants**  
  - `DENOMINATION` – Fixed deposit/withdrawal amount (0.001 ETH)  

- **Mappings**  
  - `s_commitment` – Tracks if a commitment is already deposited  
  - `s_nullifierHashes` – Tracks if a nullifier has been used  

- **External Contracts**  
  - `IVerifier` – ZK proof verifier contract  
  - `Poseidon2` – Poseidon hash function  

- **Functions**  
  - `deposit(bytes32 _commitment)` – Deposit ETH with a commitment  
  - `withdraw(bytes calldata _proof, bytes32 _root, bytes32 _nullifierHash, address payable _recipient)` – Withdraw ETH privately  

---

## Events

- `Deposit(bytes32 indexed _commitment, uint32 insertedIndex, uint256 timestamp)` – Emitted on deposit  
- `Withdrawal(address indexed recipient, bytes32 nullifierHash)` – Emitted on withdrawal  

---

## Errors

- `Mixer__CommitmentAlreadyAdded(bytes32)` – Commitment already exists  
- `Mixer__DepositAmountNotCorrect(uint256, uint256)` – ETH amount does not match `DENOMINATION`  
- `Mixer__UnknownRoot(bytes32)` – Merkle root is not recognized  
- `Mixer__NullifierHasAlreadyUsed(bytes32)` – Nullifier has already been spent  
- `Mixer__InvalidProof()` – Proof verification failed  
- `Mixer__PaymentFailed(address, uint256)` – ETH transfer failed  

---

## Testing

The contract is designed to be tested with:

- [Foundry](https://github.com/foundry-rs/foundry)  
- Node.js scripts to generate proof and Merkle tree commitments  

Test workflow:

1. Generate commitments and zero-knowledge proof off-chain  
2. Deposit commitments via `deposit()`  
3. Withdraw funds with `withdraw()` using proof  

---

## License

MIT OR Apache-2.0