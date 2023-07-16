// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// host is the actual wallet that deploy this eventify
// owner is the factory contract that deploys this contract

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Eventify.sol";
import "./FeaturedEvents.sol";
import "./IFactoryEventify.sol";


contract FactoryEventify is IFactoryEventify, Ownable {

    Eventify[] public contracts;
    address public featuredEventsInstanceAddress;
    FeaturedEvents featuredEventsInstance;

    mapping(address => string) public addressToUsernames;
    mapping(string => uint256) public usernamesToContractId;  // map username to a new contract Id
    mapping (string => bool) public usernameExist;
    mapping(address => bool) public hasDeployed;
    mapping(address => bool) public isWhitelisted;
    mapping(address => bool) public isWhitelistOperator;
    mapping(address => string[]) public userToAllHostPurchased;

    uint contractId;

    struct FeaturedRequest {
        address host;
        uint ticketId;
        bool isApproved;
    }

    uint256 featuredRequestId;
    mapping(uint256 => FeaturedRequest) public idToFeaturedRequest;

    constructor() {
        isWhitelistOperator[msg.sender] = true;
        featuredEventsInstance = new FeaturedEvents();
        featuredEventsInstanceAddress = address(featuredEventsInstance);
    }

    function setWhitelistOperator(address _user) public onlyOwner {
        isWhitelistOperator[_user] = true;
    }

    function whitelistUser(address _user) public {
        require(isWhitelistOperator[msg.sender] == true);
        isWhitelisted[_user] = true;
        emit UserWhitelisted(_user, msg.sender);
    }

    // deploys Eventify contract for user with _username
    function deployEventify(string memory _username) public returns (address) {
        // require(isWhitelisted[msg.sender] == true, "You are not whitelisted");
        require(hasDeployed[msg.sender] != true);
        Eventify t = new Eventify(featuredEventsInstanceAddress);
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

    function fetchAllPurchasedTickets() public view returns (structTicket.Ticket[][] memory) {
        uint256 counter = 0;
        uint256 length = userToAllHostPurchased[msg.sender].length;
        structTicket.Ticket[][] memory tickets = new structTicket.Ticket[][](length);

        for (uint256 i = 0; i < userToAllHostPurchased[msg.sender].length; i++) {
            uint id = i;
            structTicket.Ticket[] memory currentItem = contracts[id].fetchPurchasedTickets();
            tickets[counter] = currentItem;
        }
        return tickets;
    }

    function fetchAllFeaturedRequest() public view returns (FeaturedRequest[] memory) {
        uint256 counter = 0;
        uint256 length;

        for (uint256 i = 0; i < featuredRequestId; i++) {
            if (idToFeaturedRequest[i + 1].isApproved == false) {
                length++;
            }
        }

        FeaturedRequest[] memory tickets = new FeaturedRequest[](length);
        for (uint256 i = 0; i < featuredRequestId; i++) {
            if (idToFeaturedRequest[i + 1].isApproved == false) {
                uint256 currentId = i + 1;
                FeaturedRequest storage currentItem = idToFeaturedRequest[currentId];
                tickets[counter] = currentItem;
                counter++;
            }
        }
        return tickets;
    }

    function uriCall(address host, uint256 _ticketId) public view returns (string memory) {
        string memory _username = addressToUsernames[host];
        uint id = usernamesToContractId[_username];
        return  contracts[id].uri(_ticketId);
    }

    function raiseFeaturedEvents(uint256 _ticketId) public {
        featuredRequestId++;
        idToFeaturedRequest[featuredRequestId] = FeaturedRequest(msg.sender, _ticketId, false);
    }

    function approveFeaturedEvents(address host, uint256 _ticketId) public onlyOwner {
        string memory _username = addressToUsernames[host];
        uint id = usernamesToContractId[_username];
        contracts[id].pushFeaturedEvent(_ticketId);
        idToFeaturedRequest[_ticketId].isApproved == false;
    }
    
    function fetchFeaturedEvents() public view returns (structFeatured.Ticket[] memory) {
        return  featuredEventsInstance.fetchFeaturedEvents();
    }

    // function mintTicketsCall(uint _price, uint _supply, bool _isPrivateEvent, string memory _tokenURI) public {
    //     string memory _username = addressToUsernames[msg.sender];
    //     uint id = usernamesToContractId[_username];
    //     contracts[id].mintTickets(_price, _supply, _isPrivateEvent, _tokenURI);
    // }

    // function publishTickets(uint256 _ticketId) public {
    //     string memory _username = addressToUsernames[msg.sender];
    //     uint id = usernamesToContractId[_username];
    //     contracts[id].publishTickets(_ticketId);
    // }

    function fetchActiveEventsCall(string memory _username) public view returns (structTicket.Ticket[] memory) {
        uint id = usernamesToContractId[_username];
        return  contracts[id].fetchActiveEvents();
    }

    function buyTicketCall(string memory _username, uint256 _ticketId) public payable {
        uint id = usernamesToContractId[_username];
        contracts[id].buyTicket{value: msg.value}(_ticketId);
        userToAllHostPurchased[msg.sender].push(_username);
    }

    // function pauseActiveEventCall(uint256 _ticketId) public payable {
    //     string memory _username = addressToUsernames[msg.sender];
    //     uint id = usernamesToContractId[_username];
    //     contracts[id].pauseActiveEvent(_ticketId);
    // }

    // function runPausedEventCall(uint256 _ticketId) public payable {
    //     string memory _username = addressToUsernames[msg.sender];
    //     uint id = usernamesToContractId[_username];
    //     contracts[id].runPausedEvent(_ticketId);
    // }

    // function fetchMintedTicketsCall(string memory _username) public view returns (structTicket.Ticket[] memory) {
    //     uint id = usernamesToContractId[_username];
    //     return  contracts[id].fetchMintedTickets();
    // }

    // function fetchShortlistEvents() public view returns (structFeatured.Ticket[] memory) {}

    // function fetchPausedEventsCall(string memory _username) public view returns (structTicket.Ticket[] memory) {
    //     uint id = usernamesToContractId[_username];
    //     return  contracts[id].fetchPausedEvents();
    // }

    // function fetchAllEventsCall(string memory _username) public view returns (structTicket.Ticket[] memory) {
    //     uint id = usernamesToContractId[_username];
    //     return  contracts[id].fetchAllEvents();
    // }

    // function fetchPurchasedTickets(string memory _username) public view returns (structTicket.Ticket[] memory) {
    //     uint id = usernamesToContractId[_username];
    //     return  contracts[id].fetchPurchasedTickets();
    // }
}