// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

// ── PAYMENT TOKEN ─────────────────────────────────────────────────────────────

contract PropertyToken is ERC20, ERC20Burnable {
    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner, "PropToken: not owner");
        _;
    }

    constructor(uint256 initialSupply) ERC20("PropertyToken", "PROP") {
        owner = msg.sender;
        _mint(msg.sender, initialSupply * 10 ** decimals());
    }

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }
}

// ── PROPERTY MANAGEMENT SYSTEM ────────────────────────────────────────────────

contract PropertyManagement {

    // ── ENUMS & STRUCTS ───────────────────────────────────────────────────────

    enum PropertyStatus { Available, Sold, Removed }

    enum PropertyType { Residential, Commercial, Industrial, Land }

    struct Property {
        uint256       id;
        string        name;
        string        location;
        string        description;
        PropertyType  propertyType;
        uint256       sizeInSqft;
        uint256       price;          // in PROP token wei units
        address       owner;          // current owner
        PropertyStatus status;
        uint256       listedAt;
        uint256       soldAt;         // 0 if not sold
        bool          exists;
    }

    // ── ROLES ─────────────────────────────────────────────────────────────────

    bytes32 public constant ADMIN_ROLE  = keccak256("ADMIN_ROLE");
    bytes32 public constant AGENT_ROLE  = keccak256("AGENT_ROLE");

    mapping(bytes32 => mapping(address => bool)) private _roles;

    // ── STATE VARIABLES ───────────────────────────────────────────────────────

    PropertyToken public token;

    uint256 private _propertyIdCounter;
    mapping(uint256 => Property) private _properties;

    // ── EVENTS ────────────────────────────────────────────────────────────────

    event PropertyCreated(uint256 indexed id, string name, string location, uint256 price, address indexed listedBy);
    event PropertyRemoved(uint256 indexed id, string name);
    event PropertyPurchased(uint256 indexed id, address indexed buyer, uint256 price);
    event PropertyPriceUpdated(uint256 indexed id, uint256 oldPrice, uint256 newPrice);
    event RoleGranted(bytes32 indexed role, address indexed account);
    event RoleRevoked(bytes32 indexed role, address indexed account);

    // ── MODIFIERS ─────────────────────────────────────────────────────────────

    modifier onlyRole(bytes32 role) {
        require(_roles[role][msg.sender], "PMS: access denied");
        _;
    }

    modifier onlyAdminOrAgent() {
        require(
            _roles[ADMIN_ROLE][msg.sender] || _roles[AGENT_ROLE][msg.sender],
            "PMS: not admin or agent"
        );
        _;
    }

    modifier propertyExists(uint256 propertyId) {
        require(_properties[propertyId].exists, "PMS: property not found");
        _;
    }

    modifier propertyAvailable(uint256 propertyId) {
        require(
            _properties[propertyId].status == PropertyStatus.Available,
            "PMS: property not available"
        );
        _;
    }

    // ── CONSTRUCTOR ───────────────────────────────────────────────────────────

    constructor(address _token) {
        require(_token != address(0), "PMS: zero token address");
        token = PropertyToken(_token);

        // Grant deployer admin role
        _roles[ADMIN_ROLE][msg.sender] = true;
        emit RoleGranted(ADMIN_ROLE, msg.sender);
    }

    // ── ROLE MANAGEMENT ───────────────────────────────────────────────────────

    function grantRole(bytes32 role, address account) external onlyRole(ADMIN_ROLE) {
        require(account != address(0), "PMS: zero address");
        _roles[role][account] = true;
        emit RoleGranted(role, account);
    }

    function revokeRole(bytes32 role, address account) external onlyRole(ADMIN_ROLE) {
        _roles[role][account] = false;
        emit RoleRevoked(role, account);
    }

    function hasRole(bytes32 role, address account) external view returns (bool) {
        return _roles[role][account];
    }

    // ── PROPERTY MANAGEMENT ───────────────────────────────────────────────────

    /**
     * @notice Create a new property listing (admin or agent only)
     * @param name         Property name/title
     * @param location     Physical address or location description
     * @param description  Detailed description of the property
     * @param propertyType Type: Residential, Commercial, Industrial, Land
     * @param sizeInSqft   Size in square feet
     * @param price        Sale price in PROP token wei units
     */
    function createProperty(
        string       calldata name,
        string       calldata location,
        string       calldata description,
        PropertyType propertyType,
        uint256      sizeInSqft,
        uint256      price
    ) external onlyAdminOrAgent returns (uint256 propertyId) {
        require(bytes(name).length     > 0, "PMS: name required");
        require(bytes(location).length > 0, "PMS: location required");
        require(sizeInSqft             > 0, "PMS: size must be > 0");
        require(price                  > 0, "PMS: price must be > 0");

        _propertyIdCounter++;
        propertyId = _propertyIdCounter;

        _properties[propertyId] = Property({
            id:           propertyId,
            name:         name,
            location:     location,
            description:  description,
            propertyType: propertyType,
            sizeInSqft:   sizeInSqft,
            price:        price,
            owner:        msg.sender,
            status:       PropertyStatus.Available,
            listedAt:     block.timestamp,
            soldAt:       0,
            exists:       true
        });

        emit PropertyCreated(propertyId, name, location, price, msg.sender);
    }

    /**
     * @notice Remove a property listing (admin only)
     * @param propertyId  ID of the property to remove
     */
    function removeProperty(uint256 propertyId)
        external
        onlyRole(ADMIN_ROLE)
        propertyExists(propertyId)
        propertyAvailable(propertyId)
    {
        Property storage p = _properties[propertyId];
        p.status = PropertyStatus.Removed;
        emit PropertyRemoved(propertyId, p.name);
    }

    /**
     * @notice Update the price of a listed property (admin or agent only)
     * @param propertyId  ID of the property
     * @param newPrice    New price in PROP token wei units
     */
    function updatePrice(uint256 propertyId, uint256 newPrice)
        external
        onlyAdminOrAgent
        propertyExists(propertyId)
        propertyAvailable(propertyId)
    {
        require(newPrice > 0, "PMS: price must be > 0");
        Property storage p = _properties[propertyId];
        uint256 oldPrice = p.price;
        p.price = newPrice;
        emit PropertyPriceUpdated(propertyId, oldPrice, newPrice);
    }

    /**
     * @notice Purchase a property. Buyer must approve this contract first.
     * @param propertyId  ID of the property to buy
     */
    function purchaseProperty(uint256 propertyId)
        external
        propertyExists(propertyId)
        propertyAvailable(propertyId)
    {
        Property storage p = _properties[propertyId];
        require(msg.sender != p.owner, "PMS: cannot buy your own listing");

        uint256 price = p.price;

        // Transfer PROP tokens from buyer to contract (treasury)
        bool ok = token.transferFrom(msg.sender, address(this), price);
        require(ok, "PMS: token transfer failed");

        p.status  = PropertyStatus.Sold;
        p.owner   = msg.sender;
        p.soldAt  = block.timestamp;

        emit PropertyPurchased(propertyId, msg.sender, price);
    }

    // ── QUERY FUNCTIONS ───────────────────────────────────────────────────────

    /// @notice Get a single property by ID
    function getProperty(uint256 propertyId)
        external
        view
        propertyExists(propertyId)
        returns (Property memory)
    {
        return _properties[propertyId];
    }

    /// @notice Get all properties (available, sold, and removed)
    function getAllProperties() external view returns (Property[] memory) {
        Property[] memory result = new Property[](_propertyIdCounter);
        for (uint256 i = 1; i <= _propertyIdCounter; i++) {
            result[i - 1] = _properties[i];
        }
        return result;
    }

    /// @notice Get only available properties
    function getAvailableProperties() external view returns (Property[] memory) {
        uint256 count;
        for (uint256 i = 1; i <= _propertyIdCounter; i++) {
            if (_properties[i].status == PropertyStatus.Available) count++;
        }
        Property[] memory result = new Property[](count);
        uint256 idx;
        for (uint256 i = 1; i <= _propertyIdCounter; i++) {
            if (_properties[i].status == PropertyStatus.Available) {
                result[idx++] = _properties[i];
            }
        }
        return result;
    }

    /// @notice Total number of properties ever listed
    function totalProperties() external view returns (uint256) {
        return _propertyIdCounter;
    }

    /// @notice Treasury balance (PROP tokens collected from sales)
    function treasuryBalance() external view returns (uint256) {
        return token.balanceOf(address(this));
    }

    /// @notice Withdraw treasury funds to a recipient (admin only)
    function withdrawTreasury(address to, uint256 amount)
        external
        onlyRole(ADMIN_ROLE)
    {
        require(to != address(0), "PMS: zero address");
        require(token.balanceOf(address(this)) >= amount, "PMS: insufficient balance");
        bool ok = token.transfer(to, amount);
        require(ok, "PMS: withdrawal failed");
    }
}