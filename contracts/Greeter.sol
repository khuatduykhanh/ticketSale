//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.12;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract TicketSale is Ownable,ERC721 {
    
    using Counters for Counters.Counter;
    Counters.Counter private _eventID;

    struct OrganizationalUintInfo {
        string  companyName;
        string  location;
        string hostline;
        string Code;

    }
    enum ticketType {
        footballTickets,
        movieTickets,
        concertTickets
    }

    struct InfoTicketSale {
        string venue;
        uint256 saleStartTime;
        uint256 saleEndTime;
        uint256 numberOfTicketsSale;
        uint256 numberOfTicketsSold;
        uint256 maxBuy;
        ticketType choice;
    }
    struct DetailTicket {
        string name;
        string describeDetail;
        string[] seat;
        uint256[] price;
        uint256 timeStart;
        uint256 timeEnd;
        
    }

    address[] private ListCompany;
    address public fundWallet;
    mapping (uint256 => address ) public eventToOwner;
    mapping (address => uint256 ) ownerEventCount;
    mapping (address => OrganizationalUintInfo ) public infoSeller;
    mapping (address => mapping (uint256 => uint256)) listEventIDToCompany;
    mapping(uint256 => uint256)  _ownedTokensIndex;
    mapping (uint256 => InfoTicketSale) public infoEventTicket;
    mapping (uint256 => DetailTicket) infoDetailTicket;
    mapping (uint256 => mapping(string => uint256 )) priceBySeat;
    mapping (uint256 => uint256 ) ticketByEvent;
    event CreateInfoCompany(address _company,string _companyName, string _location, string _hostline,string  _businessCode );
    event CreateInfoTicket (uint256 _eventId,string _venue,uint256 _startSales,uint256 _endSales,uint256 _ticketCount,uint256 _buyMax,ticketType _choice);
    event CreateInforDetailTicket (uint256 _eventId,string _name,string _describe,uint256 _timeStart,uint256 _timeEnd,string[] _seat,uint256[] _price);
    event CreateTicketId (uint256 _ticketId,string _name, string _describe,uint256 _timeStart,uint256 _timeEnd,string _seat);
    constructor() ERC721 ("Ticket", "TCT") {}
    modifier onlyOwnerOTicket(uint _eventId) {
        require(eventToOwner[_eventId] == msg.sender);
        _;
    }
    function createInfoCompany(address _company,string memory _name, string memory _address, string memory _phone, string memory _businessCode) external onlyOwner {
        infoSeller[_company] = OrganizationalUintInfo(_name,_address,_phone,_businessCode);
        ListCompany.push(_company);
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
    function _checkAddress (address _address) view private returns (bool) {
        for (uint256 index = 0; index < ListCompany.length; index++) {
            if (_address == ListCompany[index]) {
                return true;
            }
        }
        return false;
    }

    function creatEventSaleTicket(
        string memory _venue,
        ticketType _type,
        uint256 _saleStartTime,
        uint256 _saleEndTime,
        uint256 _amount,
        uint256 _buyMax,
        address _token
    ) external payable {
        require(_checkAddress(msg.sender), "The company is not in the list of partners");
        require(_saleEndTime > _saleStartTime, "please re-enter part-time ticket");
        require(_amount > 0 ,"Please re-enter the number of tickets");
         require(_buyMax > 0 ,"Please re-enter the maximum number of tickets that can be purchased");
        require(_buyMax < _amount,"Please re-enter quantity");
        uint256 totalFund;
        if(_type == ticketType.footballTickets ) {
            totalFund = _amount * 5000000000000;
        }
        if(_type == ticketType.movieTickets ) {
            totalFund = _amount * 500000000000000;
        }
        if(_type == ticketType.concertTickets ){
            totalFund = _amount * 500000000000000;
        }
        if (_token == address(0)) {
            require(totalFund == msg.value, "invalid value");
        }
         _fowardFund(totalFund, _token);
        _eventID.increment();
        uint256 neweventID = _eventID.current();
        eventToOwner[neweventID] = msg.sender;
        ownerEventCount[msg.sender]++;
        infoEventTicket[neweventID] = InfoTicketSale (_venue,_saleStartTime,_saleEndTime,_amount,0,_buyMax,_type);
        // infoTicket[msg.sender][neweventID] = ticketSale (_venue,_saleStartTime,_saleEndTime,_amount,_buyMax,_type);
        uint256 length = ownerEventCount[msg.sender];
        listEventIDToCompany[msg.sender][length] = neweventID;

        emit CreateInfoTicket(neweventID,_venue,_saleStartTime,_saleEndTime,_amount,_buyMax,_type);
    }
    
    function ticketDetail(uint256 _eventId,string memory _name,string memory _describe,uint256 _timeStart,uint256 _timeEnd,string[] memory _seat,uint256[] memory _price) external onlyOwnerOTicket(_eventId) {
        require(_timeEnd > _timeStart, "Please re-enter the time");
        require(_seat.length == _price.length, "Please re-enter your seat and fare");
        infoDetailTicket[_eventId] = DetailTicket(_name,_describe,_seat,_price,_timeStart,_timeEnd);
        for (uint256 index = 0; index < _seat.length; index++) {
            priceBySeat[_eventId][_seat[index]] = _price[index];
        }
        emit CreateInforDetailTicket (_eventId,_name,_describe,_timeStart,_timeEnd,_seat,_price);
    }

    function stringToUint(string memory s) private pure returns (uint) {
    bytes memory b = bytes(s);
    uint result = 0;
    for (uint i = 0; i < b.length; i++) { // c = b[i] was not needed
        if (b[i] >= 0x48 && b[i] <= 0x57) {
            result = result * 10 + (uint(uint8(b[i]) - 48)); // bytes and int are not compatible with the operator -.
        }
    }
    return result; // this was missing
    }

     function buyTicket (uint256 _eventId, uint256 _amount, string[] memory _seat,address _token) public payable {
        InfoTicketSale memory infoticketsale = infoEventTicket[_eventId];
        require(_amount > 0 ,"Please Please re-enter the number of tickets");
        require(_amount < (infoticketsale.numberOfTicketsSale - infoticketsale.numberOfTicketsSold));
        require(infoticketsale.saleStartTime < block.timestamp && infoticketsale.saleStartTime > block.timestamp,"sold out time");
        require(_amount < infoticketsale.maxBuy,"you bought too much");
        require(_amount < infoticketsale.numberOfTicketsSale,"There are not enough tickets left, please re-enter");
        require(_amount == _seat.length,"Please re-enter your sitting position");
        uint256 totalFund;
        for (uint256 index = 0; index < _seat.length; index++) {
            totalFund = totalFund + priceBySeat[_eventId][_seat[index]];
        } 
         if (_token == address(0)) {
            require(totalFund == msg.value, "invalid value");
        }
        _fowardFund(totalFund, _token);
        string memory bonus;
        if(infoticketsale.numberOfTicketsSale < 999 ){
            bonus = "000";
        }
        if(infoticketsale.numberOfTicketsSale < 9999) {
            bonus = "0000";
        }
        if(infoticketsale.numberOfTicketsSale < 99999) {
            bonus = "00000";
        }
        DetailTicket memory detailTicket = infoDetailTicket[_eventId];
        for (uint i = 0; i < _amount; i++) {
         //   uint256 ticketId = uint256(string memory (Strings.toString(_eventId) + bonus + Strings.toString(infoticketsale.numberOfTicketsSold)));
           string memory newEvent = Strings.toString(_eventId);
           string memory newTicketID = string.concat(newEvent,bonus);
           uint256 ticketId =   stringToUint(newTicketID) + infoticketsale.numberOfTicketsSold + 1;
            _safeMint(msg.sender, ticketId);
            ticketByEvent[ticketId] = _eventId;
            infoticketsale.numberOfTicketsSold += 1;
            emit CreateTicketId(ticketId,detailTicket.name,detailTicket.describeDetail,detailTicket.timeStart,detailTicket.timeEnd,_seat[i]);
        }
     }
    // function burnTicket (uint256 _eventId ) public 
}
