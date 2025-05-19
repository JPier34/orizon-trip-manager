// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./TripLib.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

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
