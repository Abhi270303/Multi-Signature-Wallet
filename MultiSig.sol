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

    // Mapping to track if an owner has confirmed a transaction.
    // The first mapping maps transaction IDs to the second mapping, which maps addresses to booleans.
    mapping(uint => mapping(address => bool)) isConfirmed;
    
    // An array to store pending transactions.
    Transaction[] public transactions;

    // Events for logging important contract actions.
    event TransactionSubmitted(uint transactionId, address sender, address receiver, uint amount);
    event TransactionConfirmed(uint transactionId);
    event TransactionExecuted(uint transactionId);

    // Constructor to initialize the contract with owners and confirmations required.
    constructor(address[] memory _owners, uint _numConfirmationsRequired) {
        // Ensure that there are at least 2 owners and numConfirmationsRequired is within bounds.
        require(_owners.length > 1, "Owners Required Must Be Greater than 1");
        require(_numConfirmationsRequired > 0 && _numConfirmationsRequired <= _owners.length, "Num of confirmations are not in sync with the number of owners");

        // Initialize the owners array with the provided addresses.
        for (uint i = 0; i < _owners.length; i++) {
            require(_owners[i] != address(0), "Invalid Owner");
            owners.push(_owners[i]);
        }

        // Set the required number of confirmations.
        numConfirmationsRequired = _numConfirmationsRequired;
    }

    // Function to submit a new transaction.
    function submitTransaction(address _to) public payable {
        // Ensure the receiver's address is valid and the transfer amount is greater than 0.
        require(_to != address(0), "Invalid Receiver's Address");
        require(msg.value > 0, "Transfer Amount Must Be Greater Than 0");

        // Create a new transaction and add it to the transactions array.
        uint transactionId = transactions.length;
        transactions.push(Transaction({to: _to, value: msg.value, executed: false}));

        // Emit an event to log the submission of the transaction.
        emit TransactionSubmitted(transactionId, msg.sender, _to, msg.value);
    }

    // Function for an owner to confirm a transaction.
    function confirmTransaction(uint _transactionId) public {
        // Ensure the provided transaction ID is valid.
        require(_transactionId < transactions.length, "Invalid Transaction Id");
        require(!isConfirmed[_transactionId][msg.sender], "Transaction Is Already Confirmed By The Owner");

        // Mark the transaction as confirmed by the sender.
        isConfirmed[_transactionId][msg.sender] = true;

        // Emit an event to log the confirmation of the transaction.
        emit TransactionConfirmed(_transactionId);

        // If enough confirmations are received, execute the transaction.
        if (isTransactionConfirmed(_transactionId)) {
            executeTransaction(_transactionId);
        }
    }

    // Function to execute a confirmed transaction.
    function executeTransaction(uint _transactionId) public payable {
        // Ensure the provided transaction ID is valid and the transaction hasn't been executed already.
        require(_transactionId < transactions.length, "Invalid Transaction Id");
        require(!transactions[_transactionId].executed, "Transaction is already executed");

        // Execute the transaction by sending the specified value to the specified address.
        (bool success, ) = transactions[_transactionId].to.call{value: transactions[_transactionId].value}("");
        require(success, "Transaction Execution Failed");

        // Mark the transaction as executed.
        transactions[_transactionId].executed = true;

        // Emit an event to log the execution of the transaction.
        emit TransactionExecuted(_transactionId);
    }

    // Internal function to check if a transaction has enough confirmations to be executed.
    function isTransactionConfirmed(uint _transactionId) internal view returns (bool) {
        // Ensure the provided transaction ID is valid.
        require(_transactionId < transactions.length, "Invalid Transaction Id");
        uint confirmationCount; // Initialize confirmation count to zero.

        // Count the number of confirmations for the transaction.
        for (uint i = 0; i < owners.length; i++) {
            if (isConfirmed[_transactionId][owners[i]]) {
                confirmationCount++;
            }
        }

        // Check if the required number of confirmations is met.
        return confirmationCount >= numConfirmationsRequired;
    }
}
