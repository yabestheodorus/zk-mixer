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
git clone https://github.com/yabestheodorus/zk-mixer.git
cd contracts
forge install
npm install