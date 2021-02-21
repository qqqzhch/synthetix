pragma solidity 0.4.25;

// Inheritance
import "./Owned.sol";
import "./interfaces/ISystemStatus.sol";


contract SystemStatus is Owned, ISystemStatus {
    bytes32 public constant SECTION_SYSTEM = "System";
    bytes32 public constant SECTION_ISSUANCE = "Issuance";
    bytes32 public constant SECTION_EXCHANGE = "Exchange";

    bool public systemSuspension;

    bool public issuanceSuspension;

    bool public exchangeSuspension;

    mapping(bytes32 => bool) public collateralSuspensions;

    constructor(address _owner, bool suspension) Owned(_owner) {
        systemSuspension = suspension;
    }

    /* ========== VIEWS ========== */
    function requireSystemActive() external view {
        _internalRequireSystemActive();
    }

    function requireIssuanceActive() external view {
        // Issuance requires the system be active
        _internalRequireSystemActive();
        require(!issuanceSuspension, "Issuance is suspended. Operation prohibited");
    }

    function requireExchangeActive() external view {
        // Issuance requires the system be active
        _internalRequireSystemActive();
        require(!exchangeSuspension, "Exchange is suspended. Operation prohibited");
    }

    function requireCollateralActive(bytes32 currencyKey) external view {
        // Collateral operations requires the system be active
        _internalRequireSystemActive();
        require(!collateralSuspensions[currencyKey], "Collateral is suspended. Operation prohibited");
    }

    function getCollateralSuspensions(bytes32[] collaterals)
        external
        view
        returns (bool[] memory suspensions)
    {
        suspensions = new bool[](collaterals.length);

        for (uint i = 0; i < collaterals.length; i++) {
            suspensions[i] = collateralSuspensions[collaterals[i]];
        }
    }

    /* ========== MUTATIVE FUNCTIONS ========== */
    function suspendSystem() external onlyOwner {
        systemSuspension = true;
        emit StatusChanged(SECTION_SYSTEM, true);
    }

    function resumeSystem() external onlyOwner {
        systemSuspension = false;
        emit StatusChanged(SECTION_SYSTEM, false);
    }

    function suspendIssuance() external onlyOwner {
        issuanceSuspension = true;
        emit StatusChanged(SECTION_ISSUANCE, true);
    }

    function resumeIssuance() external onlyOwner {
        issuanceSuspension = false;
        emit StatusChanged(SECTION_ISSUANCE, false);
    }

    function suspendExchange() external onlyOwner {
        exchangeSuspension = true;
        emit StatusChanged(SECTION_EXCHANGE, true);
    }

    function resumeExchange() external onlyOwner {
        exchangeSuspension = false;
        emit StatusChanged(SECTION_EXCHANGE, false);
    }

    function suspendCollateral(bytes32 currencyKey) external onlyOwner {
        collateralSuspensions[currencyKey] = true;
        emit StatusChanged(currencyKey, true);
    }

    function resumeSynth(bytes32 currencyKey) external onlyOwner {
        collateralSuspensions[currencyKey] = false;
        emit StatusChanged(currencyKey, false);
    }

    /* ========== INTERNAL FUNCTIONS ========== */
    function _internalRequireSystemActive() internal view {
        require(!systemSuspension, "System is suspended, Operation prohibited");
    }

    /* ========== EVENTS ========== */

    event StatusChanged(bytes32 key, bool suspension);
}
