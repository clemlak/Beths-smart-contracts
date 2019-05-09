# Beths

## Casual bets with your friends!

### Introduction

Beths was originally created in 2018 to manage bets during the World Cup. But today, the goal of this new version is to manage any kind of "casual bets", for example the ones you make with your friends!


### How does it work?

The concept is pretty simple! Anyone can create a bet by specifying:
* A description
* An opponent
* An amount and a currency (several ERC20 tokens are supported)
* A mediator, that will solve any kind of dispute regarding the result
* A deadline

When an user creates a bet, the amount he specified will be transferred and locked into the smart-contract.

Once the bet has been created, the opponent can join it by transferring his funds to the smart-contract.

Later, users can propose an outcome (won or lost) and attach a **proof** to verify the result. If both outcomes are the same, the bet will be closed and the winner will be able to claim his reward.
If the outcomes are different, the bet will be marked as **disputed**. The mediator will be able to check the proofs linked to the bet and solve the dispute by choosing the outcome. The bet will be then closed and the winner will be able to claim his reward.

*Note: The smart-contract takes a 2% fee on the rewards, and an additional 2% fee will be applied if a mediator has been involved in the bet.*

### Features

To enhance the user experience, a few features has been added to the smart-contract:
* Usernames: anyone can claim an username and link it to his address
* ERC20 tokens: bets can be made using several ERC20 tokens
