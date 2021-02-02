/**
 *Submitted for verification at Etherscan.io on 2018-11-24
*/
pragma solidity 0.4.25;

import "./SafeDecimalMath.sol";
import "./Owned.sol";
import "./interfaces/IERC20.sol";

contract ISynRewardContract {
    function closeCurrentFeePeriod() external;
    function debtLedgerLength() external view returns (uint);
    function applicableIssuanceData(address account, uint closingDebtIndex) external view returns (uint, uint);
    function effectiveDebtRatioForLastCloseIndex(address account, uint closingDebtIndex) external view returns (uint);
}

contract SynthetixReward is Owned {
    using SafeMath for uint;
    using SafeDecimalMath for uint;
    address TFIERC20;
    address FeePoolState;
    address SynthetixState;
    address FeePool;

    uint lastCloseIndex;
    uint MIN_CLOSE_PERIOD_TIME = 30 days;
    uint lastCloseTime;

    // cache
    uint totalRewardPeriod;

    mapping(address => uint) rewardIndex;

    constructor (address _owner, address _TFIERC20, address _SynthetixState, address _FeePoolState, address _FeePool) public Owned(_owner) {
        TFIERC20 = _TFIERC20;
        SynthetixState = _SynthetixState;
        FeePoolState = _FeePoolState;
        FeePool = _FeePool;

        lastCloseTime = block.timestamp;
        lastCloseIndex = 0;
    }

    function setTFIERC20(address _TFIERC20) external onlyOwner {
        require(_TFIERC20 != address(0));
        TFIERC20 = _TFIERC20;
    }

    function setSynthetixState(address _SynthetixState) external onlyOwner {
        require(_SynthetixState != address(0));
        SynthetixState = _SynthetixState;
    }

    function setFeePoolState(address _FeePoolState) external onlyOwner {
        require(_FeePoolState != address(0));
        FeePoolState = _FeePoolState;
    }

    function setFeePool(address _FeePool) external onlyOwner {
        require(_FeePool != address(0));
        FeePool = _FeePool;
    }

    function closePeriodReward() external onlyOwner {
        require(block.timestamp >= lastCloseTime.add(MIN_CLOSE_PERIOD_TIME), "too early close reward period");
        ISynRewardContract(FeePool).closeCurrentFeePeriod();
        uint lastIndex = ISynRewardContract(SynthetixState).debtLedgerLength();
        lastCloseIndex = lastIndex;
        uint periodReward = IERC20(TFIERC20).balanceOf(address(this));
        require(periodReward > 0, "TFI reward token must greater 0");
        totalRewardPeriod = periodReward;
        lastCloseTime = block.timestamp;
    }

    function settleReward() external {
        require(rewardIndex[msg.sender] < lastCloseIndex, "already reward");
        uint remainderAmount = IERC20(TFIERC20).balanceOf(address(this));
        require(remainderAmount > 0, "not enough reward token");

        (uint rewardPercent, uint debtEntryIndex) = ISynRewardContract(FeePoolState).applicableIssuanceData(msg.sender, lastCloseIndex);

        // transfer
        uint rewardAmount = rewardPercent.multiplyDecimal(totalRewardPeriod);
        if (remainderAmount < rewardAmount) {
            rewardAmount = remainderAmount;
        }
        IERC20(TFIERC20).transfer(msg.sender, rewardAmount);
        rewardIndex[msg.sender] = lastCloseIndex;
    }
}