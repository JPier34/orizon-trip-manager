// SPDX-License-Identifier: MIT
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
