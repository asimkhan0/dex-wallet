const Dex = artifacts.require('Dex');

module.exports = function (deployer, x, address) {
    deployer.deploy(Dex, address[0]);
}