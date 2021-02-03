pragma solidity 0.4.25;


/**
 * @title SynthetixRewardState Interface
 * @notice Abstract contract to hold public getters
 */
interface ISynthetixRewardState {
    function appendAccountIssuanceRecord(address account, uint lockedAmount, uint debtEntryIndex, uint currentPeriodStartDebtIndex) external;

    function applicableIssuanceData(address account, uint closingDebtIndex) external view returns (uint, uint);
}
