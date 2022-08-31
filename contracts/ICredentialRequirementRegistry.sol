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
 * @title Interface defining basic CredentialRequirementRegistry functionality.
 */
interface ICredentialRequirementRegistry {

    /**********************/
    /* EVENT DECLARATIONS */
    /**********************/

    event VerifiedCredentialRegistryAdded(string requirementId, address registry);
    event VerifiedCredentialRegistryRemoved(string requirementId, address registry);


    /*****************************/
    /* REGISTRY MANAGEMENT LOGIC */
    /*****************************/

    /**
     * @dev The Owner adds a Registry to the contract.
     */
    function addRegistry(string memory requirementId, address registryAddress) external;

    /**
     * @dev Query whether an address is a Registry Delegate.
     */
    function hasRegistry(string memory requirementId, address account) external view returns (bool);

    /**
     * @dev Retrieve the number of Registry Delegates
     */
    function getRegistryCount(string memory requirementId) external view returns(uint);

    /**
     * @dev The owner can remove a Registry Delegate from the contract.
     */
    function removeRegistry(string memory requirementId, address registryAddress) external;

    /**********************/
    /* VERIFICATION LOGIC */
    /**********************/

    /**
     * @dev Determine whether the subject address has a verification record that is not expired
     */
    function isVerified(string memory requirementId, address subject) external view returns (bool);
}
