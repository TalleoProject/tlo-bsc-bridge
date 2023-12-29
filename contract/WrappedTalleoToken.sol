// SPDX-License-Identifier: LGPL-2.0-or-later
pragma solidity >= 0.8.0 <0.9.0;

import "IBEP20.sol";

contract WrappedTalleoToken is IBEP20 {

string tokenName;
string tokenSymbol;
uint8 tokenDecimals;
address payable private owner;
address payable private _pendingOwner;
address payable private deployer;
uint256 tokenTotalSupply;
mapping(address => uint256) balances;
mapping(address => mapping(address => uint256)) allowed;

modifier onlyOwner() {
    require(msg.sender == owner, "Only owner can call this function.");
    _;
}

modifier onlyDeployer() {
    require(msg.sender == deployer, "Only contract deployer can call this function.");
    _;
}

constructor(string memory _name, string memory _symbol, uint8 _decimals, uint256 _totalSupply) {
    owner = payable(msg.sender);
    deployer = payable(msg.sender);
    _pendingOwner = payable(address(0));
    tokenName = _name;
    tokenSymbol = _symbol;
    tokenDecimals = _decimals;
    tokenTotalSupply = _totalSupply;
    balances[owner] = _totalSupply;
    emit Transfer(address(0), owner, _totalSupply);
    emit OwnershipTransferred(address(0), owner);
}

function getOwner() public override view returns (address) {
    return owner;
}

function pendingOwner() public view returns (address) {
    return _pendingOwner;
}

function _transferOwnership(address payable newOwner) internal {
    address payable _oldOwner = owner;
    owner = newOwner;
    emit OwnershipTransferred(_oldOwner, newOwner);
}

function transferOwnership(address payable newOwner) public onlyOwner {
    require(newOwner != owner);
    require(newOwner != address(0));
    require(newOwner != address(this));
    require(_pendingOwner == address(0));
    if (msg.sender == deployer) {
        _transferOwnership(newOwner);
    } else {
        _pendingOwner = newOwner;
        emit OwnershipTransferStarted(owner, _pendingOwner);
    }
}

function cancelOwnershipTransfer() public onlyOwner {
    require(_pendingOwner != address(0));
    _pendingOwner = payable(address(0));
}

function approveOwnershipTransfer() public onlyDeployer {
    require(_pendingOwner != address(0));
    _transferOwnership(_pendingOwner);
    _pendingOwner = payable(address(0));
}

function recoverOwnership() public onlyDeployer {
    require(owner != deployer);
    _transferOwnership(deployer);
    _pendingOwner = payable(address(0));
}

function name() public override view returns (string memory) {
    return tokenName;
}

function symbol() public override view returns (string memory) {
    return tokenSymbol;
}

function decimals() public override view returns (uint8) {
    return tokenDecimals;
}

function totalSupply() public override view returns (uint256) {
    return tokenTotalSupply;
}

function circulatingSupply() public view returns (uint256) {
    uint256 supply = tokenTotalSupply - balances[owner] - balances[address(this)] - balances[address(0)];
    if (owner != deployer) {
        supply -= balances[deployer];
    }
    return supply;
}

function balanceOf(address _owner) public override view returns (uint256) {
    return balances[_owner];
}

function _transfer(address _from, address _to, uint256 _value) internal {
    require(balances[_from] >= _value);

    balances[_from] -= _value;
    balances[_to] += _value;

    emit Transfer(_from, _to, _value);
}

function transfer(address _to, uint256 _value) public override returns (bool) {
    _transfer(msg.sender, _to, _value);
    return true;
}

function allowance(address _owner, address _spender) public override view returns (uint256) {
    return allowed[_owner][_spender];
}

function increaseAllowance(address _spender, uint256 _addedValue) public returns (bool) {
    uint256 _value = allowed[msg.sender][_spender] + _addedValue;
    _approve(msg.sender, _spender, _value);
    return true;
}

function decreaseAllowance(address _spender, uint256 _subtractedValue) public returns (bool) {
    uint256 _value = allowed[msg.sender][_spender] - _subtractedValue;
    _approve(msg.sender, _spender, _value);
    return true;
}

function _approve(address _owner, address _spender, uint256 _value) internal {
    require(_owner != address(0));
    require(_spender != address(0));
    require(balances[_owner] >= _value);

    allowed[_owner][_spender] = _value;
    emit Approval(_owner, _spender, _value);
}

function approve(address _spender, uint256 _value) public override returns (bool) {
    _approve(msg.sender, _spender, _value);
    return true;
}

function transferFrom(address _from, address _to, uint256 _value) public override returns (bool) {
    require(allowed[_from][msg.sender] >= _value);
    _transfer(_from, _to, _value);
    allowed[_from][msg.sender] -= _value;
    return true;
}

receive() external payable {
    emit Received(msg.sender, msg.value);
}

function withdrawBEP20(uint256 _value) public onlyOwner returns (bool) {
    address myAddress = address(this);
    _transfer(myAddress, msg.sender, _value);
    return true;
}

function withdrawBEP20(IBEP20 _token, uint256 _value) public onlyOwner returns (bool) {
    return _token.transfer(msg.sender, _value);
}

function withdrawBNB() public onlyOwner returns (bool) {
    require(address(this).balance > 0);
    owner.transfer(address(this).balance);
    return true;
}

function withdrawBNB(uint256 _value) public onlyOwner returns (bool) {
    require(address(this).balance >= _value);
    require(_value > 0);
    owner.transfer(_value);
    return true;
}

function sendBNB(address payable _to, uint256 _value) public onlyOwner returns (bool) {
    require(address(this).balance >= _value);
    require(_value > 0);
    _to.transfer(_value);
    return true;
}

function sendBEP20(IBEP20 _token, address _to, uint256 _value) public onlyOwner returns (bool) {
    return _token.transfer(_to, _value);
}

function convertTo(bytes memory _to, uint256 _value) public returns (bool) {
    require(_to.length == 71);
    _transfer(msg.sender, owner, _value);
    emit ConversionTo(msg.sender, _to, _value);
    return true;
}

function convertTo(address _from, bytes memory _to, uint256 _value) public onlyOwner returns (bool) {
    require(_to.length == 71);
    _transfer(_from, owner, _value);
    emit ConversionTo(_from, _to, _value);
    return true;
}

function convertFrom(bytes memory _from, address _to, uint256 _value) public onlyOwner returns (bool) {
    require(_from.length == 71);
    _transfer(owner, _to, _value);
    emit ConversionFrom(_from, _to, _value);
    return true;
}

event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);

event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

event Received(address indexed _from, uint256 _value);

event ConversionTo(address indexed _from, bytes _to, uint256 _value);

event ConversionFrom(bytes _from, address indexed _to, uint256 _value);
}
