/**
 *Submitted for verification at Etherscan.io on 2018-11-24
*/
pragma solidity 0.4.25;

import "./SafeDecimalMath.sol";
import "./interfaces/IERC20.sol";
import "./Owned.sol";
import "./interfaces/ISynthetixState.sol";
import "./interfaces/IFeePool.sol";


contract SynthetixReward is Owned {
    using SafeMath for uint;
    using SafeDecimalMath for uint;
    address public ercTFI;
    address public synthetixState;
    address public feePool;

    uint public lastCloseIndex;
    uint public CLOSE_PERIOD_DURATION = 30 days;
    uint public lastCloseTime;

    // cache
    uint public totalRewardPeriod;

    mapping(address => uint) public rewardIndex;

    constructor (address _owner, address _ercTFI, address _synthetixState, address _feePool) public Owned(_owner) {
        ercTFI = _ercTFI;
        synthetixState = _synthetixState;
        feePool = _feePool;

        lastCloseTime = block.timestamp;
        lastCloseIndex = 0;
    }

    function setPeriodDuration(uint _period) external onlyOwner {
        CLOSE_PERIOD_DURATION = _period;
    }

    function setErcTFI(address _ercTFI) external onlyOwner {
        require(_ercTFI != address(0));
        ercTFI = _ercTFI;
    }

    function setSynthetixState(address _synthetixState) external onlyOwner {
        require(_synthetixState != address(0));
        synthetixState = _synthetixState;
    }

    function setFeePool(address _feePool) external onlyOwner {
        require(_feePool != address(0));
        feePool = _feePool;
    }

    function closePeriodReward() external onlyOwner {
        require(block.timestamp >= lastCloseTime.add(CLOSE_PERIOD_DURATION), "too early close reward period");
        lastCloseTime = block.timestamp;

        uint periodReward = IERC20(ercTFI).balanceOf(address(this));
        require(periodReward > 0, "TFI reward token must greater 0");
        totalRewardPeriod = periodReward;

        uint length = ISynthetixState(synthetixState).debtLedgerLength();
        require(length > 0, "have no ledger");
        lastCloseIndex = length - 1;
    }

    function claimReward() external {
        require(rewardIndex[msg.sender] < lastCloseIndex, "already reward");

        require(IFeePool(feePool).isFeesClaimable(msg.sender), "staking ratio is too low to claim reward");

        uint rewardAmount = getUnClaimedReward(msg.sender);
        IERC20(ercTFI).transfer(msg.sender, rewardAmount);
        rewardIndex[msg.sender] = lastCloseIndex;
    }

    function getUnClaimedReward(address _account) public view returns (uint) {
        uint remainderAmount = IERC20(ercTFI).balanceOf(address(this));
        require(remainderAmount > 0, "no reward token distribution");

        uint rewardPercent = IFeePool(feePool).effectiveDebtRatioForLastCloseIndex(_account, lastCloseIndex);

        uint rewardAmount = rewardPercent.multiplyDecimal(totalRewardPeriod).preciseDecimalToDecimal();
        if (remainderAmount < rewardAmount) {
            rewardAmount = remainderAmount;
        }
        return rewardAmount;
    }
}