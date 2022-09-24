// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Dex {
    enum Side {
        BUY,
        SELL
    }

    struct Token {
        bytes32 ticker;
        address tokenAddress;
    }

    struct Order {
        uint id;
        address trader;
        Side side;
        bytes32 ticker;
        uint amount;
        uint filled;
        uint price;
        uint date;
    }

    mapping(bytes32 => Token) public tokens;
    mapping(address => mapping(bytes32 => uint)) traderBalances;
    mapping(bytes32 => mapping(uint => Order[])) orderBook; // uint 0/1 for Side, should replace uint with some smaller uint8 probably
    bytes32[] public tokensList;

    address public admin;
    uint public nextOrderId;
    uint public nextTradeId;

    bytes32 constant DAI = bytes32('DAI');

    event NewTrade(
        uint tradeId,
        uint orderId,
        bytes32 indexed ticker,
        address indexed trader1,
        address indexed trader2,
        uint amount,
        uint price,
        uint date
    );

    constructor (address _admin) {
        admin = _admin;
    }

    function addToken(bytes32 ticker, address tokenAddress) onlyAdmin external {
        tokens[ticker] = Token(ticker, tokenAddress);
        tokensList.push(ticker);
    }

    function deposit(uint amount, bytes32 ticker) tokenExist(ticker) external {
        // transferFrom needs an approval -> from UI
        IERC20(tokens[ticker].tokenAddress).transferFrom(
            msg.sender,
            address(this),
            amount
        );

        traderBalances[msg.sender][ticker] += amount;
    }

    function withdraw (uint amount, bytes32 ticker) tokenExist(ticker) external {
        require(traderBalances[msg.sender][ticker] >= amount, 'not enough balance');
        traderBalances[msg.sender][ticker] -= amount;

        IERC20(tokens[ticker].tokenAddress).transfer(msg.sender, amount);
    }

    function createLimitOrder(
        bytes32 ticker,
        uint amount,
        uint price,
        Side side
    ) tokenExist(ticker) tokenIsNotDai(ticker) external {
        
        if (side == Side.SELL) {
            require(traderBalances[msg.sender][ticker] >= amount, 'token balance too low');

        } else {
            require(traderBalances[msg.sender][DAI] >= amount * price, 'DAI balance too low');
        }

        Order[] storage orders = orderBook[ticker][uint(side)];

        orders.push(Order(
            nextOrderId,
            msg.sender,
            side,
            ticker,
            amount,
            0,
            price,
            block.timestamp
        ));

        uint i = orders.length - 1;

        while (i > 0) {
            if(side == Side.SELL  && orders[i - 1].price > orders[i].price) {
                break;
            }
            if(side == Side.SELL && orders[i - 1].price < orders[i].price) {
                break;
            }

            Order memory order = orders[i - 1];
            orders[i - 1] = orders[i];
            orders[i] = order;

            i--;
        }
        nextOrderId++;
    }

    function createMarketOrder(
        bytes32 ticker,
        uint amount,
        Side side
    ) 
    tokenExist(ticker)
    tokenIsNotDai(ticker)
    external {
        if(side == Side.SELL) {
            require(traderBalances[msg.sender][ticker] >= amount, 'token balance too low');
        }
        // BUY: [1,2,3,4,5]
        //SELL: [5,4,3,2,1]
        Order[] storage orders = orderBook[ticker][uint(side == Side.SELL ? Side.BUY : Side.SELL)];
        uint i;
        uint remaining = amount;
        while(i < orders.length && remaining > 0) {
            uint available = orders[i].amount - orders[i].filled;   
            uint matched = available > remaining ? remaining : available;
            remaining -= matched;

            emit NewTrade(nextTradeId, orders[i].id, ticker, orders[i].trader, msg.sender, matched, orders[i].price, block.timestamp);
            
            if(side == Side.SELL) {
                traderBalances[msg.sender][ticker] -= matched;
                traderBalances[msg.sender][DAI] += matched * orders[i].price;
                traderBalances[orders[i].trader][ticker] += matched;
                traderBalances[orders[i].trader][DAI] -= matched * orders[i].price;
            } else {
                require(traderBalances[msg.sender][DAI] >= matched * orders[i].price, 'DAI balance too low');
                traderBalances[msg.sender][ticker] += matched;
                traderBalances[msg.sender][DAI] -= matched * orders[i].price;
                traderBalances[orders[i].trader][ticker] -= matched;
                traderBalances[orders[i].trader][DAI] += matched * orders[i].price;
            }
            nextTradeId++;
            i++;
        }

        i = 0;
        while(i < orders.length && orders[i].filled == orders[i].amount) {
            for (uint j = i; j < orders.length - 1; j++) {
                orders[j] = orders[j + 1];
            }
            orders.pop();
            i++;
        }
    }

    modifier tokenIsNotDai (bytes32 ticker) {
        require(ticker != DAI, 'cannot trade DAI');
        _;
    }

    modifier tokenExist (bytes32 ticker) {
        require(tokens[ticker].tokenAddress != address(0), 'token is not supported');
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, 'only admin');
        _;
    }
}