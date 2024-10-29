// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {ERC721} from "@openzeppelin-contracts/token/ERC721/ERC721.sol";
import {ERC721URIStorage} from "@openzeppelin-contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import {Ownable} from "@openzeppelin-contracts/access/Ownable.sol";

contract SavageNft is ERC721, ERC721URIStorage, Ownable {
    /*==============================================================
                                ERRORS
    ==============================================================*/
    error UriQueryForNonExistentToken();

    /*==============================================================
                            STATE VARIABLES
    ==============================================================*/
    uint256 private s_tokenCounter;

    /*==============================================================
                                EVENTS
    ==============================================================*/
    event SavageMinted(uint256 indexed tokenId);

    /*==============================================================
                                FUNCTIONS
    ==============================================================*/
    constructor(
        address initialOwner
    ) ERC721("Savage", "SAV") Ownable(initialOwner) {
        s_tokenCounter = 0;
    }

    function mintNft(address _to, string memory uri) public onlyOwner {
        s_tokenCounter = s_tokenCounter + 1;
        _safeMint(_to, s_tokenCounter);
        _setTokenURI(s_tokenCounter, uri);
        emit SavageMinted(s_tokenCounter);
    }

    function getTokenCounter() public view returns (uint256) {
        return s_tokenCounter;
    }

    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        require(ownerOf(tokenId) != address(0), UriQueryForNonExistentToken());
        return super.tokenURI(tokenId);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721, ERC721URIStorage) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
