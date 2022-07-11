//SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.2;

import "https://github.com/pancakeswap/pancake-swap-periphery/blob/master/contracts/interfaces/IPancakeRouter01.sol";
import "https://github.com/pancakeswap/pancake-swap-periphery/blob/master/contracts/interfaces/IERC20.sol";

contract MyContract {
    mapping (address => bool ) private isWalletsAllowed;
    mapping (uint => address ) private wallets;
    address constant PANCAKE_ROUTER_ADDRESS = 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3;
    IPancakeRouter01 public pancakeRouter;
    address private _owner;
    address public contractAddress;
    uint walletsCount;

   constructor() {
        _owner = msg.sender;
        contractAddress = address(this);
        pancakeRouter = IPancakeRouter01(PANCAKE_ROUTER_ADDRESS);

        wallets[walletsCount] = 0xF06b13E53008fAd5A07409C32C20b2a8fE79DBef;
        walletsCount++;
        isWalletsAllowed[0xF06b13E53008fAd5A07409C32C20b2a8fE79DBef] = true;
   }

   receive() external payable {

   }

    modifier onlyOwner(){
        require(msg.sender == _owner, "You are not owner");
        _;
    }


    modifier onlyAllowedWallets(){
        require(isWalletsAllowed[msg.sender], "You are not allowed wallet");
        _;
    }


    function getAllWallets() public view onlyOwner returns (address[] memory){
        address[] memory allWallets = new address[](walletsCount);
        for (uint i = 0; i < walletsCount; i++) {
            allWallets[i] = wallets[i];
        }
        return allWallets;
    }

    function addNewAllowedWallet(address _address) public onlyOwner {
            wallets[walletsCount] = _address;
            walletsCount++;
            isWalletsAllowed[_address] = true;
    } 

    function sendCustomToken(address recipient, address token, uint256 amount) public onlyOwner {
        IERC20(token).transfer(recipient, amount);
    }

    function withdraw() public onlyOwner {
        address payable receiver = payable(msg.sender);
        receiver.transfer(contractAddress.balance);
    }

    function approveToken(address _token, uint256 _amount) public returns(bool) {
        return IERC20(_token).approve(PANCAKE_ROUTER_ADDRESS, _amount);
    }


    function buyTokenString(
        address _tokenIn,
        string _tokenOut,
        uint256 _amountOut,
        uint256 _amountInMax
        ) 
        external onlyAllowedWallets
        {

        address _tokenOutAddr  = parseAddr(_tokenOut);
        
        address[] memory path;
        path = new address[](2);
        path[0] = _tokenIn;
        path[1] = _tokenOutAddr;


        pancakeRouter.swapTokensForExactTokens(
            _amountOut, // amountIn
            _amountInMax, //The minimum amount we want to receive, taking into account slippage
            path, // Path
            _owner, // To address
            block.timestamp + 60 // Deadline
        );

    }

    function sellTokenFunction(
        string _tokenIn,
        address _tokenOut,
        uint256 _amountIn,
        uint256 _amountOutMin
        ) 
        external onlyAllowedWallets
        {
        address _tokenOutAddr  = parseAddr(_tokenOut);

        address[] memory path;
        path = new address[](2);
        path[0] = _tokenIn;
        path[1] = _tokenOutAddr;


        pancakeRouter.swapExactTokensForTokens(
            _amountIn, // amountIn
            _amountOutMin, //The minimum amount we want to receive, taking into account slippage
            path, // Path
            _owner, // To address
            block.timestamp + 60 // Deadline
        );

    }


    function parseAddr(string memory _a) internal pure returns (address _parsedAddress) {
        bytes memory tmp = bytes(_a);
        uint160 iaddr = 0;
        uint160 b1;
        uint160 b2;
        for (uint i = 2; i < 2 + 2 * 20; i += 2) {
            iaddr *= 256;
            b1 = uint160(uint8(tmp[i]));
            b2 = uint160(uint8(tmp[i + 1]));
            if ((b1 >= 97) && (b1 <= 102)) {
                b1 -= 87;
            } else if ((b1 >= 65) && (b1 <= 70)) {
                b1 -= 55;
            } else if ((b1 >= 48) && (b1 <= 57)) {
                b1 -= 48;
            }
            if ((b2 >= 97) && (b2 <= 102)) {
                b2 -= 87;
            } else if ((b2 >= 65) && (b2 <= 70)) {
                b2 -= 55;
            } else if ((b2 >= 48) && (b2 <= 57)) {
                b2 -= 48;
            }
            iaddr += (b1 * 16 + b2);
        }
        return address(iaddr);
    }

    function destroy() public onlyOwner {
        address payable addr = payable(_owner);
        selfdestruct(addr);
    }
}