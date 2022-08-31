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

import "./IVerifierRegistry.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "hardhat/console.sol";


/**
 * @title A persistent IVerifierRegistry implementation.
 */
contract VerifierRegistry is Ownable, EIP712("VerifierRegistry", "1.0"), IVerifierRegistry {

    // VerifierInfo addresses mapped to metadata (Verifier) about the Verifiers.
    mapping(address => VerifierInfo) private _verifiers;

    // Verifier signing keys mapped to verifier addresses
    mapping(address => address) private _signers;

    // Total number of active registered verifiers
    uint256 _verifierCount;
    
    
    /*****************************/
    /* VERIFIER MANAGEMENT LOGIC */
    /*****************************/

    /**
     * @inheritdoc IVerifierRegistry
     */
    function addVerifier(address verifierAddress, VerifierInfo memory verifierInfo) external override onlyOwner {
        require(_verifiers[verifierAddress].name == 0, "VerifierRegistry: Verifier Address Exists");
        _verifiers[verifierAddress] = verifierInfo;
        
        _signers[verifierInfo.signer] = verifierAddress;
        _verifierCount++;
        emit VerifierAdded(verifierAddress, verifierInfo);
    }

    /**
     * @inheritdoc IVerifierRegistry
     */
    function isVerifier(address account) external override view returns (bool) {
        return _verifiers[account].name != 0;
    }

    /**
     * @inheritdoc IVerifierRegistry
     */
    function getVerifierCount() external override view returns(uint) {
        return _verifierCount;
    }

    /**
     * @inheritdoc IVerifierRegistry
     */
    function getVerifier(address verifierAddress) external override view returns (VerifierInfo memory) {
        require(_verifiers[verifierAddress].name != 0, "VerifierRegistry: Unknown Verifier Address");
        return _verifiers[verifierAddress];
    }

    /**
     * @inheritdoc IVerifierRegistry
     */
    function updateVerifier(address verifierAddress, VerifierInfo memory verifierInfo) external override onlyOwner {
        require(_verifiers[verifierAddress].name != 0, "VerifierRegistry: Unknown Verifier Address");
        _verifiers[verifierAddress] = verifierInfo;
        _signers[verifierInfo.signer] = verifierAddress;
        emit VerifierUpdated(verifierAddress, verifierInfo);
    }

    /**
     * @inheritdoc IVerifierRegistry
     */
    function removeVerifier(address verifierAddress) external override onlyOwner {
        require(_verifiers[verifierAddress].name != 0, "VerifierRegistry: Verifier Address Does Not Exist");
        delete _signers[_verifiers[verifierAddress].signer];
        delete _verifiers[verifierAddress];
        _verifierCount--;
        emit VerifierRemoved(verifierAddress);
    }

    /*****************************/
    /* VERIFIER HELPER FUNCTIONS */
    /*****************************/

    function getVerifierAddressForSigner(address signerAddress) external override view returns (address) {
        return _signers[signerAddress];
    }
    
    function verifySigner(address signerAddress) external override view {
        address verifierAddress = _signers[signerAddress];
        require(
            _verifiers[verifierAddress].signer == signerAddress,
            "VerifierRegistry: Signed digest cannot be verified"
        );
    }

}
