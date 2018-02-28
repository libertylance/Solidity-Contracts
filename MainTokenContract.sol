pragma solidity ^0.4.18;

// ----------------------------------------------------------------------------
// LTN token main contract
//
// Symbol       : LTN
// Name         : LibertyLance ERC20 token contract
// Total supply : 50000000,000000000000000000 (burnable)
// Decimals     : 18
//
// 2018 (c) Sergey Kalich
// ----------------------------------------------------------------------------


// ----------------------------------------------------------------------------
// Safe math
// ----------------------------------------------------------------------------
library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}


// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
// ----------------------------------------------------------------------------
contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


// ----------------------------------------------------------------------------
// Contract function to receive approval and execute function in one call
// ----------------------------------------------------------------------------
contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}


// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    function Owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}


// ----------------------------------------------------------------------------
// LTN ERC20 Token - LibertyLance token contract
// ----------------------------------------------------------------------------
contract LTN is ERC20Interface, Owned {
    using SafeMath for uint;

    bool public running = true;
    string public symbol;
    string public name;
    uint8 public decimals;
    uint _totalSupply;

    address public saleAddress;
    address public teamFreeze = 0x7777777777777777777777777777777777777777;
    uint8 public teamFreezePercent = 20;
    uint256 public teamTokens;
    uint256 public teamTokensReleaseTime;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;


    // ------------------------------------------------------------------------
    // Contract init. Set symbol, name, decimals and initial fixed supply
    // ------------------------------------------------------------------------
    function LTN() public {
        symbol = "LTN";
        name = "LibertyLance";
        decimals = 18;
        _totalSupply = 50000000 * 10**uint(decimals);
        balances[owner] = _totalSupply;
        Transfer(address(0), owner, _totalSupply);
    // ------------------------------------------------------------------------
    // Team tokens transfer to freeze account (20% - 10000000 tokens)
    // ------------------------------------------------------------------------
        teamTokens = _totalSupply.mul(teamFreezePercent).div(100);
        balances[owner] = balances[owner].sub(teamTokens);
        balances[teamFreeze] = balances[teamFreeze].add(teamTokens);
        Transfer(owner, teamFreeze, teamTokens);
        teamTokensReleaseTime = now + 180 days;
    }


    // ------------------------------------------------------------------------
    // Team tokens unfreeze 
    // 25% of freezed tokens each 6 months
    // 2500000 of freezed 10000000 tokens each 180 days 
    // from contract deplay time
    // ------------------------------------------------------------------------

    function unfreezeTeamTokens(address unfreezeaddress) public onlyOwner returns (bool success) {
        require(balances[teamFreeze] > 0);
        require(now >= teamTokensReleaseTime);
        balances[teamFreeze] = balances[teamFreeze].sub(teamTokens.div(4));
        balances[unfreezeaddress] = balances[unfreezeaddress].add(teamTokens.div(4));
        Transfer(teamFreeze, unfreezeaddress, teamTokens.div(4));
        teamTokensReleaseTime = teamTokensReleaseTime + 180 days;
        return true;
    }


    // ------------------------------------------------------------------------
    // Start-stop contract functions:
    // transfer, approve, transferFrom, approveAndCall
    // ------------------------------------------------------------------------

    modifier isRunnning {
        require(running);
        _;
    }

    function startStop () public onlyOwner returns (bool success) {
        if (running) { running = false; } else { running = true; }
        return true;
    }

    // ------------------------------------------------------------------------
    // Total supply
    // ------------------------------------------------------------------------
    function totalSupply() public constant returns (uint) {
        return _totalSupply;
    }


    // ------------------------------------------------------------------------
    // Get the token balance for account `tokenOwner`
    // ------------------------------------------------------------------------
    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return balances[tokenOwner];
    }


    // ------------------------------------------------------------------------
    // Transfer the balance from token owner's account to `to` account
    // ------------------------------------------------------------------------
    function transfer(address to, uint tokens) public isRunnning returns (bool success) {
        require(tokens <= balances[msg.sender]);
        require(tokens != 0);
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        Transfer(msg.sender, to, tokens);
        return true;
    }


    // ------------------------------------------------------------------------
    // Token owner can approve for `spender` to transferFrom(...) `tokens`
    // from the token owner's account
    //
    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
    // recommends that there are no checks for the approval double-spend attack
    // as this should be implemented in user interfaces 
    // ------------------------------------------------------------------------
    function approve(address spender, uint tokens) public isRunnning returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        Approval(msg.sender, spender, tokens);
        return true;
    }


    // ------------------------------------------------------------------------
    // Transfer `tokens` from the `from` account to the `to` account
    // ------------------------------------------------------------------------
    function transferFrom(address from, address to, uint tokens) public isRunnning returns (bool success) {
        require(tokens <= balances[from]);
        require(tokens <= allowed[from][msg.sender]);
        require(tokens != 0);
        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        Transfer(from, to, tokens);
        return true;
    }


    // ------------------------------------------------------------------------
    // Returns the amount of tokens approved by the owner that can be
    // transferred to the spender's account
    // ------------------------------------------------------------------------
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }


    // ------------------------------------------------------------------------
    // Token owner can approve for `spender` to transferFrom(...) `tokens`
    // from the token owner's account. The `spender` contract function
    // `receiveApproval(...)` is then executed
    // ------------------------------------------------------------------------
    function approveAndCall(address spender, uint tokens, bytes data) public isRunnning returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;
    }


    // ------------------------------------------------------------------------
    // Owner can transfer out any accidentally sent ERC20 tokens
    // ------------------------------------------------------------------------
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }


    // ------------------------------------------------------------------------
    // Tokens burn
    // ------------------------------------------------------------------------
    function burnTokens(uint256 tokens) public returns (bool success) {
        require(tokens <= balances[msg.sender]);
        require(tokens != 0);
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        _totalSupply = _totalSupply.sub(tokens);
        Transfer(msg.sender, address(0), tokens);
        return true;
    }    


    // ------------------------------------------------------------------------
    // Tokens multisend from owner only by owner
    // ------------------------------------------------------------------------
    function multisend(address[] to, uint256[] values) public onlyOwner returns (uint256) {
        uint256 i = 0;
        while (i < to.length) {
            balances[owner] = balances[owner].sub(values[i]);
            balances[to[i]] = balances[to[i]].add(values[i]);
            Transfer(owner, to[i], values[i]);
            i += 1;
        }
        return(i);
    }


    // ------------------------------------------------------------------------
    // Sale from external contract only from sale contract
    // ------------------------------------------------------------------------

    modifier onlySaleConract(){
        require(msg.sender == saleAddress);
        _;
    }

    function setSaleAddress(address newSaleAddress) public onlyOwner returns (bool) {
        saleAddress = newSaleAddress;
        return true;
    }

    function sale(address to, uint tokens) external onlySaleConract returns (bool success) {
        require(tokens <= balances[owner]);
        require(tokens != 0);
        balances[owner] = balances[owner].sub(tokens);
        balances[to] = balances[to].add(tokens);
        Transfer(owner, to, tokens);
        return true;
    }
}
