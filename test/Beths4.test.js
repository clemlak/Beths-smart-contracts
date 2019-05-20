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
  describe('Testing cancelable bet', () => {
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

    it('Should allow the Beths contract to handle account 0 funds', () => testToken.approve(
      beths.address,
      Utils.toWei('50'), {
        from: accounts[1],
      },
    ));

    it('Should create a new bet', () => beths.createBet(
      accounts[2],
      accounts[3],
      Utils.toWei('50'),
      testToken.address,
      toSolidityTimestamp(Date.now() - 60 * 60 * 24), {
        from: accounts[1],
      },
    ));

    it('Should check the status of bet 0', () => beths.getBetStatus(0)
      .then((status) => {
        assert.equal(status, Status.Open);
      }));

    it('Should cancel a bet', () => beths.cancelBet(0, {
      from: accounts[1],
    }));

    it('Should check the status of bet 0', () => beths.getBetStatus(0)
      .then((status) => {
        assert.equal(status.toNumber(), Status.Canceled);
      }));

    it('Should check the balance of account 1', () => testToken.balanceOf(accounts[1])
      .then((balance) => {
        assert.equal(balance.toString(), Utils.toWei('50'), 'Account 1 balance is wrong');
      }));
  });
});
