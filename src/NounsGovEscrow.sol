// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {IERC721 as ERC721} from "openzeppelin/token/ERC721/IERC721.sol";
import {Ownable} from "openzeppelin/access/Ownable.sol";

interface ENSResolver {
    function setName(string memory) external returns (bytes32);
}

interface NounsGovernor {
    function castRefundableVoteWithReason(uint256 pId, uint8 support, string calldata reason) external;
}

contract NounsGovEscrow is Ownable {
    address public constant NOUNS_DAO = 0x6f3E6272A167e8AcCb32072d08E0957F9c79223d;
    address public constant NOUNS_TIMELOCK = 0xb1a32FC9F9D8b2cf86C068Cae13108809547ef71;
    address public constant NOUNS_TOKEN = 0x9C8fF314C9Bc7F6e59A9d9225Fb22946427eDC03;

    uint256 public votes;
    uint256 public voteThreshold;
    uint256 public maturity;
    address public receiver;

    error ThresholdNotReached();
    error MaturityNotReached();
    error CannotClawback();
    error OnlyReceiver();

    modifier onlyReceiver() {
        if (msg.sender != receiver) {
            revert OnlyReceiver();
        }

        _;
    }

    /// initialize the contract with vote threshold, maturity time, and
    /// the token receiver. nouns is automatically set as the owner
    constructor(uint256 _voteThreshold, uint256 _daysToMature, address _receiver) Ownable(NOUNS_TIMELOCK) {
        voteThreshold = _voteThreshold;
        receiver = _receiver;

        uint256 _maturity = 1 days * _daysToMature;
        maturity = block.timestamp + _maturity;
    }

    /// cast a vote on a proposal
    function castVote(uint256 _pId, uint8 _support, string calldata _reason) external onlyReceiver {
        NounsGovernor(NOUNS_DAO).castRefundableVoteWithReason(_pId, _support, _reason);
        votes += 1;
    }

    /// claim a noun owned by this contract once the vote threshold and maturity
    /// time is reached
    function claimNoun(uint256 _tId) external {
        if (votes < voteThreshold) {
            revert ThresholdNotReached();
        }

        if (block.timestamp < maturity) {
            revert MaturityNotReached();
        }

        ERC721(NOUNS_TOKEN).transferFrom(address(this), receiver, _tId);
    }

    /// set an ENS reverse record for this contract
    function setENS(address _resolver, string calldata _name) external onlyReceiver {
        ENSResolver(_resolver).setName(_name);
    }

    /// the owner can clawback a token from this contract for any reason if
    /// threshold / maturity is not already reached
    function clawBack(uint256 _tId) external onlyOwner {
        if (votes >= voteThreshold && block.timestamp >= maturity) {
            revert CannotClawback();
        }

        ERC721(NOUNS_TOKEN).transferFrom(address(this), NOUNS_TIMELOCK, _tId);
    }
}
