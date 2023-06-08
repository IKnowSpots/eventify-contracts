// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./eventify.sol";

contract FactoryEventify {

    Eventify[] public contracts;
    Eventify public eventifyLibrary;

    mapping(address => string) public addressToUsernames;  // users set their usernames while deploying contract
    mapping(string => uint256) public usernamesToContractId;  // map username to a new contract Id
    mapping(address => bool) public haveDeployed;

    uint contractId;
    event EventifyCreated(address owner, address tokenContract);


    // deploys Eventify contract for user with _username
    // a user can only deploy one contract
    function deployEventify(string memory _username) public returns (address) {
        require(haveDeployed[msg.sender] != true);
        Eventify t = new Eventify();
        contracts.push(t);
        addressToUsernames[msg.sender] =_username;
        usernamesToContractId[_username] = contracts.length - 1;
        haveDeployed[msg.sender] == true;
        emit EventifyCreated(msg.sender, address(t));
        return address(t);
    }

    function getContractAddress(string memory _username) public view returns (address) {
        uint id = usernamesToContractId[_username];
        return address(contracts[id]);
    }


    function hostCall(uint _price, uint _supply, string memory _tokenURI) public {
        string memory _username = addressToUsernames[msg.sender];
        uint id = usernamesToContractId[_username];
        contracts[id].hostEvent(_price, _supply, _tokenURI);
    }

    function pauseActiveEvents(uint256 _ticketId) public payable {
        string memory _username = addressToUsernames[msg.sender];
        uint id = usernamesToContractId[_username];
        contracts[id].pauseActiveEvents(_ticketId);
    }

    function unpauseActiveEvents(uint256 _ticketId) public payable {
        string memory _username = addressToUsernames[msg.sender];
        uint id = usernamesToContractId[_username];
        contracts[id].pauseActiveEvents(_ticketId);
    }


    function buyCall(string memory _username, uint256 _ticketId) public payable {
        uint id = usernamesToContractId[_username];
        contracts[id].buyTicket{value: msg.value}(_ticketId);
    }

    function hostedEventsCall(string memory _username) public view returns (structTicket.Ticket[] memory) {
        // require(keccak256(abi.encodePacked((addressToUsernames[msg.sender]))) == keccak256(abi.encodePacked((_username))), "You are not the deployer of this contract");
        uint id = usernamesToContractId[_username];
        return  contracts[id].hostedEvents();
    }

    function inventoryCall(string memory _username) public view returns (structTicket.Ticket[] memory) {
        uint id = usernamesToContractId[_username];
        return  contracts[id].inventory();
    }

    function activeEventsCall(string memory _username) public view returns (structTicket.Ticket[] memory) {
        uint id = usernamesToContractId[_username];
        return  contracts[id].activeEvents();
    }
}