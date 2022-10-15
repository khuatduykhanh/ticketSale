//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.12;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

interface MintToken {
        function issueToken(address receiver, uint256 amount) external;
}

contract TicketSale is Ownable,ERC721 {
    
    using Counters for Counters.Counter;
    Counters.Counter private _eventID;

    struct OrganizationalUintInfo {
        string  companyName;
        string  location;
        string hostline;
        string Code;
        bool check;

    }
    enum ticketType { 
        footballTickets,
        movieTickets,
        concertTickets
    }

    struct InfoTicketSale {
        uint256 saleStartTime;
        uint256 saleEndTime;
        uint256 numberOfTicketsSale;
        uint256 numberOfTicketsSold;
        uint256 maxBuy;
    }
    struct DetailTicket {
        string name;
        string venue;
        string describeDetail;
        string[] seat;
        uint256[] price;
        ticketType choice;

    }
    struct InfoSaleTicket {
        uint256 price;
        uint256 timeStart;
        uint256 timeEnd;
        string name;
        string venue;
        string describeDetail;
        string seat;
        ticketType choice;
    }

    address public fundWallet;
    mapping (uint256 => address ) public eventToOwner;
    mapping (address => uint256 ) ownerEventCount;
    mapping (address => OrganizationalUintInfo ) public infoSeller;
    mapping (address => mapping (uint256 => uint256)) listEventIDToCompany;
    mapping (uint256 => InfoTicketSale) public infoEventTicket;
    mapping (uint256 => DetailTicket) infoDetailTicket;
    mapping (uint256 => mapping(string => uint256 )) priceBySeat;
    mapping (uint256 => uint256 ) ticketByEvent;
    mapping (uint256 => InfoSaleTicket) saleTicketByID;
    mapping (uint256 => string ) ticketIdToSeat;
    mapping (uint256 => mapping(uint256 => uint256)) arrayTicketRemaining;
    event CreateInfoCompany(address _company,string _companyName, string _location, string _hostline,string  _businessCode );
    event CreateInfoTicket (uint256 _eventId,string _venue,uint256 _startSales,uint256 _endSales,uint256 _ticketCount,uint256 _buyMax,ticketType _choice);
    event CreateInforDetailTicket (uint256 _eventId,string _name,string _describe,string[] _seat,uint256[] _price,ticketType _type);
    event CreateTicketId (uint256 _ticketId,string _name, string _describe,string _seat);
    event BuyTicket (uint256 _ticketId,uint256 _price,DetailTicket _ticket);
    constructor() ERC721 ("Ticket", "TCT") {}
    modifier onlyOwnerOTicket(uint _eventId) {
        require(eventToOwner[_eventId] == msg.sender);
        _;
    }
    function createInfoCompany(address _company,string memory _name, string memory _address, string memory _phone, string memory _businessCode) external onlyOwner {
        infoSeller[_company] = OrganizationalUintInfo(_name,_address,_phone,_businessCode,true);
        emit CreateInfoCompany(_company,_name,_address,_phone,_businessCode);
    }

    function _fowardFund(uint256 _amount, address _token) internal {
        if (_token == address(0)) { // native token (BNB)
            (bool isSuccess,) = fundWallet.call{value: _amount}("");
            require(isSuccess, "Transfer failed: gas error");
            return;
        }

        IERC20(_token).transferFrom(msg.sender, fundWallet, _amount);
    }
    function sum(uint256[] memory _array ) private pure returns(uint256) {
        uint256 t = 0;
        for (uint256 index = 0; index < _array.length; index++) {
            t = t + _array[index];
        }
        return t;
    }
    function creatEventSaleTicket(
        string memory _venue,
        string memory _name,
        string memory _describeDetail,
        string[] memory _seat,
        uint256 _saleStartTime,
        uint256 _saleEndTime,     
        uint256[] memory _amount,
	    uint256[] memory _price,
        uint256 _buyMax,
        address _token,
        ticketType  _type
    ) external payable {
        require(infoSeller[msg.sender].check == true , "The company is not in the list of partners");
        require(_saleEndTime > _saleStartTime, "please re-enter part-time ticket");
        require( sum(_amount) > 0 ,"Please re-enter the number of tickets");
        require(_buyMax > 0 ,"Please re-enter the maximum number of tickets that can be purchased");
        require(_buyMax < sum(_amount),"Please re-enter quantity");
        require((_seat.length == _price.length) &&  (_price.length == _amount.length), "Please re-enter your seat and fare");
        uint256 totalFund;
        if(_type == ticketType.footballTickets ) {
            totalFund = sum(_amount) * 5000000000000;
        }
        if(_type == ticketType.movieTickets ) {
            totalFund = sum(_amount) * 500000000000000;
        }
        if(_type == ticketType.concertTickets ){
            totalFund = sum(_amount) * 500000000000000;
        }
        if (_token == address(0)) {
            require(totalFund == msg.value, "invalid value");
        }
         _fowardFund(totalFund, _token);
        _eventID.increment();
        uint256 neweventID = _eventID.current();
        eventToOwner[neweventID] = msg.sender;
        ownerEventCount[msg.sender]++;
        infoEventTicket[neweventID] = InfoTicketSale (_saleStartTime,_saleEndTime,sum(_amount),0,_buyMax);
        infoDetailTicket[neweventID] = DetailTicket (_name,_venue,_describeDetail,_seat,_price,_type);
        uint256 length = ownerEventCount[msg.sender];
        listEventIDToCompany[msg.sender][length] = neweventID;
        for (uint256 index = 0; index < _seat.length; index++) {
            priceBySeat[neweventID][_seat[index]] = _price[index];
        }
        emit CreateInfoTicket(neweventID,_venue,_saleStartTime,_saleEndTime,sum(_amount),_buyMax,_type);
        emit CreateInforDetailTicket (neweventID,_name,_describeDetail,_seat,_price,_type);
    }
    
    MintToken mintToken;
    function setAddressToken (address _ckAddress) external onlyOwner {
        mintToken = MintToken(_ckAddress);
    
    }

     function buyTicket (uint256 _eventId, uint256 _amount, string[] memory _seat,address _token) public payable {
        InfoTicketSale memory infoticketsale = infoEventTicket[_eventId];
        InfoTicketSale memory infoticketbefore = infoEventTicket[_eventId-1];
        require(_amount > 0 ,"Please Please re-enter the number of tickets");
        require(_amount < (infoticketsale.numberOfTicketsSale - infoticketsale.numberOfTicketsSold));
        require(infoticketsale.saleStartTime < block.timestamp && infoticketsale.saleStartTime > block.timestamp,"sold out time");
        require(_amount < infoticketsale.maxBuy,"you bought too much");
        require(_amount < infoticketsale.numberOfTicketsSale,"There are not enough tickets left, please re-enter");
        require(_amount == _seat.length,"Please re-enter your sitting position");
        uint256 totalFund ;
        for (uint256 index = 0; index < _seat.length; index++) {
            totalFund = totalFund + priceBySeat[_eventId][_seat[index]];
        } 
         if (_token == address(0)) {
            require(totalFund == msg.value, "invalid value");
            
        }
        _fowardFund(totalFund * 1/100 , _token);
        if (_token == address(0)) { // native token (BNB)
            (bool isSuccess,) = eventToOwner[_eventId].call{value: totalFund * 99/100 }("");
            require(isSuccess, "Transfer failed: gas error");
        }
        if (_eventId == 0 ){
            infoticketbefore.numberOfTicketsSale = 0;
        }
        DetailTicket memory detailTicket = infoDetailTicket[_eventId];
        for (uint i = 0; i < _amount; i++) {
           uint256 ticketId =  infoticketbefore.numberOfTicketsSale + infoticketsale.numberOfTicketsSold + 1;
            _safeMint(msg.sender, ticketId);
            ticketByEvent[ticketId] = _eventId;
            infoticketsale.numberOfTicketsSold += 1;
            ticketIdToSeat[ticketId] = _seat[i];
            emit CreateTicketId(ticketId,detailTicket.name,detailTicket.describeDetail,_seat[i]);
        }
        mintToken.issueToken(msg.sender,_amount);
     }
     function burnTicket (uint256 _ticketId ) public {
        uint256 _eventId = ticketByEvent[_ticketId];
        require(eventToOwner[_eventId] == msg.sender,"can't burn tickets");
        _burn(_ticketId);   
     }
    function reSaleTicket (uint256 _ticketId,uint256 _price,uint256 _timeStart,uint256 _timeEnd) public {
        uint256 _eventId = ticketByEvent[_ticketId];
        DetailTicket memory detailTicket = infoDetailTicket[_eventId];
        require(ownerOf(_ticketId) == msg.sender,"Can't sell tickets");
        // require(_timeStart < _timeEnd && _timeEnd < detailTicket.timeStart,"Please re-enter the time");
        saleTicketByID[_ticketId] = InfoSaleTicket(_price,_timeStart,_timeEnd,detailTicket.name,detailTicket.venue,detailTicket.describeDetail,ticketIdToSeat[_ticketId],detailTicket.choice);
        emit BuyTicket(_ticketId,_price,detailTicket);
    }
    function buyReSaleTicket (uint256 _ticketId,address _token ) public payable {
        InfoSaleTicket memory inforTicket = saleTicketByID[_ticketId];
        address from = ownerOf(_ticketId);
        require(block.timestamp >= inforTicket.timeStart, "Sale has not started");
        require(block.timestamp <= inforTicket.timeStart, "Sale has ended");
        if (_token == address(0)) {
            require(inforTicket.price == msg.value, "invalid value");
        }
        if (_token == address(0)) { // native token (BNB)
            (bool isSuccess,) = from.call{value: inforTicket.price}("");
            require(isSuccess, "Transfer failed: gas error");
        }
         IERC20(_token).transferFrom(msg.sender,from, inforTicket.price);

       safeTransferFrom(from,msg.sender,_ticketId); 
    }
}
