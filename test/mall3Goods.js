const Mall3Goods = artifacts.require("Mall3Goods");
const Web3 = require("web3");
const web3 = new Web3(new Web3.providers.HttpProvider("http://localhost:8545"));

contract("Mall3Goods", (accounts) => {
  it("buy", async () => {
    const mall3GoodsInstance = await Mall3Goods.deployed(accounts[1], [1, 5, 7], 9999999999);
    await mall3GoodsInstance.buy.call(1, { value: 9999999999 * 10 ** 9 });

    let buyerBalanceStr = await web3.eth.getBalance(accounts[0]);
    let buyerBalance = web3.utils.fromWei(buyerBalanceStr);
    assert.isBelow(parseFloat(buyerBalance), 990);

    let sellerBalanceStr = await web3.eth.getBalance(accounts[1]);
    let sellerBalance = web3.utils.fromWei(sellerBalanceStr);
    assert.isAbove(parseFloat(sellerBalance), 1009);
  });
});
