/* eslint-env node */
/* global artifacts */

const Beths = artifacts.require('Beths');

function deployContracts(deployer) {
  deployer.deploy(Beths);
}

module.exports = deployContracts;
