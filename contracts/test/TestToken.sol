pragma solidity 0.5.8;

import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-solidity/contracts/token/ERC20/ERC20Detailed.sol";


contract TestToken is ERC20, ERC20Detailed {
    constructor() public ERC20Detailed(
        "TestToken",
        "TT",
        18
    ) {
        _mint(msg.sender, 21000000 * 10 ** 18);
    }
}
