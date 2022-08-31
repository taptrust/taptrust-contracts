/**
 * SPDX-License-Identifier: MIT
 *
 * Copyright (c) 2022 TAPTRUST
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */
pragma solidity ^0.8.0;

import "./IVerifiedCredentialRegistry.sol";
import "./VerifierRegistry.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "hardhat/console.sol";


/**
 * @title A modified VerifiedCredentialRegistry implementation allowing for an external verifier registry to be used.
 */

contract VerifiedCredentialRegistry is Ownable, EIP712("VerifiedCredentialRegistry", "1.0"), IVerifiedCredentialRegistry {

    address private verifierRegistryAddress;

    // All verification records keyed by their uuids
    mapping(bytes32 => VerificationRecord) private _verifications;

    // Verifications mapped to subject addresses (those who receive verifications)
    mapping(address => bytes32[]) private _verificationsForSubject;

    // Verfications issued by a given trusted verifier (those who execute verifications)
    mapping(address => bytes32[]) private _verificationsForVerifier;

    // Total verifications registered (mapping keys not being enumerable, countable, etc)
    uint256 private _verificationRecordCount;

    /*****************************/
    /* VERIFIER REGISTRY MANAGEMENT LOGIC */
    /*****************************/

    function setVerifierRegistry(address _verifierRegistryAddress) external override onlyOwner {
        verifierRegistryAddress = _verifierRegistryAddress;
    }
    
    /**********************/
    /* VERIFICATION LOGIC */
    /**********************/

    modifier onlyVerifier() {
        require(VerifierRegistry(verifierRegistryAddress).isVerifier(msg.sender), "Not a verifier");
        _;
    }

    /**
     * @inheritdoc IVerifiedCredentialRegistry
     */
    function getVerificationCount() external override view returns(uint256) {
        return _verificationRecordCount;
    }

    /**
     * @inheritdoc IVerifiedCredentialRegistry
     */
    function isVerified(address subject) external override view returns (bool) {
        require(subject != address(0), "VerifiedCredentialRegistry: Invalid address");
        bytes32[] memory subjectRecords = _verificationsForSubject[subject];
        for (uint i=0; i<subjectRecords.length; i++) {
            VerificationRecord memory record = _verifications[subjectRecords[i]];
            if (!record.revoked && record.expirationTime > block.timestamp) {
                return true;
            }
        }
        return false;
    }

    /**
     * @inheritdoc IVerifiedCredentialRegistry
     */
    function getVerification(bytes32 uuid) external override view returns (VerificationRecord memory) {
        return _verifications[uuid];
    }

    /**
     * @inheritdoc IVerifiedCredentialRegistry
     */
    function getVerificationsForSubject(address subject) external override view returns (VerificationRecord[] memory) {
        require(subject != address(0), "VerifiedCredentialRegistry: Invalid address");
        bytes32[] memory subjectRecords = _verificationsForSubject[subject];
        VerificationRecord[] memory records = new VerificationRecord[](subjectRecords.length);
        for (uint i=0; i<subjectRecords.length; i++) {
            VerificationRecord memory record = _verifications[subjectRecords[i]];
            records[i] = record;
        }
        return records;
    }

    /**
     * @inheritdoc IVerifiedCredentialRegistry
     */
    function getVerificationsForVerifier(address verifier) external override view returns (VerificationRecord[] memory) {
        require(verifier != address(0), "VerifiedCredentialRegistry: Invalid address");
        bytes32[] memory verifierRecords = _verificationsForVerifier[verifier];
        VerificationRecord[] memory records = new VerificationRecord[](verifierRecords.length);
        for (uint i=0; i<verifierRecords.length; i++) {
            VerificationRecord memory record = _verifications[verifierRecords[i]];
            records[i] = record;
        }
        return records;
    }

    /**
     * @inheritdoc IVerifiedCredentialRegistry
     */
    function revokeVerification(bytes32 uuid) external override onlyVerifier {
        require(_verifications[uuid].verifier == msg.sender, "VerifiedCredentialRegistry: Caller is not the original verifier");
        _verifications[uuid].revoked = true;
        emit VerificationRevoked(uuid);
    }

    /**
     * @inheritdoc IVerifiedCredentialRegistry
     */
    function removeVerification(bytes32 uuid) external override onlyVerifier {
        require(_verifications[uuid].verifier == msg.sender,
            "VerifiedCredentialRegistry: Caller is not the verifier of the referenced record");
        delete _verifications[uuid];
        emit VerificationRemoved(uuid);
    }

    /**
     * @inheritdoc IVerifiedCredentialRegistry
     */
    function registerVerification(
        VerificationResult memory verificationResult,
        bytes memory signature
    ) external override onlyVerifier returns (VerificationRecord memory) {
        _beforeVerificationValidation(verificationResult);
        VerificationRecord memory verificationRecord = _validateVerificationResult(verificationResult, signature);
        // commented out this requirement to allow for verifications to be relayed by a third party
        // require(
        //     verificationRecord.verifier == msg.sender,
        //     "VerifiedCredentialRegistry: Caller is not the verifier of the verification"
        // );
        _persistVerificationRecord(verificationRecord);
        emit VerificationResultConfirmed(verificationRecord);
        return verificationRecord;
    }

    /**
     * A caller may be the subject of a successful VerificationResult
     * and register that verification itself rather than rely on a verifier
     * to do so. The registry will validate the result, and if the result
     * is valid, signed by a known verifier, and the subject of the verification
     * is this caller, then the resulting VerificationRecord will be persisted and returned.
     *
     * To use this pattern, a derived contract should inherit and invoke this function,
     * otherwise the caller will not be the subject but an intermediary.
     * See ThresholdToken.sol for a simple example.
     */
    function _registerVerificationBySubject(
        VerificationResult memory verificationResult,
        bytes memory signature
    ) internal returns (VerificationRecord memory) {
        require(
            verificationResult.subject == msg.sender,
            "VerifiedCredentialRegistry: Caller is not the verified subject"
        );
        _beforeVerificationValidation(verificationResult);
        VerificationRecord memory verificationRecord = _validateVerificationResult(verificationResult, signature);
        _persistVerificationRecord(verificationRecord);
        emit VerificationResultConfirmed(verificationRecord);
        return verificationRecord;
    }

    /**
     * A subject can remove records about itself, similarly to how a verifier can
     * remove records about a subject. Nothing is truly 'deleted' from on-chain storage,
     * as the record exists in previous state, but this does prevent the record from
     * usage in the future.
     *
     * To use this pattern, a derived contract should inherit and invoke this function,
     * otherwise the caller will not be the subject but an intermediary.
     * See ThresholdToken.sol for a simple example.
     */
    function _removeVerificationBySubject(bytes32 uuid) internal {
        require(_verifications[uuid].subject == msg.sender,
            "VerifiedCredentialRegistry: Caller is not the subject of the referenced record");
        delete _verifications[uuid];
        emit VerificationRemoved(uuid);
    }

    /***********************************/
    /* VERIFICATION INTERNAL MECHANICS */
    /***********************************/

    /**
     * This hook may be overridden to enable registry-specific or credential-specific
     * filtering of a Verification Result. For example, a registry devoted to risk scoring
     * or accredited investor status may make assertions based on the result's payload
     * or on the designation of the issuer or verifier. The default behavior is a no-op,
     * no additional processing of the payload or other properties is executed.
     */
    function _beforeVerificationValidation(VerificationResult memory verificationResult) internal {
    }

    /**
     * A verifier provides a signed hash of a verification result it
     * has created for a subject address. This function recreates the hash
     * given the result artifacts and then uses it and the signature to recover
     * the public address of the signer. If that address is a trusted verifier's
     * signing address, and the assessment completes within the deadline (unix time in
     * seconds since epoch), then the verification succeeds and is valid until revocation,
     * expiration, or removal from storage.
     */
    function _validateVerificationResult(
        VerificationResult memory verificationResult,
        bytes memory signature
    ) internal view returns(VerificationRecord memory) {
        bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
          keccak256("VerificationResult(string schema,address subject,uint256 expiration)"),
          keccak256(bytes(verificationResult.schema)),
          verificationResult.subject,
          verificationResult.expiration
        )));

        // recover the public address corresponding to the signature and regenerated hash
        address signerAddress = ECDSA.recover(digest, signature);

        // retrieve a verifier address for the recovered address
        address verifierAddress = VerifierRegistry(verifierRegistryAddress).getVerifierAddressForSigner(signerAddress);
        // ensure the verifier is registered and its signer is the recovered address
        VerifierRegistry(verifierRegistryAddress).verifySigner(signerAddress);

        // ensure that the result has not expired
        require(
            verificationResult.expiration > block.timestamp,
            "VerifiedCredentialRegistry: Verification confirmation expired"
        );

        // create a VerificationRecord
        VerificationRecord memory verificationRecord = VerificationRecord({
            uuid: 0,
            verifier: verifierAddress,
            subject: verificationResult.subject,
            entryTime: block.timestamp,
            expirationTime: verificationResult.expiration,
            revoked: false
        });

        // generate a UUID for the record
        bytes32 uuid = _createVerificationRecordUUID(verificationRecord);
        verificationRecord.uuid = uuid;

        return verificationRecord;
    }

    /**
     * After validating a Verification Result and generating a Verification Record,
     * the registry increments the record count, adds the record to a map based on its uuid,
     * and associates the record's uuid with the verifier's and subject's existing record mappings.
     */
    function _persistVerificationRecord(VerificationRecord memory verificationRecord) internal {
        // persist the record count and the record itself, and map the record to verifier and subject
        _verificationRecordCount++;
        _verifications[verificationRecord.uuid] = verificationRecord;
        _verificationsForSubject[verificationRecord.subject].push(verificationRecord.uuid);
        _verificationsForVerifier[verificationRecord.verifier].push(verificationRecord.uuid);
    }

    /**
     * Generate a UUID for a VerificationRecord.
     */
    function _createVerificationRecordUUID(VerificationRecord memory verificationRecord) private view returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    verificationRecord.verifier,
                    verificationRecord.subject,
                    verificationRecord.entryTime,
                    verificationRecord.expirationTime,
                    _verificationRecordCount
                )
            );
    }


}
