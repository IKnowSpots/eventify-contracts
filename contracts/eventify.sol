//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155URIStorage.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./IEventify.sol";
import "./IFeaturedEvents.sol";

library structTicket { 
    struct Ticket {
        address host;
        uint supply;
        uint remaining;
        uint price;
        address owner;
        uint256 ticketId;
        bool isActive; //indicates paused/active event
        bool isPublished;
        bool isPrivateEvent; //if the event is open or shortlist-based
        bool isExistingTicket;
    }

    enum NftType {
        ERC721,
        ERC1155
    }

    struct existing721NFT {
        NftType nftType;
        string collectionName;
        address contractAddress;
    }

    struct existing1155NFT {
        NftType nftType;
        string collectionName;
        address contractAddress;
        uint256 tokenId;
    }
}

contract Eventify is Ownable, IEventify, ERC1155URIStorage, ERC1155Holder {
    address public host;
    IFeaturedEvents featuredEvents;

    // host is a contract deployer
    constructor(address _featuredContract) ERC1155("") {
        host = payable(tx.origin);
        featuredEvents = IFeaturedEvents(_featuredContract);
    }

    using Counters for Counters.Counter;
    Counters.Counter private _tokenId;

    mapping(uint256 => structTicket.Ticket) public idToTicket;
    mapping(uint256 => structTicket.existing721NFT) public idToExisting721;
    mapping(uint256 => structTicket.existing1155NFT) public idToExisting1155;
    mapping(uint256 => address[]) public idToShortlist;

    modifier onlyHost() {
        require(tx.origin == host, "You are not deployer of this contract");
        _;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, ERC1155Receiver) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    // mints erc1155 Nft collection
    function mintTickets(uint _price, uint _supply, bool _isPrivateEvent, string memory _tokenURI) public onlyHost {
        _tokenId.increment();
        uint256 currentToken = _tokenId.current();
        _mint(host, currentToken, _supply, "");
        _setURI(currentToken, _tokenURI);
        idToTicket[currentToken] = structTicket.Ticket(host, _supply, _supply, _price, host, currentToken, false, false, _isPrivateEvent, false);
    }

    // publishes NFT collection as event tickets
    function publishTickets(uint256 _ticketId) public onlyHost {
        _safeTransferFrom(host, address(this), _ticketId, idToTicket[_ticketId].supply, "");
        idToTicket[_ticketId].isActive = true;
        idToTicket[_ticketId].isPublished = true;
    }

    // publishes existing ERC721 NFT collection as event tickets
    function publishExistingNFT721Tickets(string memory _collectionName, address _contract) public onlyHost {
        _tokenId.increment();
        uint256 currentToken = _tokenId.current();
        idToTicket[currentToken] = structTicket.Ticket(host, 0, 0, 0, address(0), currentToken, false, false, false, false);
        idToExisting721[currentToken] = structTicket.existing721NFT(structTicket.NftType.ERC721, _collectionName, _contract);
    }

    // publishes existing ERC1155 NFT collection as event tickets
    function publishExistingNFT1155Tickets(string memory _collectionName, address _contract, uint256 _nftId) public onlyHost {
        _tokenId.increment();
        uint256 currentToken = _tokenId.current();
        idToExisting1155[currentToken] = structTicket.existing1155NFT(structTicket.NftType.ERC1155, _collectionName, _contract, _nftId);
    }

    // pauses an active event
    function pauseActiveEvent(uint256 _ticketId) public onlyHost {
        idToTicket[_ticketId].isActive = false;
    }

    // runs a paused event
    function runPausedEvent(uint256 _ticketId) public onlyHost {
        idToTicket[_ticketId].isActive = true;
    } 

    // updates shortlist for a shortlist event
    function updateShortlist(uint256 _ticketId, address[] memory _shortlist) public { 
        idToShortlist[_ticketId] = _shortlist;
    }

    function pushFeaturedEvent(uint _ticketId) public onlyOwner {
        structTicket.Ticket storage ticket = idToTicket[_ticketId];
        featuredEvents.createFeaturedEvent(ticket.supply, ticket.remaining, ticket.price, host, ticket.ticketId, ticket.isActive, ticket.isPrivateEvent, ticket.isExistingTicket);
    }

    // anyone can buy Nfts and amount goes to contract deployer
    function buyTicket(uint256 _ticketId) public payable { 
        structTicket.Ticket storage ticket = idToTicket[_ticketId];
        if(ticket.isPrivateEvent == true) {
            shortlistBuy(_ticketId);
        } else {

        require(msg.value == ticket.price, "Exact price not payed");
        require(ticket.remaining > 0, "No remining Nfts to buy in this collection");
        _safeTransferFrom(address(this), tx.origin, _ticketId, 1, "");
        ticket.owner = payable(tx.origin);
        ticket.remaining--;
        payable(host).transfer(ticket.price);
        emit Purchased(_ticketId, msg.sender);
        }
    }

    // shortlist users can claim NFTs 
    function shortlistBuy(uint256 _ticketId) public returns (bool) {
        structTicket.Ticket storage ticket = idToTicket[_ticketId];
        for (uint256 i = 0; i < ticket.supply; i++) {
            address iAddress = idToShortlist[_ticketId][i];
            if (tx.origin == iAddress) {
                require(ticket.remaining > 0, "No tickets left to claim");
                require(balanceOf(msg.sender, _ticketId) < 1, "You already own a ticket");
                _safeTransferFrom(address(this), tx.origin, _ticketId, 1, "");
                ticket.owner = tx.origin;
                ticket.remaining = ticket.remaining - 1;
                return true;
            }
        }
        return false;
    }

    // returns minted but not published nft collections
    function fetchMintedTickets() public view returns (structTicket.Ticket[] memory) {
        uint256 counter = 0;
        uint256 length;

        for (uint256 i = 0; i < _tokenId.current(); i++) {
            if (idToTicket[i + 1].isPublished == false && idToTicket[i + 1].isExistingTicket == false) {
                length++;
            }
        }

        structTicket.Ticket[] memory tickets = new structTicket.Ticket[](length);
        for (uint256 i = 0; i < _tokenId.current(); i++) {
            if (idToTicket[i + 1].isPublished == false && idToTicket[i + 1].isExistingTicket == false) {
                uint256 currentId = i + 1;
                structTicket.Ticket storage currentItem = idToTicket[currentId];
                tickets[counter] = currentItem;
                counter++;
            }
        }
        return tickets;
    }

    // returns published and active events
    function fetchActiveEvents() public view returns (structTicket.Ticket[] memory) {
        uint256 counter = 0;
        uint256 length;

        for (uint256 i = 0; i < _tokenId.current(); i++) {
            structTicket.Ticket memory iTicket = idToTicket[i + 1];
            if (iTicket.remaining > 0 && iTicket.isActive == true && iTicket.isPublished == true) {
                length++;
            }
        }

        structTicket.Ticket[] memory tickets = new structTicket.Ticket[](length);
        for (uint256 i = 0; i < _tokenId.current(); i++) {
            structTicket.Ticket memory iTicket = idToTicket[i + 1];
            if (iTicket.remaining > 0 && iTicket.isActive == true && iTicket.isPublished == true) {
                uint256 currentId = i + 1;
                structTicket.Ticket storage currentItem = idToTicket[currentId];
                tickets[counter] = currentItem;
                counter++;
            }
        }
        return tickets;
    }

    // returns published and paused events
    function fetchPausedEvents() public view returns (structTicket.Ticket[] memory) {
        uint256 counter = 0;
        uint256 length;

        for (uint256 i = 0; i < _tokenId.current(); i++) {
            structTicket.Ticket memory iTicket = idToTicket[i + 1];
            if (iTicket.remaining > 0 && iTicket.isActive == false && iTicket.isPublished == true) {
                length++;
            }
        }

        structTicket.Ticket[] memory tickets = new structTicket.Ticket[](length);
        for (uint256 i = 0; i < _tokenId.current(); i++) {
            structTicket.Ticket memory iTicket = idToTicket[i + 1];
            if (iTicket.remaining > 0 && iTicket.isActive == false && iTicket.isPublished == true) {
                uint256 currentId = i + 1;
                structTicket.Ticket storage currentItem = idToTicket[currentId];
                tickets[counter] = currentItem;
                counter++;
            }
        }
        return tickets;
    }

    // returns published and shortlist-type events
    function fetchShortlistEvents() public view returns (structTicket.Ticket[] memory) {
        uint256 counter = 0;
        uint256 length;

        for (uint256 i = 0; i < _tokenId.current(); i++) {
            structTicket.Ticket memory iTicket = idToTicket[i + 1];
            if (iTicket.remaining > 0 && iTicket.isActive == true && iTicket.isPublished == true && iTicket.isExistingTicket == false && iTicket.isPrivateEvent == true) {
                length++;
            }
        }

        structTicket.Ticket[] memory tickets = new structTicket.Ticket[](length);
        for (uint256 i = 0; i < _tokenId.current(); i++) {
            structTicket.Ticket memory iTicket = idToTicket[i + 1];
            if (iTicket.remaining > 0 && iTicket.isActive == true && iTicket.isPublished == true && iTicket.isExistingTicket == false && iTicket.isPrivateEvent == true) {
                uint256 currentId = i + 1;
                structTicket.Ticket storage currentItem = idToTicket[currentId];
                tickets[counter] = currentItem;
                counter++;
            }
        }
        return tickets;
    }
    
    // returns all published events by deployer
    function fetchAllEvents() public view returns (structTicket.Ticket[] memory) {
        uint256 counter = 0;
        uint256 length;

        structTicket.Ticket[] memory tickets = new structTicket.Ticket[](length);
        for (uint256 i = 0; i < _tokenId.current(); i++) {
            uint256 currentId = i + 1;
            structTicket.Ticket storage currentItem = idToTicket[currentId];
            tickets[counter] = currentItem;
            counter++;
        }
        return tickets;
    }

    // returns all purchased tickets of a user
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