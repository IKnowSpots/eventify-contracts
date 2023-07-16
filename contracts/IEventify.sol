//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IEventify {
    event Purchased(uint256 ticketId, address indexed to);

    function mintTickets(uint _price, uint _supply, bool _isPrivateEvent, string memory _tokenURI) external;

    function publishTickets(uint256 _ticketId) external;

    function pauseActiveEvent(uint256 _ticketId) external;

    function runPausedEvent(uint256 _ticketId) external;

    function buyTicket(uint256 _ticketId) external payable;

    function pushFeaturedEvent(uint _ticketId) external;
}