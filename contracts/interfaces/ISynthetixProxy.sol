pragma solidity 0.4.25;


/**
 * @title ISynthetixProxy Interface
 * @notice Abstract contract to hold public getters
 */
interface ISynthetixProxy {
    function proxyToMint(address account, uint value) external view returns (uint);

	function proxyToBurn(address account, uint value) external view returns (uint);
}
