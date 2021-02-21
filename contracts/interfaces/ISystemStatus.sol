pragma solidity 0.4.25;


interface ISystemStatus {
    // Views
    function requireSystemActive() external view;

    function requireIssuanceActive() external view;

    function requireExchangeActive() external view;

    function requireCollateralActive(bytes32 currencyKey) external view;
}
