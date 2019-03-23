const NFDNS = artifacts.require("NFDNS");

module.exports = function(deployer) {
    deployer.deploy(NFDNS);
};