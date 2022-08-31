// This is a script for deploying your contracts. You can adapt it to deploy
// yours, or create new ones.

// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import { Contract, ContractFactory } from "ethers"
import * as hre from "hardhat"

async function main() {
  if (hre.network.name === "hardhat") {
    console.warn(
      "You are trying to deploy a contract to the Hardhat Network, which" +
        "gets automatically created and destroyed every time. Use the Hardhat" +
        " option '--network localhost'"
    )
  }

  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  // await hre.run('compile');

  const [deployer] = await hre.ethers.getSigners()
  console.log(
    "Deploying the contracts with the account:",
    await deployer.getAddress()
  )

  console.log("Account balance:", (await deployer.getBalance()).toString())

  
  // deploy VerifiedCredentialRegistry
  const verifiedCredentialRegistryFactory: ContractFactory = await hre.ethers.getContractFactory(
    "VerifiedCredentialRegistry"
  )
  const verifiedCredentialRegistryContract: Contract = await verifiedCredentialRegistryFactory.deploy()
  const registryContract = verifiedCredentialRegistryContract; // just avoiding compile error
  await verifiedCredentialRegistryContract.deployed()
  console.log("Verified Credential Registry address:", verifiedCredentialRegistryContract.address);

  // deploy VerifierRegistry
  const verifierRegistryFactory: ContractFactory = await hre.ethers.getContractFactory(
    "VerifierRegistry"
  )
  const verifierRegistryContract: Contract = await verifierRegistryFactory.deploy()
  await verifierRegistryContract.deployed()
  console.log("Verifier Registry address:", verifierRegistryContract.address);


  // deploy CredentialRequirementsRegistry
  const credentialRequirementRegistryFactory: ContractFactory = await hre.ethers.getContractFactory(
    "CredentialRequirementRegistry"
  )
  const credentialRequirementRegistryContract: Contract = await credentialRequirementRegistryFactory.deploy()
  await credentialRequirementRegistryContract.deployed()
  console.log("CredentialRequirementRegistry address:", credentialRequirementRegistryContract.address);


}

async function registerVerifications(registry: Contract, addresses: string[]) {
  const domain = {
    name: "VerifiedCredentialRegistry",
    version: "1.0",
    chainId: hre.network.config.chainId ?? 1337,
    verifyingContract: registry.address
  }

  const types = {
    VerificationResult: [
      { name: "schema", type: "string" },
      { name: "subject", type: "address" },
      { name: "expiration", type: "uint256" }
    ]
  }
  // We use a long expiration for these Verifications because we don't want
  // them to expire in the middle of the demo.
  const expiration = Math.floor(Date.now() / 1000) + 31_536_000 * 10 // 10 years

  for (const address of addresses) {
    const verificationResult = {
      schema: "centre.io/credentials/kyc",
      subject: address,
      expiration: expiration
    }

    // sign the structured result
    const [deployer] = await hre.ethers.getSigners()

    const signature = await deployer._signTypedData(
      domain,
      types,
      verificationResult
    )

    const tx = await registry.registerVerification(
      verificationResult,
      signature
    )
    await tx.wait()

    console.log(
      `Registered Verification for address: ${address}, by verifier: ${await deployer.getAddress()}`
    )
  }
}

async function createTrustedVerifier(
  verifiers: string[],
  verifiedCredentialRegistry: Contract,
  thresholdToken: Contract
) {
  for (const address of verifiers) {
    const testVerifierInfo = {
      name: hre.ethers.utils.formatBytes32String("Centre Consortium"),
      did: "did:web:centre.io",
      url: "https://centre.io/about",
      signer: address
    }

    const setThresholdVerifierTx = await thresholdToken.addVerifier(
      address,
      testVerifierInfo
    )
    await setThresholdVerifierTx.wait()

    const setRegistryVerifierTx = await verifiedCredentialRegistry.addVerifier(
      address,
      testVerifierInfo
    )
    await setRegistryVerifierTx.wait()

    console.log("Added trusted verifier:", address)
  }
}

function saveFrontendFiles(
  registryContract
) {
  const fs = require("fs")
  const contractsDir = __dirname + "/../../e2e-demo/contracts"

  if (!fs.existsSync(contractsDir)) {
    fs.mkdirSync(contractsDir)
  }

  fs.writeFileSync(
    contractsDir + "/registry-contract-address.json",
    JSON.stringify({ RegistryContract: registryContract.address }, undefined, 2)
  )
  const registryContractArtifact = hre.artifacts.readArtifactSync(
    "VerifiedCredentialRegistry"
  )
  fs.writeFileSync(
    contractsDir + "/RegistVerifiedCredentialRegistryContract.json",
    JSON.stringify(registryContractArtifact, null, 2)
  )

}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
