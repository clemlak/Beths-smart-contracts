/* eslint-env node */
/* global artifacts */

const Beths = artifacts.require('Beths');
const TestToken = artifacts.require('TestToken');

function deployContracts(deployer) {
  deployer.deploy(TestToken);
  deployer.deploy(Beths);
}

module.exports = deployContracts;
