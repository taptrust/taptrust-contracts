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

import "./ICredentialRequirementRegistry.sol";
import "./VerifiedCredentialRegistry.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "hardhat/console.sol";


/**
 * @title A persistent ICredentialRequirementRegistry implementation.
 */
contract CredentialRequirementRegistry is Ownable, EIP712("CredentialRequirementRegistry", "1.0"), ICredentialRequirementRegistry {

    // Verifications mapped to subject addresses (those who receive verifications)
    mapping(string => address[]) private _verificationRegistries;
    mapping(string => address) private _NFTRegistry;
    mapping(address => uint256[]) public _tokenIDRegistries;

    
    /*****************************/
    /* VERIFIER MANAGEMENT LOGIC */
    /*****************************/

    /**
     * @inheritdoc ICredentialRequirementRegistry
     */
    function addRegistry(string memory requirementId, address registryAddress) external override onlyOwner {
        _verificationRegistries[requirementId].push(registryAddress);
        emit VerifiedCredentialRegistryAdded(requirementId, registryAddress);
    }

    function addNFTRegistry(string memory requirementId, address nftregistryAddress, uint256 tokenID) external override onlyOwner {
        _NFTRegistry[requirementId] = nftregistryAddress;
        _tokenIDRegistries[nftregistryAddress].push(tokenID);
    }

    /**
     * @inheritdoc ICredentialRequirementRegistry
     */
    function hasRegistry(string memory requirementId, address registryAddress) external override view returns (bool) {
        for (uint i=0; i<_verificationRegistries[requirementId].length; i++) {
            address _registryAddress = _verificationRegistries[requirementId][i]; 
            if (_registryAddress == registryAddress) {
                return true;
            }
        }
        return false;
    }

    /**
     * @inheritdoc ICredentialRequirementRegistry
     */
    function getRegistryCount(string memory requirementId) external override view returns(uint) {
        return _verificationRegistries[requirementId].length;
    }

    function _findRegistryIndex(string memory requirementId, address account) private view returns(uint) {
        uint i = 0;
        while (_verificationRegistries[requirementId][i] != account) {
            i++;
        }
        return i;
    }

    function _removeRegistryByIndex(string memory requirementId, uint i) private {
        while (i<_verificationRegistries[requirementId].length-1) {
            _verificationRegistries[requirementId][i] = _verificationRegistries[requirementId][i+1];
            i++;
        }
        _verificationRegistries[requirementId].pop();
    }

    /**
     * @inheritdoc ICredentialRequirementRegistry
     */
    function removeRegistry(string memory requirementId, address registryAddress) external override onlyOwner {
        uint index = _findRegistryIndex(requirementId, registryAddress);
        _removeRegistryByIndex(requirementId, index);
        emit VerifiedCredentialRegistryRemoved(requirementId, registryAddress);
    }

    /*****************************/
    /* VERIFIER HELPER FUNCTIONS */
    /*****************************/

    /**
     * @inheritdoc ICredentialRequirementRegistry
     */
    function isVerified(string memory requirementId, address subject) external override view returns (bool) {
        for (uint i=0; i<_verificationRegistries[requirementId].length; i++) {
            address _registryAddress = _verificationRegistries[requirementId][i];
            address nftaddress = _NFTRegistry[requirementId];
            for(uint j=0; j<_tokenIDRegistries[nftaddress].length; j++){
                uint256 ID = _tokenIDRegistries[nftaddress][j];
                if (VerifiedCredentialRegistry(_registryAddress).balanceOf(nftaddress, subject, ID)) {
                    return true;
                }
            }
        }
        return false;
    }
    

}
