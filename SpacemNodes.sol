// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";





contract Collection is ERC721, ERC721Enumerable, ERC721Pausable, Ownable(msg.sender) {
     uint256 public maxSupply;
    uint256 public minted;
    string public baseURI;

    constructor(
        uint256 _maxSupply,
        string memory _baseURI 
    )
        ERC721("SPACEM NODE", "SPACEMN")  
    {
        maxSupply = _maxSupply;
        baseURI = _baseURI;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    // Function to mint a new NFT
    function mint(address to) public payable onlyOwner returns (uint256) {
        require(minted < maxSupply, "Max supply reached");
        minted += 1;
        uint256 tokenId = minted;
        _safeMint(to, tokenId);
        return tokenId;
    }

    // The following functions are overrides required by Solidity.

    function _update(address to, uint256 tokenId, address auth)
        internal
        override(ERC721, ERC721Enumerable, ERC721Pausable)
        returns (address)
    {
        return super._update(to, tokenId, auth);
    }

    function _increaseBalance(address account, uint128 value)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._increaseBalance(account, value);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

      // Override the tokenURI function to return the base URI
    function tokenURI(uint256) public view override returns (string memory) {
        return baseURI;
    }
}



contract SpacemNodes is Ownable(msg.sender), ReentrancyGuard {
    Collection public collection;
    IERC20 public rewardsToken;
    IERC20 public usdtToken;
    uint256 public contractStartTime = 1715260175;
    uint256 public contractEndTime = 1873026575;
    address public safeAddress = 0x511C645389eBe73aecFfaA57924d14ec46c13de8;
    address public stakingAddress = 0x62766990101d74f393F25e538191c00C40cB1fe4;
    address public marketingAddress = 0x27Ac53EF2B3D37fFee3aa11bf9E5B81c876D3572;
    address public communityRewardsAddress = 0x43e855635009b1f04fc8961852638B895A272020;

    struct NFTInfo {
        address collectionAddress;
        uint256 tokenId;
        string name;
        string imageURL;
    }

    mapping(uint256 => uint256) public mintTime;
    mapping(uint256 => uint256) public lastClaim;
    mapping(uint256 => address) public referredBy;
    mapping(string => address) public inviteCode;
    mapping(address => string) public inviteCodeForAddress;
    mapping(address => uint256) public invitePercent;

    uint256 constant DAILY_TOKENS = 451000000000000000000;
    uint256 constant DISTIBUTION_SPEED = 1 days;  
    uint256 constant DAYS = 1826;
    uint256 constant DAILY_STAKING = 1500000000000000000000000;
    uint256 constant DAILY_MARKETING = 1500000000000000000000000;
    uint256 constant DAILY_COMMUNITY_REWARDS = 3000000000000000000000000;

    mapping(uint256 => uint256) public dailyNodeReward;
    uint256 public lastDistributionDay;
    bool public IS_PAUSED = false;

    event CollectionCreated(address collectionAddress);

    constructor(address _collection) {
        usdtToken = IERC20(0x9702230A8Ea53601f5cD2dc00fDBc13d4dF4A8c7);
        rewardsToken = IERC20(0x3c780F5cBF94De3EFCec964Af928D08c4508EeBE);
        collection = Collection(_collection);
    }

    function addRefferal(
        address user,
        uint256 percent,
        string memory code
    ) public onlyOwner {
        inviteCode[code] = user;
        invitePercent[user] = percent;
        inviteCodeForAddress[user] = code;
    }

    function addRefferals(address[] memory _users, string[] memory _codes) public onlyOwner {
        require(_users.length == _codes.length, "Array lengths must match");
        for (uint256 j = 0; j < _users.length; j++) {
            inviteCode[_codes[j]] = _users[j];
            invitePercent[_users[j]] = 10;
            inviteCodeForAddress[_users[j]] = _codes[j];
        }
    }

    function getPriceForQuantity(uint256 quantity) public view returns (uint256) {
        uint256 cost = 0;
        for (uint256 i = 0; j < quantity; j++) {
            uint256 price = getPrice(collection.minted() + i);
            cost += price;
        }
        return cost;
    }

    function buy(uint256 quantity, uint256 usdtAmount, address referrer) public nonReentrant {
        if(IS_PAUSED) collection.unpause();

        uint256 available = collection.maxSupply() - collection.minted();
        require(quantity > 0 && quantity <= available, "Not enough NFTs available.");

        uint256 cost = getPriceForQuantity(quantity);

        // Ensure the payment is transferred for this portion
        require(usdtToken.transferFrom(msg.sender, address(this), cost), "USDT payment failed");

        uint256 refPercent = invitePercent[referrer];
        uint256 refAmount = 0;
        if(refPercent > 0) {
            refAmount = cost * refPercent / 100;
            require(usdtToken.transfer(referrer, refAmount), "USDT referral payment failed");
        }
        uint256 safeAmount = cost - refAmount;
        require(usdtToken.transfer(safeAddress, safeAmount), "USDT safe payment failed");

        // Save who referred the user
        referredBy[collection.minted()] = referrer;

        // Mint the NFTs
        for (uint256 j = 0; j < quantity; j++) {
            uint256 tokenId = collection.mint(msg.sender);
            mintTime[tokenId] = block.timestamp;
            lastClaim[tokenId] = block.timestamp;
        }

        if(IS_PAUSED) collection.pause();
    }

    function calculateRewards(uint256 tokenId) public view returns (uint256) {
        uint256 lastClaimTime = lastClaim[tokenId] > 0 ? lastClaim[tokenId] : mintTime[tokenId];
        if (lastClaimTime >= contractEndTime) return 0;

        uint256 currentTime = block.timestamp > contractEndTime ? contractEndTime : block.timestamp;
        uint256 totalRewards = 0;

        uint256 day = lastClaimTime / DISTIBUTION_SPEED * DISTIBUTION_SPEED;
        uint256 currentDay = currentTime / DISTIBUTION_SPEED * DISTIBUTION_SPEED;

        while (day < currentDay) {
            if (dailyNodeReward[day] > 0) {
                totalRewards += dailyNodeReward[day];
            }
            day += DISTIBUTION_SPEED;
        }

        return totalRewards;
    }


    function claimRewards(uint256 tokenId) public nonReentrant {
        require(collection.ownerOf(tokenId) == msg.sender, "You are not the owner of this token");

        uint256 rewardAmount = calculateRewards(tokenId);
        require(rewardAmount > 0, "No rewards to claim");

        lastClaim[tokenId] = block.timestamp;
        require(rewardsToken.transfer(msg.sender, rewardAmount), "Failed to transfer rewards");
    }

    function claimAllRewards() public nonReentrant {
        uint256 numTokens = collection.balanceOf(msg.sender);
        uint256 totalReward = 0;

        for (uint256 i = 0; i < numTokens; i++) {
            uint256 tokenId = collection.tokenOfOwnerByIndex(msg.sender, i);
            uint256 rewardAmount = calculateRewards(tokenId);

            if (rewardAmount > 0) {
                lastClaim[tokenId] = block.timestamp;
                totalReward += rewardAmount;
            }
        }

        require(totalReward > 0, "No rewards to claim");
        require(rewardsToken.transfer(msg.sender, totalReward), "Failed to transfer rewards");
    }
    
    function dailyDistribute() public nonReentrant {
        uint256 today = block.timestamp / DISTIBUTION_SPEED * DISTIBUTION_SPEED; // Normalize to the start of the day

        // Check if function has already been run today
        require(lastDistributionDay < today, "Distribution already done for today");

        // Calculate reward based on the number of tokens minted
        uint256 reward = (DAILY_TOKENS * collection.maxSupply()) / collection.minted();
        dailyNodeReward[today] = reward;
        lastDistributionDay = today; // Update the last distribution day to today

        require(rewardsToken.transfer(stakingAddress, DAILY_STAKING), "Failed to transfer DAILY_STAKING");
        require(rewardsToken.transfer(marketingAddress, DAILY_MARKETING), "Failed to transfer DAILY_MARKETING");
        require(rewardsToken.transfer(communityRewardsAddress, DAILY_COMMUNITY_REWARDS), "Failed to transfer DAILY_COMMUNITY_REWARDS");
    }

    function importRewards(uint256[] memory _tokenIDs, uint256[] memory _mintTimes, uint256[] memory _lastClaims) public onlyOwner {
        require(_tokenIDs.length == _mintTimes.length && _tokenIDs.length == _lastClaims.length, "Array lengths must match");
        for (uint256 j = 0; j < _tokenIDs.length; j++) {
            mintTime[_tokenIDs[j]] = _mintTimes[j];
            lastClaim[_tokenIDs[j]] = _lastClaims[j];
        }
    }

    function importDailyRewards(uint256[] memory _timestamps, uint256[] memory _rewards) public onlyOwner {
        require(_timestamps.length == _rewards.length, "Array lengths must match");
        for (uint256 j = 0; j < _timestamps.length; j++) {
            dailyNodeReward[_timestamps[j]] = _rewards[j];
        }
    }

    function getPrice(uint256 tokenId) public pure returns (uint256) {
        if(tokenId < 500) { 
            return 300 * 1e6;
        } else if(tokenId >= 500 && tokenId < 2000) {
            return 450 * 1e6;
        } else if(tokenId >= 2000 && tokenId < 3000) {
            return 600 * 1e6;
        } else if(tokenId >= 3000 && tokenId < 4000) {
            return 800 * 1e6;
        } else if(tokenId >= 4000 && tokenId < 5000) {
            return 1000 * 1e6;
        } else if(tokenId >= 5000 && tokenId < 6000) {
            return 1200 * 1e6;
        } else if(tokenId >= 6000 && tokenId < 7000) {
            return 1400 * 1e6;
        } else if(tokenId >= 7000 && tokenId < 8000) {
            return 1600 * 1e6;
        } else if(tokenId >= 8000 && tokenId < 9000) {
            return 1800 * 1e6;
        } else if(tokenId >= 9000 && tokenId < 10000) {
            return 2000 * 1e6;
        } else if(tokenId >= 10000 && tokenId < 11000) {
            return 2200 * 1e6;
        } else if(tokenId >= 11000 && tokenId < 12000) {
            return 2400 * 1e6;
        } else if(tokenId >= 12000 && tokenId < 13000) {
            return 2600 * 1e6;
        } else if(tokenId >= 13000 && tokenId < 14000) {
            return 2800 * 1e6;
        } else if(tokenId >= 14000 && tokenId < 15000) {
            return 3000 * 1e6;
        } else if(tokenId >= 15000 && tokenId < 16000) {
            return 3200 * 1e6;
        } else if(tokenId >= 16000 && tokenId < 17000) {
            return 3400 * 1e6;
        } else if(tokenId >= 17000 && tokenId < 18000) {
            return 3600 * 1e6;
        } else if(tokenId >= 18000 && tokenId < 19000) {
            return 3800 * 1e6;
        } else if(tokenId >= 19000 && tokenId < 20000) {
            return 4000 * 1e6;
        } 
        return 9999 * 1e6;
    }

    function getAllNFTsForUser(address user) public view returns (NFTInfo[] memory) {
        uint totalNFTCount = collection.balanceOf(user);

        NFTInfo[] memory nfts = new NFTInfo[](totalNFTCount);

        for (uint j = 0; j < totalNFTCount; j++) {
            uint tokenId = collection.tokenOfOwnerByIndex(user, j);
            nfts[j] = NFTInfo(
                address(collection),
                tokenId,
                collection.name(),
                collection.tokenURI(tokenId)
            );
        }

        return nfts;
    }

    function changeIsPaused(bool _value) public onlyOwner {
        IS_PAUSED = _value;
    }

    function exportData() public view returns (
        uint256[] memory, uint256[] memory, uint256[] memory, address[] memory
    ) {
        uint256 totalSupply = collection.totalSupply();
        uint256[] memory tokenIds = new uint256[](totalSupply);
        uint256[] memory mintTimes = new uint256[](totalSupply);
        uint256[] memory lastClaims = new uint256[](totalSupply);
        address[] memory referrers = new address[](totalSupply);

        for (uint256 i = 0; i < totalSupply; i++) {
            uint256 tokenId = collection.tokenByIndex(i);
            tokenIds[i] = tokenId;
            mintTimes[i] = mintTime[tokenId];
            lastClaims[i] = lastClaim[tokenId];
            referrers[i] = referredBy[tokenId];
        }

        return (tokenIds, mintTimes, lastClaims, referrers);
    }

}