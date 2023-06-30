//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IEventify {
    event Purchased(uint256 ticketId, address indexed to);

    function mintTickets(uint _price, uint _supply, string memory _tokenURI) external payable  ;

    function publishTickets(uint256 _ticketId) external payable;

    function pauseActiveEvent(uint256 _ticketId) external payable;

    function runPausedEvent(uint256 _ticketId) external payable;

    function buyTicket(uint256 _ticketId) external payable;
}