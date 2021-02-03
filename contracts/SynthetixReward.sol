/**
 *Submitted for verification at Etherscan.io on 2018-11-24
*/
pragma solidity 0.4.25;

import "./SafeDecimalMath.sol";
import "./interfaces/IERC20.sol";
import "./MixinResolver.sol";
import "./interfaces/ISynthetixState.sol";
import "./interfaces/IFeePool.sol";
import "./interfaces/IIssuer.sol";
import "./SynthetixRewardState.sol";


contract SynthetixReward is MixinResolver {
    using SafeMath for uint;
    using SafeDecimalMath for uint;
    address public ercTFI;

    uint public startIndex;
    uint public closePeriodDuration = 30 days;
    uint64 public startTime;

    // cache
    uint public totalRewardPeriod;

    mapping(address => uint) public rewardIndex;

    constructor (address _owner, address _resolver , address _ercTFI) public MixinResolver(_owner, _resolver) {
        ercTFI = _ercTFI;
        startTime = uint64(now);
        startIndex = 0;
    }

    function synthetixState() internal view returns (ISynthetixState) {
        return ISynthetixState(resolver.requireAndGetAddress("SynthetixState", "Missing SynthetixState address"));
    }

    function feePool() internal view returns (IFeePool) {
        return IFeePool(resolver.requireAndGetAddress("FeePool", "Missing FeePool address"));
    }

    function issuer() internal view returns (IIssuer) {
        return IIssuer(resolver.requireAndGetAddress("Issuer", "Missing Issuer address"));
    }

    function synthetixRewardState() internal view returns (SynthetixRewardState) {
        return SynthetixRewardState(resolver.requireAndGetAddress("SynthetixRewardState", "Missing Issuer address"));
    }

    function setPeriodDuration(uint _period) external onlyOwner {
        closePeriodDuration = _period;
    }

    function setErcTFI(address _ercTFI) external onlyOwner {
        require(_ercTFI != address(0));
        ercTFI = _ercTFI;
    }

    function closePeriodReward() external onlyOwner {
        require(startTime <= (now - closePeriodDuration), "too early close reward period");
        startTime = uint64(now);

        uint periodReward = IERC20(ercTFI).balanceOf(address(this));
        require(periodReward > 0, "TFI reward token must greater 0");
        totalRewardPeriod = periodReward;

        uint length = synthetixState.debtLedgerLength();
        require(length > 0, "have no ledger");
        startIndex = length;
    }

    function claimReward() external {
        require(startIndex > 0, "system just starts, no reward period closed");

        require(rewardIndex[msg.sender] < startIndex, "already reward");

        require(feePool().isFeesClaimable(msg.sender), "staking ratio is too low to claim reward");

        uint rewardAmount = getUnClaimedReward(msg.sender);

        if (rewardAmount > 0){
            IERC20(ercTFI).transfer(msg.sender, rewardAmount);
            rewardIndex[msg.sender] = startIndex;
        }
    }

    function getUnClaimedReward(address _account) public view returns (uint) {
        if (startIndex == 0) return 0;

        uint remainderAmount = IERC20(ercTFI).balanceOf(address(this));
        require(remainderAmount > 0, "no reward token distribution");

        uint rewardPercent = effectiveDebtRatioForLastCloseIndex(_account, startIndex.sub(1));
        if (rewardPercent == 0) return 0;

        uint rewardAmount = rewardPercent.multiplyDecimal(totalRewardPeriod).preciseDecimalToDecimal();
        if (remainderAmount < rewardAmount) {
            rewardAmount = remainderAmount;
        }
        return rewardAmount;
    }

    function appendAccountIssuanceRecord(address account, uint debtRatio, uint debtEntryIndex) external onlyIssuer {
        synthetixRewardState().appendAccountIssuanceRecord(
            account,
            debtRatio,
            debtEntryIndex,
            startIndex
        );
    }

    function effectiveDebtRatioForLastCloseIndex(address account, uint closingDebtIndex) internal view returns (uint) {
        uint ownershipPercentage;
        uint debtEntryIndex;
        (ownershipPercentage, debtEntryIndex) = synthetixRewardState().applicableIssuanceData(account, closingDebtIndex);

        if (ownershipPercentage == 0) return 0;

        // internal function will check closingDebtIndex has corresponding debtLedger entry
        return _effectiveDebtRatioForPeriod(closingDebtIndex, ownershipPercentage, debtEntryIndex);
    }

    function _effectiveDebtRatioForPeriod(uint closingDebtIndex, uint ownershipPercentage, uint debtEntryIndex)
        internal
        view
        returns (uint)
    {
        ISynthetixState _synthetixState = synthetixState();
        uint debtOwnership = _synthetixState
            .debtLedger(closingDebtIndex)
            .divideDecimalRoundPrecise(_synthetixState.debtLedger(debtEntryIndex))
            .multiplyDecimalRoundPrecise(ownershipPercentage);

        return debtOwnership;
    }
}