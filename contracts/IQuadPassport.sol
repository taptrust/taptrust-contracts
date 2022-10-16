//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface IQuadSoulbound  {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    function uri(uint256 _tokenId) external view returns (string memory);

    /**
     * @dev ERC1155 balanceOf implementation
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);
}

interface IQuadPassportStore {

    /// @dev Attribute store infomation as it relates to a single attribute
    /// `attrKeys` Array of keys defined by (wallet address/DID + data Type)
    /// `value` Attribute value
    /// `epoch` timestamp when the attribute has been verified by an Issuer
    /// `issuer` address of the issuer issuing the attribute
    struct Attribute {
        bytes32 value;
        uint256 epoch;
        address issuer;
    }

    /// @dev AttributeSetterConfig contains configuration for setting attributes for a Passport holder
    /// @notice This struct is used to abstract setAttributes function parameters
    /// `attrKeys` Array of keys defined by (wallet address/DID + data Type)
    /// `attrValues` Array of attributes values
    /// `attrTypes` Array of attributes types (ex: [keccak256("DID")]) used for validation
    /// `did` did of entity
    /// `tokenId` tokenId of the Passport
    /// `issuedAt` epoch when the passport has been issued by the Issuer
    /// `verifiedAt` epoch when the attribute has been attested by the Issuer
    /// `fee` Fee (in Native token) to pay the Issuer
    struct AttributeSetterConfig {
        bytes32[] attrKeys;
        bytes32[] attrValues;
        bytes32[] attrTypes;
        bytes32 did;
        uint256 tokenId;
        uint256 verifiedAt;
        uint256 issuedAt;
        uint256 fee;
    }
}

interface IQuadPassport is IQuadSoulbound {
    event GovernanceUpdated(address indexed _oldGovernance, address indexed _governance);
    event SetPendingGovernance(address indexed _pendingGovernance);
    event SetAttributeReceipt(address indexed _account, address indexed _issuer, uint256 _fee);
    event BurnPassportsIssuer(address indexed _issuer, address indexed _account);
    event WithdrawEvent(address indexed _issuer, address indexed _treasury, uint256 _fee);

    function setAttributes(
        IQuadPassportStore.AttributeSetterConfig memory _config,
        bytes calldata _sigIssuer,
        bytes calldata _sigAccount
    ) external payable;

    function setAttributesBulk(
        IQuadPassportStore.AttributeSetterConfig[] memory _configs,
        bytes[] calldata _sigIssuers,
        bytes[] calldata _sigAccounts
    ) external payable;


    function setAttributesIssuer(
        address _account,
        IQuadPassportStore.AttributeSetterConfig memory _config,
        bytes calldata _sigIssuer
    ) external payable;

    function burnPassports() external;

    function burnPassportsIssuer(address _account) external;

    function setGovernance(address _governanceContract) external;

    function acceptGovernance() external;

    function attributes(address _account, bytes32 _attribute) external view returns (IQuadPassportStore.Attribute[] memory);

    function withdraw(address payable _to, uint256 _amount) external;

    function passportPaused() external view returns(bool);

    function setTokenURI(uint256 _tokenId, string memory _uri) external;
}