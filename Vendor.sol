// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "./MentoraWellPlayedToken.sol";

//TODO: TRIGGER PRICE P.O.

// Learn more about the ERC20 implementation 
// on OpenZeppelin docs: https://docs.openzeppelin.com/contracts/4.x/api/access#Ownable
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

import "./Price.sol";
//TODO: Get Batch
//TODO: GET ETEPA

contract Vendor is Ownable, PriceConsumerMaticDollar, ReentrancyGuard, AccessControl {
  
  // Event that log buy operation
  event BuyTokens(address indexed buyer, uint256 indexed amountOfMatic, uint256 indexed amountOfTokens);
  event Claim(address indexed buyes, uint256 indexed ammount);
  event Ordem(uint256 _value, address _account, bytes32 _method, uint index);
  // Our Token Contract
  MentoraWellPlayedToken Mtoken;

  ////////
  int256  Price1 = 80*10**15;
  int256  Price2 = 90*10**15;
  int256  Price3 = 95*10**15;
  int256  PricePO =100*10**15;
  uint public index;
  uint256 public totalSold;


  uint256 public maxSupplyBatch1 = 2020000*10**18;
  uint256 public maxSupplyBatch2 = 4180000*10**18;
  uint256 public maxSupplyBatch3 = 6270000*10**18;
  uint256 public maxSupplyPO = 8360000*10**18;

  bytes32 public constant MATIC = keccak256("MATIC");
  bytes32 public constant PIX = keccak256("PIX");

//Set inicial false
  bool public isPO;

  struct Order {
    address account;
    uint256 value;
    bytes32 method;
  }
//total clain for address
  mapping (address => uint256) public totalValue;
//index de ordem
  mapping(uint => Order) public Orders;
//ordem dos address
  mapping(address=>uint[]) public accountOrdens;

    bytes32 public constant WITHDRAWROLE = keccak256("WITHDRAWROLE");
    bytes32 public constant BUYPIXROLE = keccak256("BUYPIXROLE");
    bytes32 public constant BUYORDERROLE = keccak256("BUYORDERROLE");

  constructor(address tokenAddress) {
    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _grantRole(WITHDRAWROLE, msg.sender);
    _grantRole(BUYPIXROLE, msg.sender);
    _grantRole(BUYORDERROLE, msg.sender);
    isPO = false;
    Mtoken = MentoraWellPlayedToken(tokenAddress);
  }


  function priceToken() public view returns (int256){
    
    if(isPO==true){
      return PricePO;
    }
    else if( maxSupplyBatch1 >=  totalSold){
      return Price1;
      }
    else if(totalSold <= (maxSupplyBatch1 + maxSupplyBatch2) && totalSold > maxSupplyBatch1){
      return Price2;
      }
    else if(totalSold <= (maxSupplyBatch1 + maxSupplyBatch2 + maxSupplyBatch3) && totalSold > (maxSupplyBatch1 + maxSupplyBatch2 ) ){
        return Price3;
      }
      else{
        return PricePO;
      }
    }

  function setPO(bool _PO) public onlyOwner{
    isPO = _PO;
  }



// Quantos token da pra comprar com 1059000000000000000 dol?
  function tokensPerMatic() public view returns (int256){
    int256 _priceToken = priceToken();
    int256 dol = getPriceMaticperDolar();
    return dol*10**18/_priceToken;
    }



//FUNÇÃO DE ATUALIZAÇÃO DA ORDEM DA COMPRA SE ELE COMPRAR POR PIX

//FUNÇÃO PARA COMPRA COM MATIC E INTERAÇÃO COM O USUARIO
  function buyTokensMatic() public payable nonReentrant returns (uint256 tokenAmount) {
    //Require para verificar se foi mandado MATIC
    require(msg.value > 0, "Send ETH to buy some tokens");
    uint _amountToBuy  = msg.value * SafeCast.toUint256(tokensPerMatic());
    uint amountToBuy = _amountToBuy/10*10**18;
    //Atualiza ordem de compra:
    OrderBuy(amountToBuy,MATIC,msg.sender);
    // EMIT the event
    emit BuyTokens(msg.sender, msg.value, amountToBuy);
    return amountToBuy;
  }

//FUNÇÃO PARA COMPRA COM PIX
//INTEGRAÇÃO MENTORA VIA API
    function BuyPix(uint256 _value, address _account) public onlyRole(BUYPIXROLE){
      OrderBuy(_value,PIX,_account);
    }

    function OrderBuy(uint256 _value, bytes32 _method, address _account) public onlyRole(BUYPIXROLE){
      Orders[index].account = _account;
      Orders[index].value = _value;
      Orders[index].method = _method;
      totalValue[_account] +=  _value;
      accountOrdens[_account].push(index);
      index++;
      totalSold += _value;
      emit Ordem( _value, _account, _method, index-1);
  }

    function getTotalValue(address _account) public view returns (uint256) {
        return totalValue[_account];
    }

    function getOrdem(uint _index) public view returns (address, bytes32,uint256){
      address account = Orders[_index].account;
      bytes32 method = Orders[_index].method;
      uint256 ammount = Orders[index].value;
      return (account, method, ammount);
    }

    function getAccountOrdens(address _account) public view returns (uint256[] memory){
      return accountOrdens[_account];
    }

    function getBalanceMPWContract() public view returns(uint256){
      uint256 vendorBalance = Mtoken.balanceOf(address(this));
      return vendorBalance;
    }

// TODO: TRAVA DE CLAIN E REENTRANCIA
// TODO: SETAR SALDO
  function claim() public nonReentrant {
    uint256 vendorBalance = Mtoken.balanceOf(address(this));
    uint256 amountToBuy = getTotalValue(msg.sender);
    require(vendorBalance >= amountToBuy, "Vendor contract has not enough tokens in its balance");
    totalValue[msg.sender] = 0;
    (bool sent) = Mtoken.transfer(msg.sender, amountToBuy);
    require(sent, "Failed to transfer token to user");
    emit Claim(msg.sender,amountToBuy);
  }
// TODO: TRAVA DE CLAIN E REENTRANCIA
// TODO: SETAR SALDO
  function claimMentora(address _account) public onlyRole(WITHDRAWROLE){
    uint256 amountToBuy = getTotalValue(_account);
    (bool sent) = Mtoken.transfer(_account, amountToBuy);
    require(sent, "Failed to transfer token to user");
    emit Claim(_account, amountToBuy);
  }

  /**
  * @notice Allow the owner of the contract to withdraw ETH
  */
  function withdraw() public onlyOwner onlyRole(WITHDRAWROLE){
    uint256 ownerBalance = address(this).balance;
    require(ownerBalance > 0, "Owner has not balance to withdraw");
    (bool sent,) = msg.sender.call{value: address(this).balance}("");
    require(sent, "Failed to send user balance back to the owner");
  }
}
