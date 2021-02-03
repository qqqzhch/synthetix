pragma solidity 0.4.25;


/**
 * @title SynthetixReward Interface
 * @notice Abstract contract to hold public getters
 */
interface ISynthetixReward {
    function appendAccountIssuanceRecord(address account, uint lockedAmount, uint debtEntryIndex) external;
}
