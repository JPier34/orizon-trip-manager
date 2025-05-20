// SPDX-License-Identifier: MIT
// File: contracts/TripLib.sol


pragma solidity ^0.8.0;

library TripLib {
    struct Trip {
        string name;
        string location;
        uint256 startDate;
        uint256 endDate;
        uint256 price;
        address provider;
        bool isActive;
    }

    event TripBooked(uint256 tripId, address indexed client, uint256 amount);
}

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}

// File: contracts/TripManager.sol


pragma solidity ^0.8.20;



contract TripManager is ReentrancyGuard{
    using TripLib for TripLib.Trip;
    TripLib.Trip[] public trips;

    mapping(address => uint256) public providerBalances;
    mapping(address => mapping(uint256 => bool)) public bookings;
    mapping(address => bool) public isProvider;
    mapping(address => uint256) public clientBalances;

    event BookingConfirmation(uint256 tripId, address client, string message);

    // Client books a trip
    function bookTrip(uint256 tripId) external payable {
        TripLib.Trip storage trip = trips[tripId];
        require(tripId < trips.length, "Invalid trip ID");
        require(trip.isActive, "Trip not available!");
        require(msg.value == trip.price, "Incorrect amount!");
        require(block.timestamp < trip.startDate, "Trip already started!");
        require(!bookings[msg.sender][tripId], "Already booked!");

        clientBalances[msg.sender] += msg.value;
        bookings[msg.sender][tripId] = true;

    emit TripLib.TripBooked(tripId, msg.sender, msg.value);
    emit BookingConfirmation(tripId, msg.sender,  "Congratulations! Booking completed! You can still cancel your trip 14 days before your trip starts!");
    }

    // Client deletes the booking (before the trip)
    function cancelBooking(uint256 tripId) external {
        TripLib.Trip storage trip = trips[tripId];
        require(tripId < trips.length, "Invalid trip ID");
        require(bookings[msg.sender][tripId], "No booking found");
        require(block.timestamp < trip.startDate - 14 days, "Cannot cancel within 14 days of trip start");
        require(msg.sender != trip.provider, "Provider cannot cancel client booking!");

        clientBalances[msg.sender] -= trip.price;
        payable(msg.sender).transfer(trip.price);
        bookings[msg.sender][tripId] = false;
    }

    // Trip ends. Provider gets the payment
    function completeTrip(uint256 tripId, address client) external {
        TripLib.Trip storage trip = trips[tripId];
        require(tripId < trips.length, "Invalid trip ID");
        require(msg.sender == trip.provider, "Not the trip provider!");
        require(bookings[client][tripId], "Client didn't book this trip yet!");

        providerBalances[msg.sender] += trip.price;
        bookings[client][tripId] = false;
    }

    // Provider withdraws the funds available to him
    function withdraw() external nonReentrant {
        uint256 amount = providerBalances[msg.sender];
        require(amount > 0, "No funds available to withdraw!");

        // EFFECTS (before)
        providerBalances[msg.sender] = 0;

        // INTERACTION (after)
        (bool sent, ) = payable(msg.sender).call{value: amount}("");
        require(sent, "Transfer failed");
}

    // Adds a new trip (providers only)
    function addTrip(
        string memory name,
        string memory location,
        uint256 startDate,
        uint256 endDate,
        uint256 price
    ) external {
        require(startDate < endDate, "Invalid dates");

        isProvider[msg.sender] = true;

        trips.push(
            TripLib.Trip({
                name: name,
                location: location,
                startDate: startDate,
                endDate: endDate,
                price: price,
                provider: msg.sender,
                isActive: true
            })
        );
    }

    // Gets all the available trips
    function getAllTrips() external view returns (TripLib.Trip[] memory) {
        return trips;
    }

    // Reads the current balance (client/provider)
    function getClientBalance(address client) external view returns (uint256) {
        require(client == msg.sender, "Access denied: only the owner can access");
        return clientBalances[msg.sender];
    }

    function getProviderBalance(address provider) external view returns (uint256 balance, bool registered) {
    return (providerBalances[provider], isProvider[provider]);
}
}
