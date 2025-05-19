# ✈️ OrizonTripManager Smart Contract

A decentralized trip booking platform built in Solidity. This contract allows providers to offer trips and clients to book, cancel, and track their trip status — all with secure payment and balance management.

## 📌 Features

- ✅ Trip creation by providers
- ✅ Trip booking by clients (with payment)
- ✅ Trip cancellation (up to 14 days before departure)
- ✅ Balance tracking for both providers and clients
- ✅ Provider withdrawals
- ✅ Protection against reentrancy attacks

## 🔍 Github

- Repository: https://github.com/JPier34/orizon-trip-manager

---

## ⚙️ Contract Overview

---

### 🧱 Main Contract

**`TripManager.sol`**

Uses an external struct library `TripLib.sol` to manage `Trip` data structure:
```solidity
struct Trip {
    string name;
    string location;
    uint256 startDate;
    uint256 endDate;
    uint256 price;
    address provider;
    bool isActive;
}


🔐 Security
Uses ReentrancyGuard (OpenZeppelin) to prevent reentrancy in withdraw().

Access control ensures that only legitimate users can query their balances.


🚀 How to Use (via Remix):


🧑‍💼 Add a Trip (Provider)

addTrip("Rome Experience", "Rome", 1739836800, 1740355200, 2000000000000000000)


👤 Book a Trip (Client)

Select bookTrip(uint256 tripId)

Insert tripId (e.g., 0)

In the "Value" field above the button, enter the trip price (e.g., 2 ether)

Click transact


❌ Cancel Booking

Clients can cancel their booking only if:

It's more than 14 days before the trip starts.

They're not the provider.

Call:

cancelBooking(0)


✅ Complete Trip (Provider only)

completeTrip(0, clientAddress)


💸 Withdraw Earnings (Provider)

withdraw()


🧾 Read-Only Functions
Function	Description
getAllTrips()	Returns the full list of registered trips
getClientBalance(address)	Returns a client's balance (self-query only)
getProviderBalance(address)	Returns provider balance and registration status
bookings(address, uint256)	Returns whether a user booked a given trip


🔐 Access Control

Role	Permissions
Provider	Can add trips, complete trips, and withdraw funds
Client	Can book and cancel trips
getClientBalance()	Only the owner can access their own balance
getProviderBalance()	Open, includes verification via isProvider


💾 Deployment Notes

Solidity version: ^0.8.20

OpenZeppelin library required: @openzeppelin/contracts/security/ReentrancyGuard.sol

TripLib.sol should be present and imported


📂 Folder Structure

/contracts
  ├── TripLib.sol
  └── TripManager.sol


📃 License
MIT License — Free to use, modify, and distribute.


🧠 Author Notes
Designed for decentralization, clarity, and maximum composability.
Feel free to fork and expand the logic (e.g., add review/rating systems, NFT trip passes, off-chain oracle integrations).