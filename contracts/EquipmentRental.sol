// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./DepositVault.sol";

contract EquipmentRental {
    address payable public owner;
    DepositVault public vault;
    
    enum RentalStatus { None, Active, Returned, Forfeited }

    struct RentInfo {
        uint256 deposit;
        RentalStatus status;
    }

    // Карта: адреса орендаря => інформація про оренду
    mapping(address => RentInfo) public rentals;

    uint256 public constant DEPOSIT_AMOUNT = 0.1 ether; // Фіксована вартість депозиту

    constructor() {
        owner = payable(msg.sender);
        vault = new DepositVault(); // Автоматично деплоїмо сховище разом із основним контрактом
    }

    // Оренда обладнання (надсилання депозиту)
    function rentEquipment() external payable {
        require(msg.value == DEPOSIT_AMOUNT, "Incorrect deposit amount. Need exactly 0.1 ETH");
        require(rentals[msg.sender].status != RentalStatus.Active, "Already have an active rental");

        rentals[msg.sender] = RentInfo({
            deposit: msg.value,
            status: RentalStatus.Active
        });

        // Пересилаємо отримані кошти у DepositVault за допомогою .call
        (bool success, ) = address(vault).call{value: msg.value}("");
        require(success, "Failed to send ETH to vault");
    }

    // Успішне повернення обладнання (депозит повертається клієнту)
    function returnEquipment(address _renter) external {
        require(msg.sender == owner, "Only owner can confirm return");
        require(rentals[_renter].status == RentalStatus.Active, "No active rental for this address");

        rentals[_renter].status = RentalStatus.Returned;
        uint256 amount = rentals[_renter].deposit;
        rentals[_renter].deposit = 0;

        vault.refund(payable(_renter), amount);
    }

    // Порушення умов (депозит утримується на користь власника)
    function forfeitEquipment(address _renter) external {
        require(msg.sender == owner, "Only owner can forfeit deposit");
        require(rentals[_renter].status == RentalStatus.Active, "No active rental for this address");

        rentals[_renter].status = RentalStatus.Forfeited;
        uint256 amount = rentals[_renter].deposit;
        rentals[_renter].deposit = 0;

        vault.forfeit(owner, amount);
    }
}
