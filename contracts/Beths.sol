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
        bool hasBeenDisputed;
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
        string calldata currency,
        uint256 deadline
    ) external {
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
                areFundsWithdrawn: false,
                hasBeenDisputed: false
            })
        );
    }

    function addCurrency(string calldata symbol, address tokenAddress) external onlyOwner() {
        supportedTokens[symbol] = tokenAddress;
    }

    function joinBet(uint256 betId) external {
        require(
            bets[betId].status == Status.Open,
            "Bet is not open anymore"
        );

        require(
            bets[betId].responder == msg.sender,
            "You cannot join this bet"
        );

        IERC20 token = IERC20(supportedTokens[bets[betId].currency]);

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
        string calldata proof
    ) external {
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

        betsToProofs[betId].push(proof);

        if (msg.sender == bets[betId].initiator) {
            bets[betId].initiatorOutcome = proposedOutcome;
        } else {
            bets[betId].responderOutcome = proposedOutcome;
        }

        if (bets[betId].initiatorOutcome != ProposedOutcome.Undefined
            && bets[betId].responderOutcome != ProposedOutcome.Undefined
        ) {
            if (bets[betId].initiatorOutcome == bets[betId].responderOutcome) {
                if (bets[betId].initiatorOutcome == ProposedOutcome.Won) {
                    bets[betId].status = Status.Won;
                } else {
                    bets[betId].status = Status.Lost;
                }
            } else {
                bets[betId].status = Status.Disputed;
            }
        }
    }

    /* solhint-disable-next-line function-max-lines */
    function getFunds(uint256 betId) external {
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

        IERC20 token = IERC20(supportedTokens[bets[betId].currency]);

        uint256 totalAmount = SafeMath.mul(bets[betId].amount, 2);

        uint256 ownerFees = SafeMath.mul(
            totalAmount / 100,
            ownerFee
        );

        bets[betId].areFundsWithdrawn = true;

        uint256 mediatorFees = 0;

        if (bets[betId].hasBeenDisputed) {
            mediatorFees = SafeMath.mul(
                totalAmount / 100,
                mediatorFee
            );

            require(
                token.transfer(bets[betId].mediator, mediatorFees),
                "Transfer failed"
            );
        }

        require(
            token.transfer(receiver, SafeMath.sub(totalAmount, SafeMath.add(ownerFees, mediatorFees))),
            "Transfer failed"
        );

        require(
            token.transfer(owner(), ownerFees),
            "Transfer failed"
        );
    }

    function solveDispute(uint256 betId, Status outcome) external {
        require(
            msg.sender == bets[betId].mediator,
            "Sender must be the mediator"
        );

        require(
            bets[betId].status == Status.Disputed,
            "Bet is not disputed"
        );

        require(
            outcome == Status.Won
            || outcome == Status.Lost,
            "Outcome must be won or lost"
        );

        bets[betId].status = outcome;
        bets[betId].hasBeenDisputed = true;
    }

    function getBetStatus(uint256 betId) external view returns (
        Status status
    ) {
        return bets[betId].status;
    }

    function getBetInfo(uint256 betId) external view returns (
        address,
        address,
        address,
        uint256,
        string memory,
        uint256
    ) {
        return (
            bets[betId].initiator,
            bets[betId].responder,
            bets[betId].mediator,
            bets[betId].amount,
            bets[betId].currency,
            bets[betId].deadline
        );
    }

    function getBetOutcome(uint256 betId) external view returns (
        ProposedOutcome,
        ProposedOutcome,
        bool
    ) {
        return (
            bets[betId].initiatorOutcome,
            bets[betId].responderOutcome,
            bets[betId].hasBeenDisputed
        );
    }

    function areFundsWithdrawn(uint256 betId) external view returns (
        bool
    ) {
        return bets[betId].areFundsWithdrawn;
    }
}
