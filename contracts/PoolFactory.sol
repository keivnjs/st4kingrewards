//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Metaversepad.sol";

/**
 * @dev Contract module to deploy a pool automatically 
 */
contract PoolFactory is Ownable{

    /**
     * @dev Emitted when launhPool function is succesfully called and a pool is created
     */
    event PoolCreation(
      uint256 indexed timestamp, 
      Metaversepad indexed poolAddress, 
      address indexed projectOwner, 
      uint256 poolMaxCap, 
      uint256 saleStartTime, 
      uint256 saleEndTime, 
      uint256 noOfTiers,
      uint256 totalParticipants
    );
    
    /**
     * @dev Create a pool.
     *
     * emits a {PoolCreation} event
     */
    function launchPool(uint256 poolMaxCap, 
      uint256 saleStartTime, 
      uint256 saleEndTime, 
      uint256 noOfTiers, 
      uint256 totalParticipants, 
      address payable projectOwner, 
      address tokenAddress
    ) 
      public 
      onlyOwner
    {
      Metaversepad pool;

      pool = new Metaversepad(
        owner(),
        "MetaversePad",
        poolMaxCap, 
        saleStartTime, 
        saleEndTime, 
        noOfTiers, 
        totalParticipants, 
        projectOwner, 
        tokenAddress
      );

      emit PoolCreation(
        block.timestamp, 
        pool, 
        projectOwner, 
        poolMaxCap, 
        saleStartTime, 
        saleEndTime, 
        noOfTiers, 
        totalParticipants
      );
    }
}

