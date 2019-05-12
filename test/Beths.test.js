/* eslint-env node, mocha */
/* global artifacts, contract, it, assert */

const TestToken = artifacts.require('TestToken');
const Beths = artifacts.require('Beths');

const Utils = require('web3-utils');

const {
  toSolidityTimestamp,
  Status,
  ProposedOutcome,
} = require('./utils');

let testToken;
let beths;

contract('Beths', (accounts) => {
  describe('Testing a won bet', () => {
    it('Should deploy an instance of the TestToken contract', () => TestToken.deployed()
      .then((instance) => {
        testToken = instance;
      }));

    it('Should deploy an instance of the Beths contract', () => Beths.deployed()
      .then((instance) => {
        beths = instance;
      }));

    it('Should send tokens to account 1', () => testToken.transfer(
      accounts[1],
      Utils.toWei('50'),
    ));

    it('Should send tokens to account 2', () => testToken.transfer(
      accounts[2],
      Utils.toWei('50'),
    ));

    it('Should allow the Beths contract to handle account 0 funds', () => testToken.approve(
      beths.address,
      Utils.toWei('50'), {
        from: accounts[1],
      },
    ));

    it('Should allow the Beths contract to handle account 1 funds', () => testToken.approve(
      beths.address,
      Utils.toWei('50'), {
        from: accounts[2],
      },
    ));

    it('Should create a new bet', () => beths.createBet(
      accounts[2],
      accounts[3],
      Utils.toWei('50'),
      testToken.address,
      toSolidityTimestamp(Date.now() + 1000 * 60 * 60), {
        from: accounts[1],
      },
    ));

    it('Should join a bet', () => beths.joinBet(0, {
      from: accounts[2],
    }));

    it('Should propose an outcome', () => beths.proposeOutcome(
      0,
      ProposedOutcome.Won,
      '', {
        from: accounts[1],
      },
    ));

    it('Should propose an outcome', () => beths.proposeOutcome(
      0,
      ProposedOutcome.Won,
      '',
      {
        from: accounts[2],
      },
    ));

    it('Should check the status of bet 0', () => beths.getBetStatus(0)
      .then((status) => {
        assert.equal(status, Status.Won);
      }));

    it('Should get the funds', () => beths.getFunds(0, {
      from: accounts[1],
    }));

    it('Should check the balance of account 1', () => testToken.balanceOf(accounts[1])
      .then((balance) => {
        assert.equal(balance.toString(), Utils.toWei('98'), 'Account 1 balance is wrong');
      }));

    it('Should check the balance of account 2', () => testToken.balanceOf(accounts[2])
      .then((balance) => {
        assert.equal(balance.toString(), Utils.toWei('0'), 'Account 2 balance is wrong');
      }));

    it('Should check the balance of account 3', () => testToken.balanceOf(accounts[3])
      .then((balance) => {
        assert.equal(balance.toString(), Utils.toWei('0'), 'Account 3 balance is wrong');
      }));

    it('Should check the balance of account 0', () => testToken.balanceOf(accounts[0])
      .then((balance) => {
        const expectedBalance = 1000000 - 100 + 2;
        assert.equal(balance.toString(), Utils.toWei(expectedBalance.toString()), 'Account 0 balance is wrong');
      }));
  });
});
