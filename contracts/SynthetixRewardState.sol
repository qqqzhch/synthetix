/*
Synthetix reward state
*/

pragma solidity 0.4.25;

import "./SafeDecimalMath.sol";
import "./Owned.sol";

contract SynthetixRewardState is Owned {
    using SafeMath for uint;
    using SafeDecimalMath for uint;

    /* ========== STATE VARIABLES ========== */

    uint8 public constant REWARD_PERIOD_LENGTH = 6;

    address public synthetixReward;

    // The IssuanceData activity that's happened in a fee period.
    struct IssuanceData {
        uint debtPercentage;
        uint debtEntryIndex;
    }

    // The IssuanceData activity that's happened in a fee period.
    mapping(address => IssuanceData[REWARD_PERIOD_LENGTH]) public accountIssuanceLedger;

    /**
     * @dev Constructor.
     * @param _owner The owner of this contract.
     */
    constructor(address _owner, address _synthetixReward) public Owned(_owner) {
        synthetixReward = _synthetixReward;
    }

    function setSynthetixReward(address _synthetixReward) external onlyOwner {
        synthetixReward = _synthetixReward;
    }

    function getAccountsDebtEntry(address account, uint index)
        public
        view
        returns (uint debtPercentage, uint debtEntryIndex)
    {
        require(index < REWARD_PERIOD_LENGTH, "index exceeds the REWARD_PERIOD_LENGTH");

        debtPercentage = accountIssuanceLedger[account][index].debtPercentage;
        debtEntryIndex = accountIssuanceLedger[account][index].debtEntryIndex;
    }

    function applicableIssuanceData(address account, uint closingDebtIndex) external view returns (uint, uint) {
        IssuanceData[REWARD_PERIOD_LENGTH] memory issuanceData = accountIssuanceLedger[account];

        for (uint i = 0; i < REWARD_PERIOD_LENGTH; i++) {
            if (closingDebtIndex >= issuanceData[i].debtEntryIndex) {
                return (issuanceData[i].debtPercentage, issuanceData[i].debtEntryIndex);
            }
        }
    }

    function appendAccountIssuanceRecord(
        address account,
        uint debtRatio,
        uint debtEntryIndex,
        uint currentPeriodStartDebtIndex
    ) external onlySynthetixReward {
        // Is the current debtEntryIndex within this fee period
        if (accountIssuanceLedger[account][0].debtEntryIndex < currentPeriodStartDebtIndex) {
            // If its older then shift the previous IssuanceData entries periods down to make room for the new one.
            issuanceDataIndexOrder(account);
        }

        // Always store the latest IssuanceData entry at [0]
        accountIssuanceLedger[account][0].debtPercentage = debtRatio;
        accountIssuanceLedger[account][0].debtEntryIndex = debtEntryIndex;
    }

    /**
     * @notice Pushes down the entire array of debt ratios per fee period
     */
    function issuanceDataIndexOrder(address account) private {
        for (uint i = REWARD_PERIOD_LENGTH - 2; i < REWARD_PERIOD_LENGTH; i--) {
            uint next = i + 1;
            accountIssuanceLedger[account][next].debtPercentage = accountIssuanceLedger[account][i].debtPercentage;
            accountIssuanceLedger[account][next].debtEntryIndex = accountIssuanceLedger[account][i].debtEntryIndex;
        }
    }

    modifier onlySynthetixReward {
        require(msg.sender == synthetixReward, "Only the SynthetixReward contract can perform this action");
        _;
    }
}
