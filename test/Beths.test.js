/* eslint-env node, mocha */
/* global artifacts, contract, it, assert */

const TestToken = artifacts.require('TestToken');
const Beths = artifacts.require('Beths');

let testToken;
let beths;

contract('Beths', (accounts) => {
  it('Should deploy an instance of the TestToken contract', () => TestToken.deployed()
    .then((instance) => {
      testToken = instance;
    }));

  it('Should deploy an instance of the Beths contract', () => Beths.deployed()
    .then((instance) => {
      beths = instance;
    }));
});
