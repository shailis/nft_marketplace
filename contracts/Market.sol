// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.13;

import "./IERC721.sol";

contract Market {
    // status of listing
    enum ListingStatus {
        ACTIVE,
        SOLD,
        CANCELLED
    }

    // structure of listing
    struct Listing {
        ListingStatus status;
        address seller;
        address tokenAddress;
        uint256 tokenId;
        uint256 price;
    }

    event Listed(
        uint256 listingId,
        address seller,
        address tokenAddress,
        uint256 tokenId,
        uint256 price
    );

    event Sale(
        uint256 listingId,
        address buyer,
        address tokenAddress,
        uint256 tokenId,
        uint256 price
    );

    event Cancel(uint256 listingId, address seller);

    uint256 private _listingId = 0;
    mapping(uint256 => Listing) private _listings;

    // function to list tokens
    function listToken(
        address tokenAddress,
        uint256 tokenId,
        uint256 price
    ) external {
        // transfer token from seller to contract
        IERC721(tokenAddress).transferFrom(msg.sender, address(this), tokenId);

        Listing memory listing = Listing(
            ListingStatus.ACTIVE,
            msg.sender,
            tokenAddress,
            tokenId,
            price
        );

        _listingId++;

        _listings[_listingId] = listing;

        emit Listed(_listingId, msg.sender, tokenAddress, tokenId, price);
    }

    // function to get listing of a token
    function getListing(uint256 listingId)
        public
        view
        returns (Listing memory)
    {
        return _listings[listingId];
    }

    // function to buy token
    function buyToken(uint256 listingId) external payable {
        Listing storage listing = _listings[listingId];

        // seller should not be buyer
        require(msg.sender != listing.seller, "Seller cannot be buyer");
        // listing should be active
        require(
            listing.status == ListingStatus.ACTIVE,
            "Listing is not active"
        );
        // sent money must be greater than or equal to token price
        require(msg.value >= listing.price, "Insufficient payment");

        listing.status = ListingStatus.SOLD;

        // transfer token from contract to buyer
        IERC721(listing.tokenAddress).transferFrom(
            address(this),
            msg.sender,
            listing.tokenId
        );
        // sent token price money to seller
        payable(listing.seller).transfer(listing.price);

        emit Sale(
            listingId,
            msg.sender,
            listing.tokenAddress,
            listing.tokenId,
            listing.price
        );
    }

    // function to cancel listing of token
    function cancel(uint256 listingId) public {
        Listing storage listing = _listings[listingId];

        // allow only seller to cancel listing
        require(msg.sender == listing.seller, "Only seller can cancel listing");
        // only cancel listing if it's active
        require(
            listing.status == ListingStatus.ACTIVE,
            "Listing is not active"
        );

        listing.status = ListingStatus.CANCELLED;

        // transfer token from contract to seller
        IERC721(listing.tokenAddress).transferFrom(
            address(this),
            msg.sender,
            listing.tokenId
        );

        emit Cancel(listingId, listing.seller);
    }
}
