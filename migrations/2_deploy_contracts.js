/* eslint-env node */
/* global artifacts */

const UsernameManager = artifacts.require('UsernameManager');
const Beths = artifacts.require('Beths');
const TestToken = artifacts.require('TestToken');

function deployContracts(deployer, network) {
  if (network === 'development') {
    deployer.deploy(TestToken)
      .then(() => deployer.deploy(UsernameManager))
      .then(() => deployer.deploy(Beths));
  } else {
    deployer.deploy(Beths);
  }
}

module.exports = deployContracts;
