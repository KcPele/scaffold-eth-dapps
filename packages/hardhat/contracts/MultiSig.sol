// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

contract MultiSigWallet {
    event Deposit(address indexed sender, uint amount);
    event Submit(uint indexed txId);
    event Approve(address indexed owner, uint indexed txId);
    event Revoke(address indexed owner, uint indexed txId);
    event Execute(uint indexed txId);


    address contractOwner;
    struct Transaction {
        address to;
        uint value;
        bytes data;
        bool executed;
        uint required;
    }
    address[] public owners;

    mapping(address => bool) public isOwner;

    // uint public required;

    modifier onlyOwner () {
        require(isOwner[msg.sender], "not allowed");

        _;
    }
    modifier txExists(uint _txId){
        require(_txId < transactions.length, "tx does not exist");
        _;
    }
    modifier notApproved(uint _txId){
        require(!approve[_txId][msg.sender], "tx already approved");
        _;
    }

    modifier notExecuted(uint _txId) {
        require(!transactions[_txId].executed, "tx already excuted");
        _;
    }
    Transaction[] public transactions;
    //transaction uint, address of the owner
    mapping(uint => mapping(address => bool)) public approve;
    constructor(address _owner){
        owners.push(_owner);
        contractOwner = _owner;
        // require(_owners.length > 0, "owners requires");
        // require(_required > 0 && _required <= _owners.length,
        // "invalid required number os owner");
        // required = _required;
    }
    //add address to the multisig wallet;


    // adding multible owners
    function addMultiAddress(address[] calldata _owners) external {
         require(contractOwner == msg.sender, "only admin can excute. please contact admin");
         for(uint i; i < _owners.length; i++){
            address owner = _owners[i];
            require(owner != address(0), "invalid owner");
            require(!isOwner[owner], "owner is not unique");
            isOwner[owner] = true;
            
            
            owners.push(owner);
        }
    }

    //adding single owners
    function addAddress(address owner) external {
        require(owner != address(0), "invalid owner");
        require(!isOwner[owner], "owner is not unique");
        isOwner[owner] = true;
        owners.push(owner);

    }

    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }

    //creating a transaction
    function submit(address _to, uint _value, bytes calldata _data, uint _required)
    external onlyOwner {
                transactions.push(Transaction({
                    to: _to,
                    value: _value,
                    data: _data,
                    executed: false,
                    required: _required
                }));

                emit Submit(transactions.length -1);
    }

    function approved(uint _txId) external onlyOwner 
    txExists(_txId) notApproved(_txId) notExecuted(_txId)
    {
         approve[_txId][msg.sender] = true;
         emit Approve(msg.sender, _txId);
    }


    function _getApprovalCount(uint _txId) private view returns(uint count) {
        for(uint i; i < owners.length; i++) {
            if(approve[_txId][owners[i]]){
                count += 1;
            }
        }
    }
    function execute(uint _txId) external onlyOwner 
    txExists(_txId) notExecuted(_txId)
    {
         require(_getApprovalCount(_txId) >= transactions[_txId].required, "approvals < required");
         Transaction storage transactions = transactions[_txId];

         transactions.executed = true;
         (bool success, ) = transactions.to.call{value: transactions.value}(transactions.data);
         require(success, "tx failed");
         emit Execute(_txId);
    }

    function revoke(uint _txId) external onlyOwner 
    txExists(_txId) notExecuted(_txId)
    {
        require(approve[_txId][msg.sender], "tx not approved");
        approve[_txId][msg.sender] = false;
        emit Revoke(msg.sender, _txId);
    }

}