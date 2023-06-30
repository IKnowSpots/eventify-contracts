//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155URIStorage.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./IEventify.sol";


library structTicket { 
    struct Ticket {
        uint supply;
        uint remaining;
        uint price;
        address owner;
        uint256 ticketId;
        bool status; //indicates paused/active event
        bool isPublished;
    }
}

contract Eventify is IEventify, ERC1155URIStorage, ERC1155Holder {
    address public host;

    // host is a contract deployer
    constructor() ERC1155("") {
        host = payable(tx.origin);
    }

    using Counters for Counters.Counter;
    Counters.Counter private _tokenId;

    mapping(uint256 => structTicket.Ticket) public idToTicket;

    modifier onlyHost() {
        require(tx.origin == host, "You are not deployer of this contract");
        _;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, ERC1155Receiver) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    // mints erc1155 Nft collection
    function mintTickets(uint _price, uint _supply, string memory _tokenURI) public payable onlyHost {
        _tokenId.increment();
        uint256 currentToken = _tokenId.current();
        _mint(host, currentToken, _supply, "");
        _setURI(currentToken, _tokenURI);
        idToTicket[currentToken] = structTicket.Ticket(_supply, _supply, _price, host, currentToken, false, false);
    }

    // publishes NFT collection as event tickets
    function publishTickets(uint256 _ticketId) public payable onlyHost {
        _safeTransferFrom(host, address(this), _ticketId, idToTicket[_ticketId].supply, "");
        idToTicket[_ticketId].status = true;
        idToTicket[_ticketId].isPublished = true;
    }
    // pauses an active event
    function pauseActiveEvent(uint256 _ticketId) public payable onlyHost {
        idToTicket[_ticketId].status = false;
    }

    // runs a paused event
    function runPausedEvent(uint256 _ticketId) public payable onlyHost {
        idToTicket[_ticketId].status = true;
    }

    // anyone can buy Nfts and amount goes to contract deployer
    function buyTicket(uint256 _ticketId) public payable {
        structTicket.Ticket storage ticket = idToTicket[_ticketId];
        require(msg.value == ticket.price, "Exact price not payed");
        require(ticket.remaining > 0, "No remining Nfts to buy in this collection");
        _safeTransferFrom(address(this), tx.origin, _ticketId, 1, "");
        ticket.owner = payable(tx.origin);
        ticket.remaining--;
        payable(host).transfer(ticket.price);
        emit Purchased(_ticketId, msg.sender);
    }

    // returns minted but not published nft collections
    function fetchMintedTickets() public view returns (structTicket.Ticket[] memory) {
        uint256 counter = 0;
        uint256 length;

        for (uint256 i = 0; i < _tokenId.current(); i++) {
            if (idToTicket[i + 1].isPublished == false) {
                length++;
            }
        }

        structTicket.Ticket[] memory tickets = new structTicket.Ticket[](length);
        for (uint256 i = 0; i < _tokenId.current(); i++) {
            if (idToTicket[i + 1].isPublished == false) {
                uint256 currentId = i + 1;
                structTicket.Ticket storage currentItem = idToTicket[currentId];
                tickets[counter] = currentItem;
                counter++;
            }
        }
        return tickets;
    }

    // returns published and active tickets collections
    function fetchActiveEvents() public view returns (structTicket.Ticket[] memory) {
        uint256 counter = 0;
        uint256 length;

        for (uint256 i = 0; i < _tokenId.current(); i++) {
            if (idToTicket[i + 1].remaining > 0 && idToTicket[i + 1].status == true && idToTicket[i + 1].isPublished == true) {
                length++;
            }
        }

        structTicket.Ticket[] memory tickets = new structTicket.Ticket[](length);
        for (uint256 i = 0; i < _tokenId.current(); i++) {
            if (idToTicket[i + 1].remaining > 0 && idToTicket[i + 1].status == true && idToTicket[i + 1].isPublished == true) {
                uint256 currentId = i + 1;
                structTicket.Ticket storage currentItem = idToTicket[currentId];
                tickets[counter] = currentItem;
                counter++;
            }
        }
        return tickets;
    }

    // returns published and paused tickets collections
    function fetchPausedEvents() public view returns (structTicket.Ticket[] memory) {
        uint256 counter = 0;
        uint256 length;

        for (uint256 i = 0; i < _tokenId.current(); i++) {
            if (idToTicket[i + 1].remaining > 0 && idToTicket[i + 1].status == false && idToTicket[i + 1].isPublished == true) {
                length++;
            }
        }

        structTicket.Ticket[] memory tickets = new structTicket.Ticket[](length);
        for (uint256 i = 0; i < _tokenId.current(); i++) {
            if (idToTicket[i + 1].remaining > 0 && idToTicket[i + 1].status == false && idToTicket[i + 1].isPublished == true) {
                uint256 currentId = i + 1;
                structTicket.Ticket storage currentItem = idToTicket[currentId];
                tickets[counter] = currentItem;
                counter++;
            }
        }
        return tickets;
    }
    
    // returns all published Nft collections by deployer
    function fetchAllEvents() public view returns (structTicket.Ticket[] memory) {
        uint256 counter = 0;

        structTicket.Ticket[] memory tickets = new structTicket.Ticket[](_tokenId.current());
        for (uint256 i = 0; i < _tokenId.current(); i++) {
            if(idToTicket[i + 1].isPublished == true){
                uint256 currentId = i + 1;
                structTicket.Ticket storage currentItem = idToTicket[currentId];
                tickets[counter] = currentItem;
                counter++;
            }
        }
        return tickets;
    }

    // returns all purchased Nfts of a user
    function fetchPurchasedTickets() public view returns (structTicket.Ticket[] memory) {
        uint256 counter = 0;
        uint256 length;

        for (uint256 i = 0; i < _tokenId.current(); i++) {
            if (idToTicket[i + 1].owner == tx.origin) {
                length++;
            }
        }

        structTicket.Ticket[] memory tickets = new structTicket.Ticket[](length);
        for (uint256 i = 0; i < _tokenId.current(); i++) {
            if (idToTicket[i + 1].owner == tx.origin) {
                uint256 currentId = i + 1;
                structTicket.Ticket storage currentItem = idToTicket[currentId];
                tickets[counter] = currentItem;
                counter++;
            }
        }
        return tickets;
    }
}