const Dai = artifacts.require('mocks/Dai');

module.exports = function (deployer) {
    deployer.deploy(Dai);
}