use poseidon::poseidon2;
mod merkle_tree;
fn main(
    //public inputs
    root: pub Field,
    nullifier_hash: pub Field,
    recipient: pub Field,
    //private inputs
    nullifier: Field,
    secret: Field,
    merkle_proof: [Field; 20],
    is_even: [bool; 20],
) {
    // compute the commitment Poseidon(nullifier, secret)
    let commitment: Field = poseidon2::Poseidon2::hash([nullifier, secret], 2);
    // check that the nullifier match nullifierhash
    let computed_nullifier_hash: Field = poseidon2::Poseidon2::hash([nullifier], 1);
    assert(computed_nullifier_hash == nullifier_hash);

    // check that the commitment is inside the merkle tree
    // (by computing root based on the commitment and merkle_proof,
    // and comparing computed root with on-chain root a.k.a public input root parameter)
    let computed_root = merkle_tree::compute_merkle_root(commitment, merkle_proof, is_even);
    assert(computed_root == root);

    let recipient_binding = recipient * recipient;
    assert(recipient_binding == recipient * recipient);
}
