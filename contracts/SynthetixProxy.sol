/**
 *Submitted for verification at Etherscan.io on 2018-11-24
*/
pragma solidity 0.4.25;

import "./SafeDecimalMath.sol";
import "./Owned.sol";
import "./interfaces/IERC20.sol";

contract ISynContract {
    function mint(address account, uint value) external returns (uint);
    function burn(address account, uint value) external returns (uint);
}

contract SynthetixProxy is Owned {
    using SafeMath for uint;
    address public synth;
    address public ERCLamb;
    mapping(address => uint) public lockInfos;

    constructor(address _owner, address _synth, address _ERCLamb) public Owned(_owner) {
        synth = _synth;
        ERCLamb = _ERCLamb;
    }

    function setSynthAddress(address _synth) external onlyOwner {
        synth = _synth;
    }

    function setERCLambAddress(address _ERCLamb) external onlyOwner {
        ERCLamb = _ERCLamb;
    }

    function lock(uint value) external {
        require(IERC20(ERCLamb).transferFrom(msg.sender, address(this), value), "transferFrom error");
        ISynContract(synth).mint(msg.sender, value);
        lockInfos[msg.sender] = lockInfos[msg.sender].add(value);
    }

    function unlock(uint value) external {
        require(lockInfos[msg.sender] >= value, "not enough token");
        ISynContract(synth).burn(msg.sender, value);
        lockInfos[msg.sender] = lockInfos[msg.sender].sub(value);
        IERC20(ERCLamb).transfer(msg.sender, value);
    }

    /* View */

    function lockAmount(address _address) external view returns (uint) {
        require(_address != address(0));
        return lockInfos[_address];
    }
}