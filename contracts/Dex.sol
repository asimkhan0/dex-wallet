// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Dex {
    struct Token {
        bytes32 ticker;
        address tokenAddress;
    }

    mapping(bytes32 => Token) public tokens;
    mapping(address => mapping(bytes32 => uint)) traderBalances;
    bytes32[] public tokensList;

    address public admin;

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

    modifier tokenExist (bytes32 ticker) {
        require(tokens[ticker].tokenAddress != address(0), 'token is not supported');
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, 'only admin');
        _;
    }
}