# ZK Mixer Project

- Deposit: users can deposit ETH into the mixer to break the connection between depositor and withdrawer
- Withdraw: users will withdraw using a ZK proof (Noir - generated off-chain) of knowledge of their deposit.
- We will only allow users to deposit a fixed amount of ETH (0.001 ETH)

## Proof
- calculate the commitment using the secret and nullifier
- We need to check that the commitment is present in the Merkle tree
  - proposed root
  - merkle proof

  - check the nullifier matches the (public) nullifier hash

  ### Private Input
  - Secret
  - Nullifier
  - Merkle proof (intermediate nodes required to reconstrut the tree)
  - boolean to say whether node has an even index

  ### Public Input
  - Proposed root
  - nullifier hash