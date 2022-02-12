// SPDX-License-Identifier: GPL-3.0

//Author: André Costa (Terratecc)

pragma solidity >=0.8.2;
// to enable certain compiler features

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol



pragma solidity ^0.8.0;


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

interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

//initial coin offering smart contract
contract ICO is Ownable {

    //declaring the ERC20 token
    IERC20 public Token;
    
    //the maximum amount to be sold of tokens & the current amount sold
    uint256 private maxTokensToBeSold;
    uint256 private tokensSold;

    //price to buy 1 token
    uint256 private pricePerToken;
    
    //declaring the state of the sale
    enum State {NoSale, OpenSale}
    State private saleState_;
    
    //triggers when a token buy happens
    event Invest(address investor, uint cost, uint tokens);
    
    constructor() {
        //connecting to ERC20 contract
        //setTokenInterface(0x245aB4792EC5ed5Da1E07906e9a45C32088dD088); //the staking contract will be deployed first and then we will set the token contract

        //initial price of a token
        pricePerToken = 3000000000000000 wei; //0.003 BNB = 1.15 USD 

        //sale is closed initially
        saleState_ = State.NoSale;
    }
    
    //to stop the ico for a period of time
    function pauseICO() public onlyOwner {
        require(saleState_ == State.OpenSale, "Sale is already paused/closed!");
        saleState_ = State.NoSale;
    }
    
    //to continue the ico
    function resumeICO() public onlyOwner {
        require(saleState_ == State.NoSale, "Sale is already Open!");
        saleState_ = State.OpenSale;
    }
    
    //check curernt state of sale
    function saleState() public view returns(State) {
        return saleState_;
    }

    
    //set ERC20
    function setTokenInterface(address newInterface) public onlyOwner {
        Token = IERC20(newInterface);
    }
    
    //buying the tokens
    function invest() public payable {
        require(saleState_ == State.OpenSale, "Sale is not open!");
        //require(msg.value >= 0.001 ether && msg.value <= 5 ether); //no min or max specified for ICO
        require(msg.value > 0, "Insufficient funds to buy!");
        uint256 tokenToBeBought = msg.value / pricePerToken;
        require(tokensSold + tokenToBeBought <= maxTokensToBeSold, "Exceeds limit of Tokens for Sale!");

        Token.transferFrom(address(this), msg.sender, tokenToBeBought);
            
        emit Invest(msg.sender, msg.value, tokenToBeBought);
    }
    
    //in case funds are sent directly to the contract we redirect to invest function
    receive() payable external {
        invest();
    }

    //allow for bigger supply to be sold
    function increaseMaxTokens(uint256 newTokens) public onlyOwner {
        require(Token.balanceOf(address(this)) >= newTokens + maxTokensToBeSold, "This increase in tokens surpasses the balance of the contract!");
        maxTokensToBeSold += newTokens;
    }

    //see the max amount to be sold
    function maxTokensSold() external view returns(uint256) {
        return maxTokensToBeSold;
    }

    //see the current amount that has been sold
    function currentTokensSold() external view returns(uint256) {
        return tokensSold;
    }

    //adjust the price to mint
    function changePrice(uint256 newPrice) public onlyOwner {
        pricePerToken = newPrice;
    }
    
    
    
    
}