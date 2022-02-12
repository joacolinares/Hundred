// SPDX-License-Identifier: GPL-3.0
// File: @openzeppelin/contracts/utils/Strings.sol

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

struct Project {
    string name;
    string description;
    uint256 funds;
    address recipient;
    uint id;
}

struct Investor {
    address sender;
    uint256 amount;
    uint256 time;
}


contract Invest is Ownable {
    //addd new projects, create a struct (name, description, funds needed, recipient address, id)
    //see projects that are pending approval (hold list)
    //see all projects that have been approved (hold list)
    //allow owner to approve/reject project by tokenid (must be pending approval)
    //emergency stop a project
    //have fee to send a project
    //hold list of finished projects, send when amount is reached or when owner decides
    //allow users to invest in a project, hold balance of a project
    //release funds to recipient address
    //change cost to send project
    //list of investors in each project

    mapping(uint => Project) private idToProject;
    mapping(uint => Investor[]) private idToInvestors;

    uint private lastId;

    uint[] private pendingProjects;
    uint[] private approvedProjects;
    uint[] private finishedProjects;

    uint256 private priceToAddProject;

    mapping(uint => uint256) private balances;

    event NewProject(string name_, string description_, uint256 funds_, address recipient_);
    event Investment(address from, uint256 value);

    constructor () {
        priceToAddProject = 1000000 wei;
    }



    function addProject(string memory name_, string memory description_, uint256 funds_, address recipient_) external payable {
        require(msg.value >= priceToAddProject, "Insufficient funds to add new project!");
        require(funds_ > 0, "Funds cannot be 0!");
        require(recipient_ != address(0), "Recipient cannot be Null Address!");

        lastId++;
        Project memory project_ = Project(name_, description_, funds_, recipient_, lastId);
        idToProject[lastId] = project_;
        pendingProjects.push(lastId);

        emit NewProject(name_, description_, funds_, recipient_);
    }

    function approveProject(uint projectID) external onlyOwner {
        require(projectID <= lastId, "Project ID does not exist!");

        popFromPendingList(projectID);
        approvedProjects.push(projectID);
    }

    function rejectProject(uint projectID) external onlyOwner {
        require(projectID <= lastId, "Project ID does not exist!");
        
        popFromPendingList(projectID);
    }

    function finishProject(uint projectID) external onlyOwner {
        require(projectID <= lastId, "Project ID does not exist!");

        popFromApprovedList(projectID);
        finishedProjects.push(projectID);
    }

    function emergencyCloseProject(uint projectID) external onlyOwner {
        require(projectID <= lastId, "Project ID does not exist!");

        popFromApprovedList(projectID);
    }


    function popFromApprovedList(uint id) internal {
        uint pos = positionInList(id, approvedProjects);
        if (pos == 0) {
            require(approvedProjects[pos] == id, "Id not in List!");
        }
        
        uint firstValue = approvedProjects[pos];
        uint secondValue = approvedProjects[approvedProjects.length - 1];
        approvedProjects[pos] = secondValue;
        approvedProjects[approvedProjects.length - 1] = firstValue;
        approvedProjects.pop();
    }

    function popFromPendingList(uint id) internal {
        uint pos = positionInList(id, pendingProjects);
        if (pos == 0) {
            require(pendingProjects[pos] == id, "Id not in List!");
        }
        
        uint firstValue = pendingProjects[pos];
        uint secondValue = pendingProjects[pendingProjects.length - 1];
        pendingProjects[pos] = secondValue;
        pendingProjects[pendingProjects.length - 1] = firstValue;
        pendingProjects.pop();
    }

    function positionInList(uint id, uint[] memory list) internal pure returns(uint) {
        uint index;
        for (uint i = 0; i < list.length; i++) {
            if (list[i] == id) {
                index = i;
                break;
            }
        }
        return index;
    }

    function investInProject(uint projectID) external payable {
        require(msg.value > 0, "Must send funds to invest!");
        uint pos = positionInList(projectID, approvedProjects);
        if (pos == 0) {
            require(projectID == approvedProjects[pos], "Project has not been approved yet!");
        }
        Project memory project_ = idToProject[projectID];
        require(balances[projectID] < project_.funds, "Project has reached investment limit!");

        balances[projectID] += msg.value;

        Investor memory investor_ = Investor(msg.sender, msg.value, block.timestamp);
        idToInvestors[projectID].push(investor_);

        (bool sent, ) = payable(project_.recipient).call{value: msg.value}("");
        require(sent, "Failed to send BNB");

        emit Investment(msg.sender, msg.value);
    }

    function seeProjectInvestors(uint projectID) public view returns(Investor[] memory) {
        return idToInvestors[projectID];
    } 

    function projectDetails(uint projectID) public view returns(Project memory) {
        require(projectID <= lastId, "Project ID does not exist!");

        return idToProject[projectID];
    }

    function seePendingProjectIds() public view returns(uint[] memory) {
        return pendingProjects;
    }

    function seeApprovedProjectIds() public view returns(uint[] memory) {
        return approvedProjects;
    }

    function seeFinishedProjectIds() public view returns(uint[] memory) {
        return finishedProjects;
    }

    function changeAddProjectPrice(uint256 newPrice) external onlyOwner {
        priceToAddProject = newPrice;
    }

    function projectBalance(uint projectID) public view returns(uint256) {
        return balances[projectID];
    }
}

