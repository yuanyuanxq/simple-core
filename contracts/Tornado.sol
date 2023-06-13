//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./MerkleTree.sol";

interface IVerifier {
    function verifyProof(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[1] memory input
    ) external view returns (bool r);
}

abstract contract Tornado is MerkleTree, ReentrancyGuard {
    uint256 public denomination;
    mapping(bytes32 => bool) public nullifierHashes;
    // we store all commitments just to prevent accidental deposits with the same commitment
    mapping(bytes32 => bool) public commitments;
    IVerifier public verifier;

    event Deposit(bytes32 indexed commitments, uint32 leafIndex, uint256 timestamp);
    event Withdrawal(address to, bytes32 nullifierHashes, address indexed relayer, uint256 fee);

    constructor(
        IVerifier _verifier,
        uint256 _denomination,
        uint32 _merkleTreeHieght,
        Hasher _hasher
    ) MerkleTree(_merkleTreeHieght, _hasher) {
        require(_denomination > 0, "denomination should be greater than zero");
        verifier = _verifier;
        denomination = _denomination;
    }

    function deposit(bytes32 _commitment) public payable nonReentrant {
        require(!commitments[_commitment], "The commitment has been submitted");

        uint32 insertedIndex = _insert(_commitment);
        commitments[_commitment] = true;
        _processDeposit();

        emit Deposit(_commitment, insertedIndex, block.timestamp);
    }

    function _processDeposit() internal virtual;

    function withdraw(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[1] memory input,
        bytes32 _root,
        bytes32 _nullifierHash,
        address payable _recipient,
        address payable _relayer,
        uint256 _fee,
        uint256 _refund
    ) external payable nonReentrant {
        require(_fee <= denomination, "Fee exceeds transfer value");
        require(!nullifierHashes[_nullifierHash], "The note has been already spent");
        require(isKnownRoot(_root), "Cannot find your merkle root");
        require(verifier.verifyProof(a, b, c, input), "Invalid withdraw proof");

        nullifierHashes[_nullifierHash] = true;
        _processWithdraw(_recipient, _relayer, _fee, _refund);

        emit Withdrawal(_recipient, _nullifierHash, _relayer, _fee);
    }

    function _processWithdraw(
        address payable _recipient,
        address payable _relayer,
        uint256 _fee,
        uint256 _refund
    ) internal virtual;

    function isSpent(bytes32 _nullifierHash) public view returns (bool) {
        return nullifierHashes[_nullifierHash];
    }
}
