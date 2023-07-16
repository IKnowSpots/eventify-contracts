//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IFeaturedEvents {
    function createFeaturedEvent(uint _supply, uint _remaining, uint _price, address _host, uint256 _ticketId, bool _isActive, bool _isPrivateEvent, bool _isExistingTicket) external;

    function buyTicket(uint _ticketId, address _eventifyAddress) payable external;
    
    function markAsOver(uint _featuredId) external;
}