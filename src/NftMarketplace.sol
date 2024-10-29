// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {IERC721} from "@openzeppelin-contracts/interfaces/IERC721.sol";
import {ReentrancyGuard} from "@openzeppelin-contracts/utils/ReentrancyGuard.sol";

contract NftMarketplace is ReentrancyGuard {
    /*==============================================================
                                ERRORS
    ==============================================================*/
    error PriceNotMet(address nftAddress, uint256 tokenId, uint256 price);
    error ItemNotForSale(address nftAddress, uint256 tokenId);
    error NotListed(address nftAddress, uint256 tokenId);
    error AlreadyListed(address nftAddress, uint256 tokenId);
    error NoProceeds();
    error NotOwner();
    error NotApprovedForMarketplace();
    error PriceMustBeAboveZero();

    /*==============================================================
                            STATE VARIABLES
    ==============================================================*/
    struct Listing {
        uint256 price;
        address seller;
    }

    mapping(address => mapping(uint256 => Listing)) private s_listings;
    mapping(address => uint256) private s_proceeds;

    /*==============================================================
                                EVENTS
    ==============================================================*/

    event ItemListed(
        address indexed seller,
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 price
    );

    event ItemCanceled(
        address indexed seller,
        address indexed nftAddress,
        uint256 indexed tokenId
    );

    event ItemBought(
        address indexed buyer,
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 price
    );

    /*==============================================================
                           FUNCTION MODIFIERS
    ==============================================================*/

    modifier notListed(
        address nftAddress,
        uint256 tokenId,
        address owner
    ) {
        Listing memory listing = s_listings[nftAddress][tokenId];
        if (listing.price > 0) {
            revert AlreadyListed(nftAddress, tokenId);
        }
        _;
    }

    modifier isOwner(
        address nftAddress,
        uint256 tokenId,
        address spender
    ) {
        IERC721 nft = IERC721(nftAddress);
        address owner = nft.ownerOf(tokenId);
        if (spender != owner) {
            revert NotOwner();
        }
        _;
    }

    modifier isListed(address nftAddress, uint256 tokenId) {
        Listing memory listing = s_listings[nftAddress][tokenId];
        if (listing.price <= 0) {
            revert NotListed(nftAddress, tokenId);
        }
        _;
    }

    /*==============================================================
                                FUNCTIONS
    ==============================================================*/

    /*----------- External Functions -----------*/
    function listNft(
        address _nftAddress,
        uint256 _tokenId,
        uint256 _nftPrice
    )
        external
        notListed(_nftAddress, _tokenId, msg.sender)
        isOwner(_nftAddress, _tokenId, msg.sender)
    {
        require(_nftPrice > 0, PriceMustBeAboveZero());
        IERC721 nft = IERC721(_nftAddress);
        require(
            nft.getApproved(_tokenId) == address(this),
            NotApprovedForMarketplace()
        );

        s_listings[_nftAddress][_tokenId] = Listing(_nftPrice, msg.sender);
        emit ItemListed(msg.sender, _nftAddress, _tokenId, _nftPrice);
    }

    function cancelListing(
        address _nftAddress,
        uint256 _tokenId
    )
        external
        isOwner(_nftAddress, _tokenId, msg.sender)
        isListed(_nftAddress, _tokenId)
    {
        delete (s_listings[_nftAddress][_tokenId]);
        emit ItemCanceled(msg.sender, _nftAddress, _tokenId);
    }

    function buyNft(
        address _nftAddress,
        uint256 _tokenId
    ) external payable isListed(_nftAddress, _tokenId) nonReentrant {
        Listing memory listedItem = s_listings[_nftAddress][_tokenId];
        require(
            msg.value > listedItem.price,
            PriceNotMet(_nftAddress, _tokenId, listedItem.price)
        );

        s_proceeds[listedItem.seller] += msg.value;
        delete (s_listings[_nftAddress][_tokenId]);
        IERC721(_nftAddress).safeTransferFrom(
            listedItem.seller,
            msg.sender,
            _tokenId
        );
        emit ItemBought(msg.sender, _nftAddress, _tokenId, listedItem.price);
    }

    function updateListing(
        address _nftAddress,
        uint256 _tokenId,
        uint256 _newPrice
    )
        external
        isListed(_nftAddress, _tokenId)
        nonReentrant
        isOwner(_nftAddress, _tokenId, msg.sender)
    {
        require(_newPrice != 0, PriceMustBeAboveZero());

        s_listings[_nftAddress][_tokenId].price = _newPrice;
        emit ItemListed(msg.sender, _nftAddress, _tokenId, _newPrice);
    }

    function withdrawBalance() external nonReentrant {
        uint256 proceeds = s_proceeds[msg.sender];
        require(proceeds > 0, NoProceeds());
        s_proceeds[msg.sender] = 0;

        (bool success, ) = payable(msg.sender).call{value: proceeds}("");
        require(success, "Transfer failed");
    }

    /*----------- View and Pure Functions -----------*/
    function getListing(
        address nftAddress,
        uint256 tokenId
    ) external view returns (Listing memory) {
        return s_listings[nftAddress][tokenId];
    }

    function getProceeds(address seller) external view returns (uint256) {
        return s_proceeds[seller];
    }
}
