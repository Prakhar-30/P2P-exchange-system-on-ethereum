// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract P2PExchange is ReentrancyGuard {
    struct Order {
        address maker;
        address tokenIn;
        address tokenOut;
        uint256 amountIn;
        uint256 amountOut;
        bool isBuyOrder;
    }


    mapping(uint256 => Order) public orders;
    uint256 public nextOrderId;

    mapping(address => mapping(address => uint256)) public userBalances;

    event OrderCreated(uint256 orderId, address maker, address tokenIn, address tokenOut, uint256 amountIn, uint256 amountOut, bool isBuyOrder);
    event OrderFulfilled(uint256 orderId, address taker, uint256 amountIn, uint256 amountOut);
    event Deposit(address user, address token, uint256 amount);
    event Withdrawal(address user, address token, uint256 amount);

    receive() external payable {
        userBalances[msg.sender][address(0)] += msg.value;
        emit Deposit(msg.sender, address(0), msg.value);
    }
    function withdrawEther(uint256 amount) external nonReentrant {
        require(userBalances[msg.sender][address(0)] >= amount, "Insufficient Ether balance");
        userBalances[msg.sender][address(0)] -= amount;
        payable(msg.sender).transfer(amount);
        emit Withdrawal(msg.sender, address(0), amount);
    }

    function depositToken(address token, uint256 amount) external {
        require(IERC20(token).transferFrom(msg.sender, address(this), amount), "Transfer failed");
        userBalances[msg.sender][token] += amount;
        emit Deposit(msg.sender, token, amount);
    }

    function withdrawToken(address token, uint256 amount) external nonReentrant {
        require(userBalances[msg.sender][token] >= amount, "Insufficient balance");
        userBalances[msg.sender][token] -= amount;
        require(IERC20(token).transfer(msg.sender, amount), "Transfer failed");
        emit Withdrawal(msg.sender, token, amount);
    }

    function createOrder(address tokenIn, address tokenOut, uint256 amountIn, uint256 amountOut, bool isBuyOrder) external {
        if (isBuyOrder) {
            require(userBalances[msg.sender][tokenOut] >= amountOut, "Insufficient balance for buy order");
            userBalances[msg.sender][tokenOut] -= amountOut;
        } else {
            require(userBalances[msg.sender][tokenIn] >= amountIn, "Insufficient balance for sell order");
            userBalances[msg.sender][tokenIn] -= amountIn;
        }

        orders[nextOrderId] = Order(msg.sender, tokenIn, tokenOut, amountIn, amountOut, isBuyOrder);
        emit OrderCreated(nextOrderId, msg.sender, tokenIn, tokenOut, amountIn, amountOut, isBuyOrder);
        nextOrderId++;
    }

    function fulfillOrder(uint256 orderId) external nonReentrant {
        Order storage order = orders[orderId];
        require(order.maker != address(0), "Order does not exist");
        require(order.maker != msg.sender, "Cannot fulfill own order");

        if (order.isBuyOrder) {
            require(userBalances[msg.sender][order.tokenIn] >= order.amountIn, "Insufficient balance to fulfill buy order");
            userBalances[msg.sender][order.tokenIn] -= order.amountIn;
            userBalances[order.maker][order.tokenIn] += order.amountIn;
            userBalances[msg.sender][order.tokenOut] += order.amountOut;
        } else {
            require(userBalances[msg.sender][order.tokenOut] >= order.amountOut, "Insufficient balance to fulfill sell order");
            userBalances[msg.sender][order.tokenOut] -= order.amountOut;
            userBalances[order.maker][order.tokenOut] += order.amountOut;
            userBalances[msg.sender][order.tokenIn] += order.amountIn;
        }

        emit OrderFulfilled(orderId, msg.sender, order.amountIn, order.amountOut);
        delete orders[orderId];
    }

    function getPrice(address tokenIn, address tokenOut, uint256 amountIn) public view returns (uint256) {
        uint256 reserveIn = IERC20(tokenIn).balanceOf(address(this));
        uint256 reserveOut = IERC20(tokenOut).balanceOf(address(this));
        return (amountIn * reserveOut) / (reserveIn + amountIn);
    }

    function swapToken(address tokenIn, address tokenOut, uint256 amountIn, uint256 minAmountOut) external nonReentrant {
        require(userBalances[msg.sender][tokenIn] >= amountIn, "Insufficient balance");
        uint256 amountOut = getPrice(tokenIn, tokenOut, amountIn);
        require(amountOut >= minAmountOut, "Insufficient output amount");

        userBalances[msg.sender][tokenIn] -= amountIn;
        userBalances[msg.sender][tokenOut] += amountOut;

        emit OrderFulfilled(type(uint256).max, msg.sender, amountIn, amountOut);
    }
        function swapEther(address tokenOut, uint256 minAmountOut) external payable nonReentrant {
        require(msg.value > 0, "Must send Ether");
        uint256 amountOut = getPrice(address(0), tokenOut, msg.value);
        require(amountOut >= minAmountOut, "Insufficient output amount");

        userBalances[msg.sender][address(0)] -= msg.value;
        userBalances[msg.sender][tokenOut] += amountOut;

        emit OrderFulfilled(type(uint256).max, msg.sender, msg.value, amountOut);
    }
}
