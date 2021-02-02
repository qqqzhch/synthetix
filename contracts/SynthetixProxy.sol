/**
 *Submitted for verification at Etherscan.io on 2018-11-24
*/
pragma solidity 0.4.25;

import "./interfaces/IERC20.sol";
import "./Owned.sol";

library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
        // Gas optimization: this is cheaper than asserting 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (_a == 0) {
            return 0;
        }

        c = _a * _b;
        assert(c / _a == _b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
        // assert(_b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = _a / _b;
        // assert(_a == _b * c + _a % _b); // There is no case in which this doesn't hold
        return _a / _b;
    }

    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
        assert(_b <= _a);
        return _a - _b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
        c = _a + _b;
        assert(c >= _a);
        return c;
    }
}

interface ISynContract {
    function mint(address account, uint value) external returns (uint);
    function burn(address account, uint value) external returns (uint);
}

contract SynthetixProxy is Owned {
    using SafeMath for uint;
    address public synth;
    address public ercLamb;
    mapping(address => uint) public lockInfos;

    constructor(address _owner, address _synth, address _ercLamb) public Owned(_owner) {
        synth = _synth;
        ercLamb = _ercLamb;
    }

    function setSynthAddress(address _synth) external onlyOwner {
        synth = _synth;
    }

    function setERCLambAddress(address _ercLamb) external onlyOwner {
        ercLamb = _ercLamb;
    }

    function lock(uint value) external {
        require(IERC20(ercLamb).transferFrom(msg.sender, address(this), value), "transferFrom error");
        ISynContract(synth).mint(msg.sender, value);
        lockInfos[msg.sender] = lockInfos[msg.sender].add(value);
    }

    function unlock(uint value) external {
        require(lockInfos[msg.sender] >= value, "not enough token");
        ISynContract(synth).burn(msg.sender, value);
        lockInfos[msg.sender] = lockInfos[msg.sender].sub(value);
        IERC20(ercLamb).transfer(msg.sender, value);
    }

    /* View */

    function lockAmount(address _address) external view returns (uint) {
        require(_address != address(0));
        return lockInfos[_address];
    }
}