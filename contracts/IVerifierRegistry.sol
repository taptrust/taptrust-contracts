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

/**
* @dev Info about Verifiers
*/
struct VerifierInfo {
    bytes32 name;
    string did;
    string url;
    address signer;
}


/**
 * @title Interface defining basic VerifierRegistry functionality.
 */
interface IVerifierRegistry {

    /**********************/
    /* EVENT DECLARATIONS */
    /**********************/

    event VerifierAdded(address verifier, VerifierInfo verifierInfo);
    event VerifierUpdated(address verifier, VerifierInfo verifierInfo);
    event VerifierRemoved(address verifier);


    /*****************************/
    /* VERIFIER MANAGEMENT LOGIC */
    /*****************************/

    /**
     * @dev The Owner adds a Verifier Delegate to the contract.
     */
    function addVerifier(address verifierAddress, VerifierInfo memory verifierInfo) external;

    /**
     * @dev Query whether an address is a Verifier Delegate.
     */
    function isVerifier(address account) external view returns (bool);

    /**
     * @dev Retrieve the number of registered Verifier Delegates
     */
    function getVerifierCount() external view returns(uint);

    /**
     * @dev Request information about a Verifier based on its signing address.
     */
    function getVerifier(address verifierAddress) external view returns (VerifierInfo memory);

    /**
     * @dev The owner updates an existing Verifier Delegate's did, URL, and name.
     */
    function updateVerifier(address verifierAddress, VerifierInfo memory verifierInfo) external;

    /**
     * @dev The owner can remove a Verifier Delegate from the contract.
     */
    function removeVerifier(address verifierAddress) external;

    /**
     * @dev Verify signer address corresponds to a valid Verifier Delegate.
     */
    function verifySigner(address signerAddress) external view;

    /**
     * @dev Ger verifier address corresponding to signer address
     */
    function getVerifierAddressForSigner(address signerAddress) external returns (address);
}
