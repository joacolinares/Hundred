// SPDX-License-Identifier: GPL-3.0
// File: @openzeppelin/contracts/utils/Strings.sol

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


contract StakingPool is Ownable {
    //last time that tokens where retrieved
    mapping(address => uint256) public checkpoints;

    //the amount of tokens that are currently staked
    mapping(address => uint256) private _stakedBalance;

    //stores all addresses that are staked
    address[] private stakers;

    //token contract
    IERC20 public Token;

    //uint public rewardPerDay; //no reward has been established

    //dummy address that we use to sign the mint transaction to make sure it is valid
    address private dummy = 0x80E4929c869102140E69550BBECC20bEd61B080c;

    //emit this notification when somebody staked
    event Stake(address staker, uint tokens);
    //emit this notification when somebody unstakes
    event Unstake(address unstaker, uint tokens);

    constructor() {}

    //set ERC20
    function setTokenInterface(address newInterface) public onlyOwner {
        Token = IERC20(newInterface);
    }

    //stake all the tokens of address at once
    function stakeAll() external {
        uint balance = Token.balanceOf(msg.sender);
        require(balance > 0, "No tokens to stake!");

        _deposit(balance);
    }

    //stake a certain amount of tokens
    function stake(uint256 tokens) external {
        //they have to have that balance
        require(Token.balanceOf(msg.sender) >= tokens, "Insufficient Balance to Stake this amount of tokens");
        _deposit(tokens);
        
    }

    function _deposit(uint256 tokens) internal {
        //set the time of staking to now
        checkpoints[msg.sender] = block.timestamp;

        //transfer the tokens and update balance
        Token.transferFrom(msg.sender, address(this), tokens);
        _stakedBalance[msg.sender] += tokens;

        emit Stake(msg.sender, tokens);
    }

    //unstake all tokens possible
    function unstakeAll() external {
        require(isStaked(msg.sender), "No tokens Staked!");
        popFromStakers();
        _withdraw(_stakedBalance[msg.sender]);
        
    }

    //unstake a certain amount of tokens
    function unstake(uint256 tokens) external {
        require(isStaked(msg.sender), "No tokens Staked!");
        uint256 balance = _stakedBalance[msg.sender];
        require(balance >= tokens, "Insufficient Staked Balance to withdraw this amount!");

        if (balance == tokens) {
            popFromStakers();
        }

        _withdraw(balance);
        
    }

    //take out of stakers list
    function popFromStakers() internal {
        uint pos = positionInStakers();
        
        address firstValue = stakers[pos];
        address secondValue = stakers[stakers.length - 1];
        stakers[pos] = secondValue;
        stakers[stakers.length - 1] = firstValue;
        stakers.pop();
    }

    function positionInStakers() internal view returns(uint) {
        uint index;
        for (uint i = 0; i < stakers.length; i++) {
            if (stakers[i] == msg.sender) {
                index = i;
                break;
            }
        }
        return index;
    }

    function _withdraw(uint256 tokens) internal {
        Token.transferFrom(address(this), msg.sender, tokens);

        emit Unstake(msg.sender, tokens);
    }

    //have a list of all addresses that are staking
    function seeStakers() public view returns(address[] memory) {
        return stakers;
    }

    //check if a certain address is staked
    function isStaked(address staker) public view returns(bool) {
        if (_stakedBalance[staker] > 0) {
            return true;
        }
        else {
            return false;
        }
    }

    //check how long a certain address has been staking
    function timeStaking(address staker) public view returns(uint256) {
        require(isStaked(staker), "Address is not staking tokens!");
        return block.timestamp - checkpoints[staker];
    }

    //check the amount of tokens staked by somebody
    function stakedBalanceOf(address staker) public view returns(uint256) {
        return _stakedBalance[staker];
    }

    
}