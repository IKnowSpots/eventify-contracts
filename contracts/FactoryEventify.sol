// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Eventify.sol";
import "./IFactoryEventify.sol";

contract FactoryEventify is IFactoryEventify, Ownable {

    Eventify[] public contracts;
    Eventify public eventifyLibrary;

    mapping(address => string) public addressToUsernames;  // users set their usernames while deploying contract
    mapping(string => uint256) public usernamesToContractId;  // map username to a new contract Id
    mapping (string => bool) public usernameExist;
    mapping(address => bool) public hasDeployed;
    mapping(address => bool) public isWhitelisted;
    mapping(address => bool) public isWhitelistOperator;

    uint contractId;

    constructor() {
        isWhitelistOperator[msg.sender] = true;
    }

    function setWhitelistOperator(address _user) public onlyOwner {
        isWhitelistOperator[_user] = true;
    }

    function whitelistUser(address _user) public {
        require(isWhitelistOperator[msg.sender] == true, "You are not a whitelist operator");
        isWhitelisted[_user] = true;
        emit UserWhitelisted(_user, msg.sender);
    }

    // deploys Eventify contract for user with _username
    function deployEventify(string memory _username) public returns (address) {
        // require(isWhitelisted[msg.sender] == true, "You are not whitelisted");
        require(hasDeployed[msg.sender] != true, "Already deployed");
        Eventify t = new Eventify();
        contracts.push(t);
        addressToUsernames[msg.sender] =_username;
        usernameExist[_username] = true;
        usernamesToContractId[_username] = contracts.length - 1;
        hasDeployed[msg.sender] = true;
        emit EventifyDeployed(msg.sender, address(t));
        return address(t);
    }

    function getContractAddress(string memory _username) public view returns (address) {
        uint id = usernamesToContractId[_username];
        return address(contracts[id]);
    }


    function mintTicketsCall(uint _price, uint _supply, string memory _tokenURI) public {
        string memory _username = addressToUsernames[msg.sender];
        uint id = usernamesToContractId[_username];
        contracts[id].mintTickets(_price, _supply, _tokenURI);
    }

    function publishTickets(uint256 _ticketId) public {
        string memory _username = addressToUsernames[msg.sender];
        uint id = usernamesToContractId[_username];
        contracts[id].publishTickets(_ticketId);
    }

    function pauseActiveEventCall(uint256 _ticketId) public payable {
        string memory _username = addressToUsernames[msg.sender];
        uint id = usernamesToContractId[_username];
        contracts[id].pauseActiveEvent(_ticketId);
    }

    function runPausedEventCall(uint256 _ticketId) public payable {
        string memory _username = addressToUsernames[msg.sender];
        uint id = usernamesToContractId[_username];
        contracts[id].runPausedEvent(_ticketId);
    }

    function buyTicketCall(string memory _username, uint256 _ticketId) public payable {
        uint id = usernamesToContractId[_username];
        contracts[id].buyTicket{value: msg.value}(_ticketId);
    }

    function fetchMintedTicketsCall(string memory _username) public view returns (structTicket.Ticket[] memory) {
        uint id = usernamesToContractId[_username];
        return  contracts[id].fetchMintedTickets();
    }

    function fetchActiveEventsCall(string memory _username) public view returns (structTicket.Ticket[] memory) {
        uint id = usernamesToContractId[_username];
        return  contracts[id].fetchActiveEvents();
    }

    function fetchPausedEventsCall(string memory _username) public view returns (structTicket.Ticket[] memory) {
        uint id = usernamesToContractId[_username];
        return  contracts[id].fetchPausedEvents();
    }

    function fetchAllEventsCall(string memory _username) public view returns (structTicket.Ticket[] memory) {
        uint id = usernamesToContractId[_username];
        return  contracts[id].fetchAllEvents();
    }

    function fetchPurchasedTickets(string memory _username) public view returns (structTicket.Ticket[] memory) {
        uint id = usernamesToContractId[_username];
        return  contracts[id].fetchPurchasedTickets();
    }

    function uriCall(string memory _username, uint256 _ticketId) public view returns (string memory) {
        uint id = usernamesToContractId[_username];
        return  contracts[id].uri(_ticketId);
    }
}