const Dai = artifacts.require('mocks/Dai.sol');
const Bat = artifacts.require('mocks/Bat.sol');
const Rep = artifacts.require('mocks/Rep.sol');
const Zrx = artifacts.require('mocks/Zrx.sol');
const Dex = artifacts.require('Dex.sol');

contract('Dex', (accounts) => {
    let dai, bat, rep, zrx;
    const [trader1, trader2] = [accounts[1], accounts[2]]
    const [DAI, BAT, REP, ZRX] = ['DAI', 'BAT', 'REP', 'ZRX'].map(val => web3.utils.fromAscii(val))

    beforeEach(async () => {
        [dai, bat, rep, zrx] = await Promise.all([
            Dai.new(),
            Bat.new(),
            Rep.new(),
            Zrx.new()
        ]);

        const dex = await Dex.new();
        dex.addToken(DAI, dai.address);
        dex.addToken(BAT, bat.address);
        dex.addToken(REP, rep.address);
        dex.addToken(ZRX, zrx.address);

        const amount = web3.utils.toWei('1000');
        const seedTokenBalance = async (trader, token) => {
            await token.faucet(trader, amount);
            await token.approve(
                dex.address,
                amount,
                {from: trader}
            );
        }

        [dai, bat, rep, zrx].map(token => seedTokenBalance(trader1, token)) // putting all supported tokens to the traders
        [dai, bat, rep, zrx].map(token => seedTokenBalance(trader2, token))
    })
})


