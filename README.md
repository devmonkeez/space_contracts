# Spacem Token and Collection Contracts

## Overview

This repository contains the smart contracts for the **Spacem Token**, **Collection**, and **Staking** systems. These contracts are designed to manage a comprehensive token economy, utilizing ERC20 and ERC721 standards to enable minting, staking, and reward distributions.

## Contracts

### SpacemToken

The `SpacemToken` contract is an implementation of the ERC20 standard with additional features for burning tokens and ownership control. It is built using OpenZeppelin's libraries to ensure security and reliability.

- **Token Name:** Spacem Token
- **Symbol:** SPACEM
- **Initial Supply:** 50 billion tokens minted to the initial owner.
- **Burnable:** Users can burn tokens to decrease the total supply.
- **Ownership:** Controlled by a single owner using OpenZeppelin's `Ownable` pattern.

### Collection

The `Collection` contract is an ERC721 implementation that manages a collection of unique NFTs. It includes features for minting, enumeration, and pausing, allowing the contract owner to control the minting process.

- **NFT Name:** SPACEM NODE
- **Symbol:** SPACEMN
- **Maximum Supply:** Configurable limit on the total number of NFTs that can be minted.
- **Minting:** The contract owner can mint new NFTs, ensuring the supply limit is respected.
- **Pausable:** The contract can be paused and unpaused to control the minting process.

### SpacemNodes

The `SpacemNodes` contract handles the sales and reward distribution of NFTs. It features a referral system for NFT purchases and distributes daily rewards to NFT holders.

- **Referral System:** Users can earn rewards by referring others to purchase NFTs.
- **Daily Rewards:** NFT holders receive rewards distributed daily based on ownership.
- **Ownership and Access Control:** Utilizes OpenZeppelin's `Ownable` and `ReentrancyGuard` for secure access management.

### Staking

The `Staking` contract allows users to stake their tokens for fixed periods in exchange for rewards. It offers multiple staking options with different reward rates and ensures the secure management of the reward pool.

- **Staking Durations:** Options range from one month to five years, each with a specific reward rate.
- **Reward Calculation:** Rewards are calculated based on predefined annual percentage yield (APY) rates.
- **Reward Pool Management:** The owner can adjust the reward pool and ensure its proper distribution.

---

For detailed information on each contract, please refer to the individual contract files and their documentation within this repository.
