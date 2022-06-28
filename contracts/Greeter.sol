//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.7;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
contract TicketSale is Ownable, ERC721 {
    
    using Counters for Counters.Counter;
    Counters.Counter private _eventID;

    struct organizationalUintInfo {
        string  companyName;
        string  location;
        string hostline;
        string representativeName;
        string Code;

    }
    enum ticketType {
        footballTickets,
        movieTickets,
        concertTickets
    }

    struct ticketSale {
        string venue;
        string performanceContent;
        uint256 saleStartTime;
        uint256 saleEndTime;
        uint256 numberOfTicketsSale;
        uint256 startTime;
        ticketType choice;
    }

    address[] private ListCompany;
    address public fundWallet;

    mapping (address => organizationalUintInfo ) public InfoSeller;
    mapping (address => mapping(uint256 => ticketSale )) public infoTicket;

    event CreateInfoCompany(address _company,string _companyName, string _location, string _hostline,string  _representativeName,string  _businessCode );
    
    constructor() ERC721("TICKET", "TCK") {}
    

    function createInfoCompany(address _company,string memory _name, string memory _address, string memory _phone, string memory _directorNanme, string memory _businessCode) external onlyOwner {
        InfoSeller[_company] = organizationalUintInfo( _name,_address,_phone,_directorNanme,_businessCode);
        ListCompany.push(_company);
        emit CreateInfoCompany(_company,_name,_address,_phone,_directorNanme,_businessCode);
    }

    function _fowardFund(uint256 _amount, address _token) internal {
        if (_token == address(0)) { // native token (BNB)
            (bool isSuccess,) = fundWallet.call{value: _amount}("");
            require(isSuccess, "Transfer failed: gas error");
            return;
        }

        IERC20(_token).transferFrom(msg.sender, fundWallet, _amount);
    }
    function creatEventSaleTicket(
        string memory _venue,
        string memory _performanceContent,
        ticketType _type,
        uint256 _saleStartTime,
        uint256 _saleEndTime,
        uint256 _amount,
        uint256 _startTime,
        address _token
    ) external payable {
        uint256 totalFund;
        if(_type == ticketType.footballTickets ) {
            totalFund = _amount * 500000000000000;
        }
        if(_type == ticketType.movieTickets ) {
            totalFund = _amount * 500000000000000;
        }
        if (_token == address(0)) {
            require(totalFund == msg.value, "invalid value");
        }

        _eventID.increment();
        uint256 neweventID = _eventID.current();
    }
    
}
