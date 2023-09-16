// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

// Importing the necessary version of Solidity.

contract MultiSig {
    // Define the MultiSig contract.

    address[] public owners; // An array to store the addresses of contract owners.
    uint public numConfirmationsRequired; // The number of confirmations required to execute a transaction.

    struct Transaction {
        // Define a structure to represent a transaction.
        address to;     // The destination address of the transaction.
        uint value;     // The value (amount) of the transaction.
        bool executed;  // A flag to track whether the transaction has been executed.
    }

    mapping(uint => mapping(address => bool)) isConfirmed; // Mapping to track if an owner has confirmed a transaction.
    Transaction[] public transactions; // An array to store pending transactions.

    // Events for logging important contract actions.
    event TransactionSubmitted(uint transactionId, address sender, address receiver, uint amount);
    event TransactionConfirmed(uint transactionId);
    event TransactionExecuted(uint transactionId);

    // Constructor to initialize the contract with owners and confirmations required.
    constructor(address[] memory _owners, uint _numConfirmationsRequired) {
        require(_owners.length > 1, "Owners Required Must Be Greater than 1");
        require(_numConfirmationsRequired > 0 && _numConfirmationsRequired <= _owners.length, "Num of confirmations are not in sync with the number of owners");

        for (uint i = 0; i < _owners.length; i++) {
            require(_owners[i] != address(0), "Invalid Owner");
            owners.push(_owners[i]);
        }
        numConfirmationsRequired = _numConfirmationsRequired;
    }

    // Function to submit a new transaction.
    function submitTransaction(address _to) public payable {
        require(_to != address(0), "Invalid Receiver's Address");
        require(msg.value > 0, "Transfer Amount Must Be Greater Than 0");
        uint transactionId = transactions.length;
        transactions.push(Transaction({to: _to, value: msg.value, executed: false}));
        emit TransactionSubmitted(transactionId, msg.sender, _to, msg.value);
    }

    // Function for an owner to confirm a transaction.
    function confirmTransaction(uint _transactionId) public {
        require(_transactionId < transactions.length, "Invalid Transaction Id");
        require(!isConfirmed[_transactionId][msg.sender], "Transaction Is Already Confirmed By The Owner");
        isConfirmed[_transactionId][msg.sender] = true;
        emit TransactionConfirmed(_transactionId);
        if (isTransactionConfirmed(_transactionId)) {
            executeTransaction(_transactionId);
        }
    }

    // Function to execute a confirmed transaction.
    function executeTransaction(uint _transactionId) public payable {
        require(_transactionId < transactions.length, "Invalid Transaction Id");
        require(!transactions[_transactionId].executed, "Transaction is already executed");
        (bool success, ) = transactions[_transactionId].to.call{value: transactions[_transactionId].value}("");
        require(success, "Transaction Execution Failed");
        transactions[_transactionId].executed = true;
        emit TransactionExecuted(_transactionId);
    }

    // Internal function to check if a transaction has enough confirmations to be executed.
    function isTransactionConfirmed(uint _transactionId) internal view returns (bool) {
        require(_transactionId < transactions.length, "Invalid Transaction Id");
        uint confirmationCount; // Initialize confirmation count to zero.

        for (uint i = 0; i < owners.length; i++) {
            if (isConfirmed[_transactionId][owners[i]]) {
                confirmationCount++;
            }
        }
        return confirmationCount >= numConfirmationsRequired;
    }
}
