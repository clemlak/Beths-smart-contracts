/* eslint-env node, mocha */
/* global artifacts, contract, it, assert */

const UsernameManager = artifacts.require('UsernameManager');

let um;

contract('UsernameManager', (accounts) => {
  it('Should deploy an instance of the UsernameManager contract', () => UsernameManager.deployed()
    .then((instance) => {
      um = instance;
    }));

  it('Should claim the username Jasper for account 0', () => um.claimUsername('Jasper'));

  it('Should get the address of the username Jasper', () => um.getAddressFromUsername('Jasper')
    .then((address) => {
      assert.equal(address, accounts[0], 'Address is wrong');
    }));

  it('Should claim the username Bob for account 1', () => um.claimUsername('Bob', {
    from: accounts[1],
  }));

  it('Should get the address of the username Bob', () => um.getAddressFromUsername('Bob')
    .then((address) => {
      assert.equal(address, accounts[1], 'Address is wrong');
    }));
});
