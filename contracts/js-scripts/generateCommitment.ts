import { Barretenberg } from "@aztec/bb.js";
import { ethers } from "ethers";
import crypto from "crypto";


export default async function generateCommitment(): Promise<string> {
  const bb = await Barretenberg.new();

  const randomField = BigInt(
    "0x" + crypto.randomBytes(32).toString("hex")
  );

  const randomField2 = BigInt(
    "0x" + crypto.randomBytes(32).toString("hex")
  );


  const nullifier = randomField;
  const secret = randomField2;
  const commitment = await bb.poseidon2Hash({ inputs: [nullifier, secret] });
  const result = ethers.AbiCoder.defaultAbiCoder().encode(["bytes32"], [commitment.toBuffer()]);

  return result;
}


(async () => {
  generateCommitment().then((result) => {
    process.stdout.write(result);
    process.exit(0);
  }).catch((error) => {
    console.error(error);
    process.exit(1);
  });
})();
