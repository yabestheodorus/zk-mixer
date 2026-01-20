// import crypto from "crypto";
// import { buildPoseidon } from "circomlibjs";
// import { AbiCoder } from "ethers";
// import { zeroPadValue, toBeHex } from "ethers";

// const FIELD_SIZE =
//   BigInt(
//     "21888242871839275222246405745257275088548364400416034343698204186575808495617"
//   );
// function toBytes32(x) {
//   return zeroPadValue(toBeHex(x), 32);
// }

// function randomField() {
//   let x;
//   do {
//     x = BigInt("0x" + crypto.randomBytes(32).toString("hex"));
//   } while (x >= FIELD_SIZE);
//   return x;
// }

// const poseidon = await buildPoseidon();
// const coder = AbiCoder.defaultAbiCoder();

// const nullifier = randomField();
// const secret = randomField();

// const commitment = poseidon.F.toObject(
//   poseidon([nullifier, secret])
// );

// // ABI-encode EVERYTHING
// const encoded = coder.encode(
//   ["bytes32", "bytes32", "bytes32"],
//   [toBytes32(commitment), toBytes32(nullifier), toBytes32(secret)]
// );
// // stdout must be ONE thing
// console.log(encoded);



import crypto from "crypto";
import { AbiCoder, zeroPadValue, toBeHex } from "ethers";
import { poseidon2HashAsync } from "@zkpassport/poseidon2"

const FIELD_SIZE =
  BigInt("21888242871839275222246405745257275088548364400416034343698204186575808495617");

function randomField() {
  let x;
  do {
    x = BigInt("0x" + crypto.randomBytes(32).toString("hex"));
  } while (x >= FIELD_SIZE);
  return x;
}

function toBytes32(x) {
  return zeroPadValue(toBeHex(x), 32);
}

const nullifier = randomField();
const secret = randomField();

const coder = AbiCoder.defaultAbiCoder();
const commitment = await poseidon2HashAsync([nullifier, secret]);
// ONLY encode nullifier + secret
const encoded = coder.encode(
  ["bytes32", "bytes32", "bytes32"],
  [toBytes32(commitment), toBytes32(nullifier), toBytes32(secret)]
);

console.log(encoded);
