// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// ── ERC20 INTERFACE ───────────────────────────────────────────────────────────

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// ── PAYMENT TOKEN ─────────────────────────────────────────────────────────────

contract PropertyToken is IERC20 {
    string public name     = "PropertyToken";
    string public symbol   = "PROP";
    uint8  public decimals = 18;

    uint256 private _totalSupply;

    mapping(address => uint256)                     private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner, "PropToken: not owner");
        _;
    }

    constructor(uint256 initialSupply) {
        owner = msg.sender;
        _mint(msg.sender, initialSupply * 10 ** decimals);
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 amount) external override returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function allowance(address _owner, address spender) external view override returns (uint256) {
        return _allowances[_owner][spender];
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external override returns (bool) {
        uint256 currentAllowance = _allowances[from][msg.sender];
        require(currentAllowance >= amount, "PropToken: insufficient allowance");
        unchecked { _allowances[from][msg.sender] = currentAllowance - amount; }
        _transfer(from, to, amount);
        return true;
    }

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    function _transfer(address from, address to, uint256 amount) internal {
        require(from != address(0), "PropToken: transfer from zero address");
        require(to   != address(0), "PropToken: transfer to zero address");
        require(_balances[from] >= amount, "PropToken: insufficient balance");
        unchecked {
            _balances[from] -= amount;
            _balances[to]   += amount;
        }
        emit Transfer(from, to, amount);
    }

    function _mint(address to, uint256 amount) internal {
        require(to != address(0), "PropToken: mint to zero address");
        _totalSupply  += amount;
        _balances[to] += amount;
        emit Transfer(address(0), to, amount);
    }

    function _approve(address _owner, address spender, uint256 amount) internal {
        require(_owner  != address(0), "PropToken: approve from zero address");
        require(spender != address(0), "PropToken: approve to zero address");
        _allowances[_owner][spender] = amount;
        emit Approval(_owner, spender, amount);
    }
}

// ── PROPERTY MANAGEMENT SYSTEM ────────────────────────────────────────────────

contract PropertyManagement {

    // ── ENUMS & STRUCTS ───────────────────────────────────────────────────────

    enum PropertyStatus { Available, Sold, Removed }

    enum PropertyType { Residential, Commercial, Industrial, Land }

    struct Property {
        uint256        id;
        string         name;
        string         location;
        string         description;
        PropertyType   propertyType;
        uint256        sizeInSqft;
        uint256        price;
        address        owner;
        PropertyStatus status;
        uint256        listedAt;
        uint256        soldAt;
        bool           exists;
    }

    // ── ROLES ─────────────────────────────────────────────────────────────────

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant AGENT_ROLE = keccak256("AGENT_ROLE");

    mapping(bytes32 => mapping(address => bool)) private _roles;

    // ── STATE VARIABLES ───────────────────────────────────────────────────────

    IERC20 public token;

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
        token = IERC20(_token);

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

    // ── PROPERTY FUNCTIONS ────────────────────────────────────────────────────

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

    function purchaseProperty(uint256 propertyId)
        external
        propertyExists(propertyId)
        propertyAvailable(propertyId)
    {
        Property storage p = _properties[propertyId];
        require(msg.sender != p.owner, "PMS: cannot buy your own listing");

        uint256 price = p.price;
        bool ok = token.transferFrom(msg.sender, address(this), price);
        require(ok, "PMS: token transfer failed");

        p.status = PropertyStatus.Sold;
        p.owner  = msg.sender;
        p.soldAt = block.timestamp;

        emit PropertyPurchased(propertyId, msg.sender, price);
    }

    // ── QUERY FUNCTIONS ───────────────────────────────────────────────────────

    function getProperty(uint256 propertyId)
        external
        view
        propertyExists(propertyId)
        returns (Property memory)
    {
        return _properties[propertyId];
    }

    function getAllProperties() external view returns (Property[] memory) {
        Property[] memory result = new Property[](_propertyIdCounter);
        for (uint256 i = 1; i <= _propertyIdCounter; i++) {
            result[i - 1] = _properties[i];
        }
        return result;
    }

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

    function totalProperties() external view returns (uint256) {
        return _propertyIdCounter;
    }

    function treasuryBalance() external view returns (uint256) {
        return token.balanceOf(address(this));
    }

    function withdrawTreasury(address to, uint256 amount) external onlyRole(ADMIN_ROLE) {
        require(to != address(0), "PMS: zero address");
        require(token.balanceOf(address(this)) >= amount, "PMS: insufficient balance");
        bool ok = token.transfer(to, amount);
        require(ok, "PMS: withdrawal failed");
    }
}