//SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155URIStorage.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

library structTicket { 
    struct Ticket {
        uint supply;
        uint remaining;
        uint price;
        address owner;
        uint256 tokenId;
        bool status;
    }
}

contract Eventify is ERC1155URIStorage, ERC1155Holder {
    address public host;

    // contract deployer is called host
    constructor() ERC1155("") {
        host = payable(tx.origin);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155, ERC1155Receiver)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    using Counters for Counters.Counter;
    Counters.Counter private _tokenId;

    mapping(uint256 => structTicket.Ticket) public idToTicket;

    modifier onlyHost() {
        require(tx.origin == host, "You are not deployer of this contract");
        _;
    }

    // mints erc1155 Nft collection and sends to currrent contract
    function hostEvent(uint _price, uint _supply, string memory _tokenURI) public payable onlyHost {
        _tokenId.increment();
        uint256 currentToken = _tokenId.current();
        _mint(host, currentToken, _supply, "");
        _safeTransferFrom(host, address(this), currentToken, _supply, "");
        _setURI(currentToken, _tokenURI);
        idToTicket[currentToken] = structTicket.Ticket(_supply, _supply, _price, host, currentToken, true);
    }

    function pauseActiveEvents(uint256 _ticketId) public payable onlyHost {
        idToTicket[_ticketId].status = false;
    }

    function playActiveEvents(uint256 _ticketId) public payable onlyHost {
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
    }

    // returns all purchased Nfts
    function inventory() public view returns (structTicket.Ticket[] memory) {
        uint256 counter = 0;
        uint256 length;

        for (uint256 i = 0; i < _tokenId.current(); i++) {
            if (idToTicket[i + 1].owner == tx.origin) {
                length++;
            }
        }

        structTicket.Ticket[] memory myTickets = new structTicket.Ticket[](length);
        for (uint256 i = 0; i < _tokenId.current(); i++) {
            if (idToTicket[i + 1].owner == tx.origin) {
                uint256 currentId = i + 1;
                structTicket.Ticket storage currentItem = idToTicket[currentId];
                myTickets[counter] = currentItem;
                counter++;
            }
        }
        return myTickets;
    }

    // returns all remaining Nft collections
    function activeEvents() public view returns (structTicket.Ticket[] memory) {
        uint256 counter = 0;
        uint256 length;

        for (uint256 i = 0; i < _tokenId.current(); i++) {
            if (idToTicket[i + 1].remaining > 0 && idToTicket[i + 1].status == true) {
                length++;
            }
        }

        structTicket.Ticket[] memory unsoldTickets = new structTicket.Ticket[](length);
        for (uint256 i = 0; i < _tokenId.current(); i++) {
            if (idToTicket[i + 1].remaining > 0 && idToTicket[i + 1].status == true) {
                uint256 currentId = i + 1;
                structTicket.Ticket storage currentItem = idToTicket[currentId];
                unsoldTickets[counter] = currentItem;
                counter++;
            }
        }
        return unsoldTickets;
    }
    
    // returns all published Nft collections by deployer
    function hostedEvents() public view returns (structTicket.Ticket[] memory) {
        uint256 counter = 0;

        structTicket.Ticket[] memory myTickets = new structTicket.Ticket[](_tokenId.current());
        for (uint256 i = 0; i < _tokenId.current(); i++) {
                uint256 currentId = i + 1;
                structTicket.Ticket storage currentItem = idToTicket[currentId];
                myTickets[counter] = currentItem;
                counter++;
        }
        return myTickets;
    }
}