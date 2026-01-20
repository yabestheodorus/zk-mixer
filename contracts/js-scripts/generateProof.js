import { Barretenberg, UltraHonkBackend } from "@aztec/bb.js";
import { poseidon2HashAsync } from "@zkpassport/poseidon2"

import { ethers } from "ethers";
import { Noir } from "@noir-lang/noir_js"
import { merkleTree } from "./merkleTree";
import circuit from "../../circuits/target/circuits.json"; // ← direct import

import fs from "fs";

export default async function generateProof() {
  try {
    const noir = new Noir(circuit);
    const inputs = process.argv.slice(2);

    const recipient = inputs[2];
    const nullifier = BigInt(inputs[0]);
    const secret = BigInt(inputs[1]);
    const leaves = inputs.slice(3).map(BigInt);



    const commitment = await poseidon2HashAsync([nullifier, secret]);
    const nullifierHash = await poseidon2HashAsync([nullifier]);


    //reconstruct merkle root off-chain
    const tree = await merkleTree(leaves);
    const merkleProof = tree.proof(tree.getIndex(commitment));



    const input = {
      //public inputs
      root: merkleProof.root.toString(),
      nullifier_hash: nullifierHash.toString(),
      recipient,

      //private inputs
      nullifier: nullifier.toString(),
      secret: secret.toString(),
      merkle_proof: merkleProof.pathElements.map(i => i.toString()),
      is_even: merkleProof.pathIndices.map(i => (i % 2 === 0 ? "1" : "0"))

    };
    const { witness } = await noir.execute(input);


    const originalLog = console.log;
    console.log = () => { }

    // initialize the backend using the circuit bytecode
    const barretenbergApi = await Barretenberg.new();
    const backend = new UltraHonkBackend(circuit.bytecode, barretenbergApi);

    const { proof, publicInputs } = await backend.generateProof(witness, {
      verifierTarget: 'evm',
    });


    console.log = originalLog;

    const result = ethers.AbiCoder.defaultAbiCoder().encode(["bytes", "bytes32[]"], [proof, publicInputs]);

    // const isValid = await backend.verifyProof({ proof, publicInputs }, { keccak: true });
    // console.log(`Proof verification: ${isValid ? 'SUCCESS' : 'FAILED'}`);
    return result;
  } catch (error) {
    console.error("Error generating proof :", error);
    throw error;
  }
}


(async () => {
  generateProof().then((result) => {
    process.stdout.write(result);
    process.exit(0);
  }).catch((error) => {
    console.error(error);
    process.exit(1);
  })
})();