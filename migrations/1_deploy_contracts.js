const Mall3Goods = artifacts.require("Mall3Goods");
const web3 = require("web3");

module.exports = async function (deployer) {
  // let accounts = await web3.eth.getAccounts();
  deployer.deploy(Mall3Goods, "0x0552D2bB70Fe94eB820Adc558E21E48a264597D1", [1, 5, 7], 9999999999);
};
