//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./IEventify.sol";
import "./IFeaturedEvents.sol";

library structFeatured {
    struct Ticket {
        address host;
        uint supply;
        uint remaining;
        uint price;
        address owner;
        uint256 ticketId;
        bool isActive; //indicates paused/active event
        bool isPublished;
        bool isPrivateEvent; //if the event is open or shortlist based
        bool isExistingTicket;
        uint featuredId;
        bool isOver;
    }
}

contract FeaturedEvents is Ownable, IFeaturedEvents {

    mapping(uint256 => structFeatured.Ticket) public idToTicket;
    uint featuredId;

    function createFeaturedEvent(uint _supply, uint _remaining, uint _price, address _host, uint256 _ticketId, bool _isActive, bool _isPrivateEvent, bool _isExistingTicket) public {
        featuredId++;
        idToTicket[featuredId] = structFeatured.Ticket(_host, _supply, _remaining, _price, _host, _ticketId, _isActive, true, _isPrivateEvent, _isExistingTicket, featuredId, false);
    }

    function buyTicket(uint _ticketId, address _eventifyAddress) public payable {
        address eventifyContract = _eventifyAddress;
        IEventify eventify = IEventify(eventifyContract);
        eventify.buyTicket(_ticketId);
    }

    function markAsOver(uint _featuredId) public onlyOwner {
        idToTicket[_featuredId].isOver = true;
    }

    function fetchFeaturedEvents() public view returns (structFeatured.Ticket[] memory) {
        uint256 counter = 0;
        uint256 length;

        for (uint256 i = 0; i < featuredId; i++) {
            if(idToTicket[i + 1].isPublished == true && idToTicket[i + 1].isOver == false) {
                length++;
            }
        }

        structFeatured.Ticket[] memory tickets = new structFeatured.Ticket[](length);
        for (uint256 i = 0; i < featuredId; i++) {
            if(idToTicket[i + 1].isPublished == true && idToTicket[i + 1].isOver == false) {
                uint256 currentId = i + 1;
                structFeatured.Ticket storage currentItem = idToTicket[currentId];
                tickets[counter] = currentItem;
                counter++;
            }
        }
        return tickets;
    }

    function fetchPastFeaturedEvents() public view returns (structFeatured.Ticket[] memory) {
        uint256 counter = 0;
        uint256 length;

        for (uint256 i = 0; i < featuredId; i++) {
            if(idToTicket[i + 1].isPublished == true && idToTicket[i + 1].isOver == true) {
                length++;
            }
        }

        structFeatured.Ticket[] memory tickets = new structFeatured.Ticket[](length);
        for (uint256 i = 0; i < featuredId; i++) {
            if(idToTicket[i + 1].isPublished == true && idToTicket[i + 1].isOver == true) {
                uint256 currentId = i + 1;
                structFeatured.Ticket storage currentItem = idToTicket[currentId];
                tickets[counter] = currentItem;
                counter++;
            }
        }
        return tickets;
    }
}