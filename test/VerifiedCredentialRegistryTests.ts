import { expect } from "chai"
import { Contract, Wallet } from "ethers"
import { ethers } from "hardhat"

describe("VerifiedCredentialRegistry", function () {
  // create a wallet to generate a private key for signing verification results
  const mnemonic =
    "announce room limb pattern dry unit scale effort smooth jazz weasel alcohol"
  const signer: Wallet = ethers.Wallet.fromMnemonic(mnemonic)

  // get a random subject address that will be used for verified subject tests
  let subjectAddress: string
  it("Should find a random address to use as a subject to verifiy", async function () {
    const addresses = await ethers.getSigners()
    const r = Math.floor(Math.random() * addresses.length)
    subjectAddress = await addresses[r].getAddress()
  })
  

  // deploy the contract, which makes this test provider the contract's owner
  let verificationRegistry: Contract
  let contractOwnerAddress: string
  it("Should deploy verified credential registry", async function () {
    const deployer = await ethers.getContractFactory("VerifiedCredentialRegistry")
    verificationRegistry = await deployer.deploy()
    await verificationRegistry.deployed()
    contractOwnerAddress = verificationRegistry.deployTransaction.from
  })

  

  // deploy the contract, which makes this test provider the contract's owner
  let verifierRegistry: Contract
  it("Should deploy verifier registry", async function () {
    const deployer = await ethers.getContractFactory("VerifierRegistry")
    verifierRegistry = await deployer.deploy()
    await verifierRegistry.deployed()
  })

  it("Should set verifier registry address", async function () {
    const setVerifierRegistryTx = await verificationRegistry.setVerifierRegistry(verifierRegistry.address);
    await setVerifierRegistryTx.wait();
  })


  it("Should not find a verifier for an untrusted address", async function () {
    await expect(verifierRegistry.getVerifier(contractOwnerAddress)).to.be
      .reverted
  })

  // create a test verifier
  const testVerifierInfo = {
    name: ethers.utils.formatBytes32String("Centre Consortium"),
    did: "did:web:centre.io",
    url: "https://centre.io/about",
    signer: signer.address
  }

  // make the contract's owner a verifier in the contract
  it("Should become a registered verifier", async function () {
    const setVerifierTx = await verifierRegistry.addVerifier(
      contractOwnerAddress,
      testVerifierInfo
    )
    // wait until the transaction is mined
    await setVerifierTx.wait()
  })

  it("Should ensure owner address maps to a verifier", async function () {
    const isVerifier = await verifierRegistry.isVerifier(
      contractOwnerAddress
    )
    expect(isVerifier).to.be.true
  })

  it("Should have one verifier", async function () {
    const verifierCount = await verifierRegistry.getVerifierCount()
    expect(verifierCount).to.be.equal(1)
  })

  it("Should find a verifier for owner address", async function () {
    const retrievedVerifierInfo = await verifierRegistry.getVerifier(
      contractOwnerAddress
    )
    expect(retrievedVerifierInfo.name).to.equal(testVerifierInfo.name)
    expect(retrievedVerifierInfo.did).to.equal(testVerifierInfo.did)
    expect(retrievedVerifierInfo.url).to.equal(testVerifierInfo.url)
  })

  it("Should update an existing verifier", async function () {
    testVerifierInfo.url = "https://centre.io"
    const setVerifierTx = await verifierRegistry.updateVerifier(
      contractOwnerAddress,
      testVerifierInfo
    )
    // wait until the transaction is mined
    await setVerifierTx.wait()
    const retrievedVerifierInfo = await verifierRegistry.getVerifier(
      contractOwnerAddress
    )
    expect(retrievedVerifierInfo.url).to.equal(testVerifierInfo.url)
  })

  it("Should remove a verifier", async function () {
    const removeVerifierTx = await verifierRegistry.removeVerifier(
      contractOwnerAddress
    )
    // wait until the transaction is mined
    await removeVerifierTx.wait()
    const verifierCount = await verifierRegistry.getVerifierCount()
    expect(verifierCount).to.be.equal(0)
  })

  // now register a new verifier for verification tests
  it("Should register a new verifier", async function () {
    const setVerifierTx = await verifierRegistry.addVerifier(
      contractOwnerAddress,
      testVerifierInfo
    )
    // wait until the transaction is mined
    await setVerifierTx.wait()
    const verifierCount = await verifierRegistry.getVerifierCount()
    expect(verifierCount).to.be.equal(1)
  })

  // get a deadline beyond which a test verification will expire
  // note this uses an external scanner service that is rate-throttled
  // add your own API keys to avoid the rate throttling
  // see https://docs.ethers.io/api-keys/
  let expiration = 9999999999
  it("Should create a deadline in seconds based on last block timestamp", async function () {
    const provider = ethers.getDefaultProvider()
    const lastBlockNumber: number = await provider.getBlockNumber()
    const lastBlock = await provider.getBlock(lastBlockNumber)
    expiration = lastBlock.timestamp + 300
  })

  // format an EIP712 typed data structure for the test verification result
  let domain,
    types,
    verificationResult = {}
  it("Should format a structured verification result", async function () {
    domain = {
      name: "VerifiedCredentialRegistry",
      version: "1.0",
      chainId: 1337,
      verifyingContract: await verificationRegistry.resolvedAddress
    }
    types = {
      VerificationResult: [
        { name: "schema", type: "string" },
        { name: "subject", type: "address" },
        { name: "expiration", type: "uint256" }
      ]
    }
    verificationResult = {
      schema: "centre.io/credentials/kyc",
      subject: subjectAddress,
      expiration: expiration
    }
  })

  // create a digest and sign it
  let signature: string
  it("Should sign and verify typed data", async function () {
    signature = await signer._signTypedData(domain, types, verificationResult)
    const recoveredAddress = ethers.utils.verifyTypedData(
      domain,
      types,
      verificationResult,
      signature
    )
    expect(recoveredAddress).to.equal(testVerifierInfo.signer)
  })

  // test whether a subject address has a verification and expect false
  it("Should see the subject has no registered valid verification record", async function () {
    const isVerified = await verificationRegistry.isVerified(
      contractOwnerAddress
    )
    expect(isVerified).to.be.false
  })

  // execute the contract's proof of the verification
  it("Should register the subject as verified and create a Verification Record", async function () {
    const verificationTx = await verificationRegistry.registerVerification(
      verificationResult,
      signature
    )
    await verificationTx.wait()
    const verificationCount = await verificationRegistry.getVerificationCount()
    expect(verificationCount).to.be.equal(1)
  })


  // test whether a subject address has a verification
  it("Should verify the subject has a registered and valid verification record", async function () {
    const isVerified = await verificationRegistry.isVerified(subjectAddress)
    expect(isVerified).to.be.true
  })

  let recordUUID = 0

  // get all verifications for a subject
  it("Get all verifications for a subject address", async function () {
    const records = await verificationRegistry.getVerificationsForSubject(
      subjectAddress
    )
    recordUUID = records[0]?.uuid
    expect(recordUUID);
    expect(records.length).to.equal(1)
  })

  // get all verifications for a verifier
  it("Get all verifications for a verifier address", async function () {
    const records = await verificationRegistry.getVerificationsForVerifier(
      contractOwnerAddress
    )
    expect(records[0]?.uuid)
    expect(records[0]?.uuid).to.equal(recordUUID)
    expect(records.length).to.equal(1)
  })

  // get a specific verification record by its uuid
  it("Get a verification using its uuid", async function () {
    if (!recordUUID) { return; }
    const record = await verificationRegistry.getVerification(recordUUID)
    expect(ethers.utils.getAddress(record.subject)).not.to.throw
  })

  // deploy the contract, which makes this test provider the contract's owner
  let credentialRequirementRegistry: Contract
  const requirementId = 'kyc';
  it("Should deploy credential requirement registry", async function () {
    const deployer = await ethers.getContractFactory("CredentialRequirementRegistry")
    credentialRequirementRegistry = await deployer.deploy()
    await credentialRequirementRegistry.deployed()
  })

  // test whether a subject address has a verification and expect false
  it("Should see the subject has no registered valid verification record", async function () {
    const isVerified = await credentialRequirementRegistry.isVerified(
        requirementId,
        subjectAddress
    )
    expect(isVerified).to.be.false
  })

  it("Should add verification requirement registry to credential requirement registry", async function () {
    const verificationTx = await credentialRequirementRegistry.addRegistry(
      requirementId,
      verificationRegistry.resolvedAddress
      )
    await verificationTx.wait()
  })

  it("Should show the verification registry is registered", async function () {
    const hasRegistry = await credentialRequirementRegistry.hasRegistry(requirementId, verificationRegistry.resolvedAddress)
    expect(hasRegistry).to.be.true
    const registryCount = await credentialRequirementRegistry.getRegistryCount(requirementId)
    expect(registryCount).to.be.equal(1)
  })

  // test whether a subject address has a verification and expect true
  it("Should see the subject has a registered valid verification record", async function () {
    const isVerified = await credentialRequirementRegistry.isVerified(
      requirementId,
      subjectAddress
    )
    expect(isVerified).to.be.true
  })

  it("Should remove verification requirement registry to credential requirement registry", async function () {
    const verificationTx = await credentialRequirementRegistry.removeRegistry(
      requirementId,
      verificationRegistry.resolvedAddress
      )
    await verificationTx.wait()
  })

  it("Should show the verification registry is not registered", async function () {
    const hasRegistry = await credentialRequirementRegistry.hasRegistry(requirementId, verificationRegistry.resolvedAddress)
    expect(hasRegistry).to.be.false
    const registryCount = await credentialRequirementRegistry.getRegistryCount(requirementId)
    expect(registryCount).to.be.equal(0)
  })

  it("Should see the subject has no registered valid verification record", async function () {
    const isVerified = await credentialRequirementRegistry.isVerified(
      requirementId,
      subjectAddress
    )
    expect(isVerified).to.be.false
  })
      
  // a subject can remove verifications about itself -- note nothing on chains is really ever removed
  it("Should remove a verification", async function () {
    let record = await verificationRegistry.getVerification(recordUUID)
    expect(ethers.utils.getAddress(record.subject)).not.to.throw
    const removeTx = await verificationRegistry.removeVerification(recordUUID)
    removeTx.wait()
    record = await verificationRegistry.getVerification(recordUUID)
    expect(ethers.utils.getAddress(record.subject)).to.throw
  })

})
