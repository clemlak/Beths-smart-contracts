pragma solidity 0.5.8;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";


/**
 * @title An amazing project called Beths
 * @dev This contract is the base of our project
 */
contract Beths is Ownable {
    enum Status { Open, OnGoing, Disputed, Won, Lost }
    enum ProposedOutcome { Undefined, Won, Lost }

    struct Bet {
        Status status;
        address initiator;
        address responder;
        address mediator;
        uint256 amount;
        string currency;
        uint256 deadline;
        ProposedOutcome initiatorOutcome;
        ProposedOutcome responderOutcome;
        bool areFundsWithdrawn;
    }

    Bet[] public bets;

    mapping (uint256 => string[]) public betsToProofs;

    mapping (string => address) private supportedTokens;

    uint256 public ownerFee = 2;
    uint256 public mediatorFee = 2;

    function createBet(
        address responder,
        address mediator,
        uint256 amount,
        string memory currency,
        uint256 deadline
    ) public {
        require(
            supportedTokens[currency] != address(0),
            "Token is not supported"
        );

        IERC20 token = IERC20(supportedTokens[currency]);

        require(
            token.allowance(msg.sender, address(this)) >= amount,
            "Allowance is too low"
        );

        require(
            token.transferFrom(msg.sender, address(this), amount),
            "Transfer failed"
        );

        bets.push(
            Bet({
                status: Status.Open,
                initiator: msg.sender,
                responder: responder,
                mediator: mediator,
                amount: amount,
                currency: currency,
                deadline: deadline,
                initiatorOutcome: ProposedOutcome.Undefined,
                responderOutcome: ProposedOutcome.Undefined,
                areFundsWithdrawn: false
            })
        );
    }

    /*
    function joinBet(uint256 betId) public {
        require(
            bets[betId].status == Status.Open,
            "Bet is not open anymore"
        );

        require(
            bets[betId].responder == msg.sender,
            "You cannot join this bet"
        );

        IERC20 token = new IERC20(supportedTokens[bets[betId].currency]);

        require(
            token.allowance(msg.sender, address(this)) >= bets[betId].amount,
            "Allowance is too low"
        );

        require(
            token.transferFrom(msg.sender, address(this), bets[betId].amount),
            "Transfer failed"
        );

        bets[betId].status = Status.OnGoing;
    }

    function proposeOutcome(
        uint256 betId,
        ProposedOutcome proposedOutcome,
        string proof
    ) public {
        require(
            bets[betId].status == Status.OnGoing,
            "Bet is not on going"
        );

        require(
            msg.sender == bets[betId].initiator
            || msg.sender == bets[betId].responder,
            "Sender must be the initiator or the responder"
        );

        require(
            proposedOutcome == ProposedOutcome.Won
            || proposedOutcome == ProposedOutcome.Lost,
            "Proposed outcome is not valid"
        );

        if (proof.length > 0) {
            betsToProofs[betId].push(proof);
        }

        if (msg.sender == bets[betId].initiator) {
            bets[betId].initiatorOutcome = proposedOutcome;
        } else {
            bets[betId].responderOutcome = proposedOutcome;
        }

        if (bets[betId].initiatorOutcome == bets[betId].responderOutcome) {
            if (bets[betId].responderOutcome == ProposedOutcome.Won) {
                bets[betId].status = Status.Won;
            } else {
                bets[betId].status = Status.Lost;
            }
        }
    }

    function getFunds(uint256 betId) public {
        require(
            msg.sender == bets[betId].initiator
            || msg.sender == bets[betId].responder,
            "Sender must be the initiator or the responder"
        );

        require(
            bets[betId].status == Status.Won
            || bets[betId].status == Status.Lost,
            "Bet is not won or lost"
        );

        require(
            bets[betId].areFundsWithdrawn == false,
            "Funds were already withdrawn"
        );

        address receiver;

        if (bets[betId].status == Status.Won) {
            receiver = bets[betId].initiator;
        } else {
            receiver = bets[betId].responder;
        }

        IERC20 token = new IERC20(supportedTokens[bets[betId].currency]);

        uint256 fees = SafeMath.mul(
            bets[betId].amount / 100,
            fee
        );

        bets[betId].areFundsWithdrawn = true;

        require(
            token.transfer(receiver, SafeMath.sub(bets[betId].amount, fees)),
            "Transfer failed"
        );

        require(
            token.transfer(owner, fees),
            "Transfer failed"
        );
    }
    */
}
