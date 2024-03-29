// SPDX-License-Identifier: LGPL-2.0-or-later
pragma solidity >= 0.8.0 <0.9.0;
import "IBEP20.sol";

contract TokenMarket {

address payable owner;
IBEP20 token;
uint256 public feeMultiplier;
uint256 public feeDivisor;

modifier onlyOwner() {
    require(msg.sender == owner, "Only owner can call this function.");
    _;
}

constructor(IBEP20 _token, uint256 _feeMultiplier, uint256 _feeDivisor) {
    owner = payable(msg.sender);
    token = _token;
    feeMultiplier = _feeMultiplier;
    feeDivisor = _feeDivisor;
}

function buyToken() public payable returns (bool) {
    require(msg.value > 0, "No coins received");
    uint256 firstBalance = address(this).balance + msg.value;
    uint256 secondBalance = token.balanceOf(address(this));
    uint256 toValue = msg.value * secondBalance / firstBalance;
    toValue -= toValue * feeMultiplier / feeDivisor;
    require(toValue > 0, "Not enough coins sent");
    require(toValue <= secondBalance, "Not enough tokens in the reserve");
    token.transfer(msg.sender, toValue);
    emit TokensBought(msg.sender, msg.value, toValue);
    return true;
}

function sellToken(uint256 _value) public returns (bool) {
    require(_value > 0, "No tokens received");
    uint256 firstBalance = token.balanceOf(address(this)) + _value;
    uint256 secondBalance = address(this).balance;
    uint256 toValue = _value * secondBalance / firstBalance;
    toValue -= toValue * feeMultiplier / feeDivisor;
    require(toValue > 0, "Not enough tokens sent");
    require(toValue <= secondBalance, "Not enough coins in the reserve");
    uint256 allowance = token.allowance(msg.sender, address(this));
    require(allowance >= _value, "Allowance is too low");
    token.transferFrom(msg.sender, address(this), _value);
    payable(msg.sender).transfer(toValue);
    emit TokensSold(msg.sender, _value, toValue);
    return true;
}

function addLiquidity() external payable returns (bool) {
    require(msg.value > 0, "Nothing to add");
    emit LiquidityAdded(msg.sender, msg.value);
    return true;
}

function setFee(uint256 _multiplier, uint256 _divisor) public onlyOwner returns (bool) {
    feeMultiplier = _multiplier;
    feeDivisor = _divisor;
    return true;
}

function withdrawAll() public onlyOwner returns (bool) {
    token.transfer(owner, token.balanceOf(address(this)));
    owner.transfer(address(this).balance);
    return true;
}

event TokensBought(address indexed _user, uint256 _fromValue, uint256 _toValue);

event TokensSold(address indexed _user, uint256 _fromValue, uint256 _toValue);

event LiquidityAdded(address indexed _user, uint256 _value);
}
