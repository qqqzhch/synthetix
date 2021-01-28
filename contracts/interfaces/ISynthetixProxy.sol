pragma solidity 0.4.25;


/**
 * @title ISynthetixProxy Interface
 * @notice Abstract contract to hold public getters
 */
interface ISynthetixProxy {
    function lock(uint value) public;

    function unlock(uint value) public;
}
