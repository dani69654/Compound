pragma solidity ^0.6.0;

//0x6B175474E89094C44Da98b954EedeAC495271d0F DAI
abstract contract Erc20 {
  function approve(address, uint)virtual external returns (bool);
  function transfer(address, uint)virtual external returns (bool);
  function balanceOf(address owner)virtual external view returns (uint256 balance);
}

//0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643 cDai
abstract contract CErc20 {
  function approve(address, uint)virtual external returns (bool);
  function mint(uint)virtual external returns (uint);
  function balanceOfUnderlying(address account)virtual external returns (uint);
  function totalReserves()virtual external returns (uint);
  function transfer(address dst, uint amount) virtual external returns (bool);
}

//0x4ddc2d193948926d02f9b1fe9e1daa0718270ed5
abstract contract CEth {
  function mint()virtual external payable;
  function balanceOfUnderlying(address account)virtual external returns (uint);
  function balanceOf(address owner)virtual external view returns (uint256 balance);
  function transfer(address dst, uint256 amount)virtual external returns (bool success);
  function transferFrom(address src, address dst, uint wad)virtual external returns (bool);
  function redeem(uint redeemTokens) virtual external returns (uint);
}


import "./IERC20.sol";
import './ComptrollerInterface.sol';
import './CTokenInterface.sol';
import "./Ownable.sol";

contract MyContract is Ownable{

  address public daiContractAddress;
  address public cDaiContractAddress;
  address public cEthContractAddress;

  event isApproved(bool);

  constructor (address _daiContractAddress, address _cDaiContractAddress, address _cEthContractAddress) public {
    daiContractAddress = _daiContractAddress;
    cDaiContractAddress = _cDaiContractAddress;
    cEthContractAddress = _cEthContractAddress;
  }

  function supplyEthToCompound() public payable returns (bool){
    CEth(cEthContractAddress).mint.value(msg.value).gas(20000000000)();
    return true;
  }

  function supplyErc20ToCompound(uint256 _numTokensToSupply) public returns (uint256){
    // Create a reference to the underlying asset contract, like DAI.
    Erc20 underlying = Erc20(daiContractAddress);
    // Create a reference to the corresponding cToken contract, like cDAI
    CErc20 cToken = CErc20(cDaiContractAddress);
    // Approve transfer on the ERC20 contract
    underlying.approve(cDaiContractAddress, _numTokensToSupply);
    // Mint cTokens
    uint mintResult = cToken.mint(_numTokensToSupply);
    require (mintResult == 0, "Mint failed");
    return mintResult;
  }

  function redeemCtokens(uint _amount, address _cTokenAddress) public returns (uint256){
    // Redeem a cToken
    uint redeemResult = CEth(_cTokenAddress).redeem(_amount);
    require(redeemResult == 0, "Redeem failed");
    return redeemResult;
  }

  function getReserve(address _cErc20Contract) public returns (uint256){
    // Reserves are an accounting entry in each cToken contract that represents
    // a portion of historical interest set aside as cash
    CErc20 cToken = CErc20(_cErc20Contract);
    return cToken.totalReserves();
  }

  function getCErc20Balance(address payable _cErc20Contract, address _myaddr) public returns(uint256) {
    // Returns cDai balance of _myaddr
    return CErc20(_cErc20Contract).balanceOfUnderlying(_myaddr);
  }

  function getDaiBalance(address payable _erc20Contract, address _myaddr) public view returns(uint256){
    // Returns Dai balance of _myaddr
    return Erc20(_erc20Contract).balanceOf(_myaddr);
  }

  function getCEthBalance(address payable _cEtherContract, address _myaddr) public view returns(uint256){
    // Returns Ceth balance of _myaddr
    return CEth(_cEtherContract).balanceOf(_myaddr);
  }

  function sendCEthToWallet(address payable _cEtherContract, address payable _dst, uint256 total) public returns(bool){
    // Send cEth from contract to  _dst
    return CEth(_cEtherContract).transferFrom(address(this), _dst ,total);
  }

  function setDAIcontractAddress (address _newDAIaddress) public onlyOwner returns (address){
    daiContractAddress = _newDAIaddress;
    return daiContractAddress;
  }

  function setCDAIcontractAddress (address _newCDAIaddress) public onlyOwner returns (address){
    cDaiContractAddress = _newCDAIaddress;
    return cDaiContractAddress;
  }

  function setCETHcontractAddress (address _newCETHaddress) public onlyOwner returns (address){
    cEthContractAddress = _newCETHaddress;
    return cEthContractAddress;
  }
  receive() external payable { }
}
