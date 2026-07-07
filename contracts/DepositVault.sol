// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract DepositVault {
    address public rentalContract;

    modifier onlyRental() {
        require(msg.sender == rentalContract, "Only Rental contract can call this");
        _;
    }

    constructor() {
        rentalContract = msg.sender; // Створювачем буде контракт EquipmentRental
    }

    // Функція для приймання Ether на контракт
    receive() external payable {}

    // Повернення депозиту орендарю
    function refund(address payable _renter, uint256 _amount) external onlyRental {
        require(address(this).balance >= _amount, "Insufficient balance in vault");
        (bool success, ) = _renter.call{value: _amount}("");
        require(success, "Refund failed");
    }

    // Утримання депозиту (переказ власнику платформи)
    function forfeit(address payable _owner, uint256 _amount) external onlyRental {
        require(address(this).balance >= _amount, "Insufficient balance in vault");
        (bool success, ) = _owner.call{value: _amount}("");
        require(success, "Forfeit failed");
    }

    // Перевірка балансу сховища
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
}