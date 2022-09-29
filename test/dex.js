const Dai = artifacts.require('mocks/Dai.sol');
const Bat = artifacts.require('mocks/Bat.sol');
const Rep = artifacts.require('mocks/Rep.sol');
const Zrx = artifacts.require('mocks/Zrx.sol');
const Dex = artifacts.require('Dex.sol');

contract('Dex', (accounts) => {
    console.log('1')
    let dai = {}, bat, rep, zrx, dex;
    const [trader1, trader2] = [accounts[1], accounts[2]]
    const [DAI, BAT, REP, ZRX] = ['DAI', 'BAT', 'REP', 'ZRX'].map(val => web3.utils.fromAscii(val))
    const admin = accounts[0];
    console.log('2')

    beforeEach(async () => {
        console.log('3');
        // dai = await Dai.new();
        // bat = await Bat.new();
        // rep = await Rep.new();
        // zrx = await Zrx.new();

        ([dai, bat, rep, zrx] = await Promise.all([
            Dai.new(),
            Bat.new(),
            Rep.new(),
            Zrx.new()
        ]));

        console.log('AA');

        dex = await Dex.new(admin);
        await Promise.all([
            dex.addToken(DAI, dai.address),
            dex.addToken(BAT, bat.address),
            dex.addToken(REP, rep.address),
            dex.addToken(ZRX, zrx.address),
        ]);

        console.log('4');
        const amount = web3.utils.toWei('1000');
        const seedTokenBalance = async (token, trader) => {
            await token.faucet(trader, amount);
            await token.approve(
                dex.address,
                amount,
                { from: trader }
            );
        };
        console.log('5');

        await Promise.all(
            [dai, bat, rep, zrx].map(
                token => seedTokenBalance(token, trader1)
            )
        );
        console.log(`trader2: ${trader2}`);
        await Promise.all(
            [dai, bat, rep, zrx].map(
                token => seedTokenBalance(token, trader2)
            )
        );

        done();
        console.log('7');
    });

    it('should deposit tokens', async () => {
        console.log('8')
        const amount = web3.utils.toWei('100');
        await dex.deposit(amount, DAI, { from: trader1 });
        const balance = await dex.traderBalances(trader1, DAI);

        assert(balance.toString() === amount);
    });
})


