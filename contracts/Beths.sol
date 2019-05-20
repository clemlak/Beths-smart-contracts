pragma solidity 0.5.8;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "./UsernameManager.sol";


/**
 * @title An amazing project called Beths
 * @dev This contract is the base of our project
 */
contract Beths is Ownable, UsernameManager {
    enum Status { Open, OnGoing, Disputed, Won, Lost, Exited, Canceled }
    enum ProposedOutcome { Undefined, Won, Lost }

    struct Bet {
        Status status;
        address initiator;
        address opponent;
        address mediator;
        uint256 amount;
        address currency;
        uint256 deadline;
        ProposedOutcome initiatorOutcome;
        ProposedOutcome opponentOutcome;
        bool areFundsWithdrawn;
        bool hasBeenDisputed;
    }

    Bet[] public bets;

    mapping (uint256 => string[]) public betsToProofs;

    uint256 public ownerFee = 2;
    uint256 public mediatorFee = 2;

    event BetCreated(
        uint256 betId,
        address indexed initiator,
        address indexed opponent
    );

    /**
     * @dev Updates the fee rewarding the owner
     * @param newOwnerFee The % of the new fee
     */
    function updateOwnerFee(uint256 newOwnerFee) external onlyOwner() {
        ownerFee = newOwnerFee;
    }

    /**
     * @dev Updates the fee rewarding the mediator
     * @param newMediatorFee The % of the new mediator
     */
    function updateMediatorFee(uint256 newMediatorFee) external onlyOwner() {
        mediatorFee = newMediatorFee;
    }

    /**
     * @dev Creates a new bet
     * @param opponent The address of the opponent
     * @param mediator The address of the mediator
     * @param amount The amount required by both parties
     * @param currency The address of the currency used
     * @param deadline The deadline to enter the bet and reply
     */
    function createBet(
        address opponent,
        address mediator,
        uint256 amount,
        address currency,
        uint256 deadline
    ) external {
        IERC20 token = IERC20(currency);

        require(
            token.allowance(msg.sender, address(this)) >= amount,
            "Allowance is too low"
        );

        require(
            token.transferFrom(msg.sender, address(this), amount),
            "Transfer failed"
        );

        uint256 betId = bets.push(
            Bet({
                status: Status.Open,
                initiator: msg.sender,
                opponent: opponent,
                mediator: mediator,
                amount: amount,
                currency: currency,
                deadline: deadline,
                initiatorOutcome: ProposedOutcome.Undefined,
                opponentOutcome: ProposedOutcome.Undefined,
                areFundsWithdrawn: false,
                hasBeenDisputed: false
            })
        ) - 1;

        emit BetCreated(betId, msg.sender, opponent);
    }

    /**
     * @dev Joins a bet
     * @param betId The id of the bet to join
     */
    function joinBet(uint256 betId) external {
        require(
            bets[betId].status == Status.Open,
            "Bet is not open anymore"
        );

        require(
            bets[betId].deadline > now,
            "Deadline has already been reached"
        );

        require(
            bets[betId].opponent == msg.sender,
            "You cannot join this bet"
        );

        IERC20 token = IERC20(bets[betId].currency);

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

    /**
     * @dev Proposes an outcome for a given bet
     * @param betId The id of a bet
     * @param proposedOutcome The proposed outcome
     * @param proof The url of a proof
     */
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
            || msg.sender == bets[betId].opponent,
            "Sender must be the initiator or the opponent"
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
            bets[betId].opponentOutcome = proposedOutcome;
        }

        if (bets[betId].initiatorOutcome != ProposedOutcome.Undefined
            && bets[betId].opponentOutcome != ProposedOutcome.Undefined
        ) {
            if (bets[betId].initiatorOutcome == bets[betId].opponentOutcome) {
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

    /**
     * @dev Gets the funds from a won bet
     * @param betId The id of the bet
     */
    /* solhint-disable-next-line function-max-lines */
    function getFunds(uint256 betId) external {
        require(
            msg.sender == bets[betId].initiator
            || msg.sender == bets[betId].opponent,
            "Sender must be the initiator or the opponent"
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
            receiver = bets[betId].opponent;
        }

        IERC20 token = IERC20(bets[betId].currency);

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

    /**
     * @dev Cancels a bet
     * @param betId The id of a bet
     */
    function cancelBet(uint256 betId) external {
        require(
            msg.sender == bets[betId].initiator,
            "Sender must be the initiator"
        );

        require(
            bets[betId].deadline < now,
            "Deadline has not been reached"
        );

        require(
            bets[betId].status == Status.Open,
            "Bet is not open anymore"
        );

        IERC20 token = IERC20(bets[betId].currency);

        bets[betId].status = Status.Canceled;

        require(
            token.transfer(bets[betId].initiator, bets[betId].amount),
            "Transfer failed"
        );
    }

    /**
     * @dev Exists a bet
     * @param betId The id of a bet
     */
    function exitBet(uint256 betId) external {
        require(
            msg.sender == bets[betId].initiator
            || msg.sender == bets[betId].opponent,
            "Sender must be the initiator or the opponent"
        );

        require(
            bets[betId].deadline < now,
            "Deadline has not been reached"
        );

        address receiver;

        if (msg.sender == bets[betId].initiator) {
            require(
                bets[betId].opponentOutcome == ProposedOutcome.Undefined,
                "Opponent has proposed an outcome"
            );

            receiver = bets[betId].initiator;
        } else if (msg.sender == bets[betId].opponent) {
            require(
                bets[betId].initiatorOutcome == ProposedOutcome.Undefined,
                "Initiator has proposed an outcome"
            );

            receiver = bets[betId].initiator;
        }

        IERC20 token = IERC20(bets[betId].currency);

        uint256 totalAmount = SafeMath.mul(bets[betId].amount, 2);

        uint256 ownerFees = SafeMath.mul(
            totalAmount / 100,
            ownerFee
        );

        bets[betId].status = Status.Exited;

        require(
            token.transfer(receiver, SafeMath.sub(totalAmount, ownerFees)),
            "Transfer failed"
        );

        require(
            token.transfer(owner(), ownerFees),
            "Transfer failed"
        );
    }

    /**
     * @dev Solves a dispute
     * @param betId The id of a bet
     * @param outcome The outcome of the bet
     */
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

    /**
     * @dev Gets the status of a bet
     * @param betId The id of a bet
     * @return The status of the bet
     */
    function getBetStatus(uint256 betId) external view returns (
        Status status
    ) {
        return bets[betId].status;
    }

    /**
     * @dev Gets info about a bet
     * @param betId The id of a bet
     * @return Some info about the bet
     */
    function getBetInfo(uint256 betId) external view returns (
        address,
        address,
        address,
        uint256,
        address,
        uint256
    ) {
        return (
            bets[betId].initiator,
            bets[betId].opponent,
            bets[betId].mediator,
            bets[betId].amount,
            bets[betId].currency,
            bets[betId].deadline
        );
    }

    /**
     * @dev Gets the outcomes proposed by both parties
     * @param betId The id of a bet
     * @return The outcomes proposed by both parties and if the bet has been disputed
     */
    function getBetOutcome(uint256 betId) external view returns (
        ProposedOutcome,
        ProposedOutcome,
        bool
    ) {
        return (
            bets[betId].initiatorOutcome,
            bets[betId].opponentOutcome,
            bets[betId].hasBeenDisputed
        );
    }

    /**
     * @dev Checks if the funds have been withdrawn yet
     * @param betId The id of a bet
     * @return True if the funds have been withdrawn
     */
    function areFundsWithdrawn(uint256 betId) external view returns (
        bool
    ) {
        return bets[betId].areFundsWithdrawn;
    }
}
