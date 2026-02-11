// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@fhenixprotocol/contracts/FHE.sol";
import { Permission } from "@fhenixprotocol/contracts/access/Permissioned.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract BlindZodiac is ERC721 {
    uint256 public _nextTokenId;

    // We use euint32 for everything because it is the most stable type in Fhenix Alpha
    // Mapping from NFT ID to Encrypted Sign ID
    mapping(uint256 => euint32) internal _blindSigns;

    constructor() ERC721("Blind Zodiac", "BZOD") {}

    function mintBlindZodiac(inEuint32 calldata encryptedDate) public {
        uint256 tokenId = _nextTokenId++;
        _mint(msg.sender, tokenId);

        // 1. Unpack the encrypted date
        euint32 date = FHE.asEuint32(encryptedDate);

        // 2. Default Sign ID = 0 (Unknown)
        euint32 signId = FHE.asEuint32(0);

        // --- ZODIAC LOGIC ---
        // Aries (March 21 - April 19) -> 321 to 419
        euint32 lower = FHE.asEuint32(321);
        euint32 upper = FHE.asEuint32(419);
        ebool isMatch = FHE.and(FHE.gte(date, lower), FHE.lte(date, upper));
        
        // If match, set signId to 1, else keep it as is
        signId = FHE.select(isMatch, FHE.asEuint32(1), signId);

        // Taurus (April 20 - May 20) -> 420 to 520
        lower = FHE.asEuint32(420);
        upper = FHE.asEuint32(520);
        isMatch = FHE.and(FHE.gte(date, lower), FHE.lte(date, upper));
        signId = FHE.select(isMatch, FHE.asEuint32(2), signId);

        // 3. Store the result
        _blindSigns[tokenId] = signId;
    }

    // RETURNS: A sealed string representing the number (1, 2, etc.)
    function getMySign(uint256 tokenId, Permission memory permission) public view returns (string memory) {
        require(ownerOf(tokenId) == msg.sender, "Not the owner");
        
        // This seals the result so only the user with the key can read it
        return FHE.seal(_blindSigns[tokenId], permission.publicKey);
    }
}