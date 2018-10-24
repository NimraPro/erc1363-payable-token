pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/utils/Address.sol";
import "openzeppelin-solidity/contracts/introspection/ERC165Checker.sol";
import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";

import "./IERC1363.sol";
import "./ERC1363Receiver.sol";
import "./ERC1363Spender.sol";


/**
 * @title ERC1363
 * @author Vittorio Minacori (https://github.com/vittominacori)
 * @dev Implementation of an ERC1363 interface
 */
contract ERC1363 is ERC20, IERC1363 { // solium-disable-line max-len
  using Address for address;

  /*
   * Note: the ERC-165 identifier for this interface is 0x4bbee2df.
   * 0x4bbee2df ===
   *   bytes4(keccak256('transferAndCall(address,uint256)')) ^
   *   bytes4(keccak256('transferAndCall(address,uint256,bytes)')) ^
   *   bytes4(keccak256('transferFromAndCall(address,address,uint256)')) ^
   *   bytes4(keccak256('transferFromAndCall(address,address,uint256,bytes)'))
   */
  bytes4 internal constant InterfaceId_ERC1363Transfer = 0x4bbee2df;

  /*
   * Note: the ERC-165 identifier for this interface is 0xfb9ec8ce.
   * 0xfb9ec8ce ===
   *   bytes4(keccak256('approveAndCall(address,uint256)')) ^
   *   bytes4(keccak256('approveAndCall(address,uint256,bytes)'))
   */
  bytes4 internal constant InterfaceId_ERC1363Approve = 0xfb9ec8ce;

  // Equals to `bytes4(keccak256("onTransferReceived(address,address,uint256,bytes)"))`
  // which can be also obtained as `ERC1363Receiver(0).onTransferReceived.selector`
  bytes4 private constant ERC1363_RECEIVED = 0x88a7ca5c;

  // Equals to `bytes4(keccak256("onApprovalReceived(address,uint256,bytes)"))`
  // which can be also obtained as `ERC1363Spender(0).onApprovalReceived.selector`
  bytes4 private constant ERC1363_APPROVED = 0x7b04a2d0;

  constructor() public {
    // register the supported interfaces to conform to ERC1363 via ERC165
    _registerInterface(InterfaceId_ERC1363Transfer);
    _registerInterface(InterfaceId_ERC1363Approve);
  }

  function transferAndCall(
    address to,
    uint256 value
  )
    public
    returns (bool)
  {
    return transferAndCall(to, value, "");
  }

  function transferAndCall(
    address to,
    uint256 value,
    bytes data
  )
    public
    returns (bool)
  {
    require(transfer(to, value));
    require(
      checkAndCallTransfer(
        msg.sender,
        to,
        value,
        data
      )
    );
    return true;
  }

  function transferFromAndCall(
    address from,
    address to,
    uint256 value
  )
    public
    returns (bool)
  {
    // solium-disable-next-line arg-overflow
    return transferFromAndCall(from, to, value, "");
  }

  function transferFromAndCall(
    address from,
    address to,
    uint256 value,
    bytes data
  )
    public
    returns (bool)
  {
    require(transferFrom(from, to, value));
    require(
      checkAndCallTransfer(
        from,
        to,
        value,
        data
      )
    );
    return true;
  }

  function approveAndCall(
    address spender,
    uint256 value
  )
    public
    returns (bool)
  {
    return approveAndCall(spender, value, "");
  }

  function approveAndCall(
    address spender,
    uint256 value,
    bytes data
  )
    public
    returns (bool)
  {
    approve(spender, value);
    require(
      checkAndCallApprove(
        spender,
        value,
        data
      )
    );
    return true;
  }

  /**
   * @dev Internal function to invoke `onTransferReceived` on a target address
   *  The call is not executed if the target address is not a contract
   * @param from address Representing the previous owner of the given token value
   * @param to address Target address that will receive the tokens
   * @param value uint256 The amount mount of tokens to be transferred
   * @param data bytes Optional data to send along with the call
   * @return whether the call correctly returned the expected magic value
   */
  function checkAndCallTransfer(
    address from,
    address to,
    uint256 value,
    bytes data
  )
    internal
    returns (bool)
  {
    if (!to.isContract()) {
      return false;
    }
    bytes4 retval = ERC1363Receiver(to).onTransferReceived(
      msg.sender, from, value, data
    );
    return (retval == ERC1363_RECEIVED);
  }

  /**
   * @dev Internal function to invoke `onApprovalReceived` on a target address
   *  The call is not executed if the target address is not a contract
   * @param spender address The address which will spend the funds
   * @param value uint256 The amount of tokens to be spent
   * @param data bytes Optional data to send along with the call
   * @return whether the call correctly returned the expected magic value
   */
  function checkAndCallApprove(
    address spender,
    uint256 value,
    bytes data
  )
    internal
    returns (bool)
  {
    if (!spender.isContract()) {
      return false;
    }
    bytes4 retval = ERC1363Spender(spender).onApprovalReceived(
      msg.sender, value, data
    );
    return (retval == ERC1363_APPROVED);
  }
}