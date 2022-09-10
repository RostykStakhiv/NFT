// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import "./IERC721.sol";
import "./IERC721Receiver.sol";

abstract contract ERC721 is IERC721 {
    string private _name;
    string private _symbol;

    mapping(uint256 => address) private _ownerships;
    mapping(address => uint16) private _balances;
    mapping(uint256 => address) _approvals;
    mapping(address => mapping(address => bool)) _approvedOperators;

    constructor(string memory name, string memory symbol) {
        _name = name;
        _symbol = symbol;
    }

    function balanceOf(address owner) external view returns (uint256) {
        require(
            owner != address(0),
            "Cannot perform that query for zero address"
        );
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) external view returns (address) {
        return _ownerships[tokenId];
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable {
        address owner = this.ownerOf(tokenId);
        require(
            _isAuthorizedSpenderForToken(msg.sender, tokenId),
            "Only owner, authorized account operator or authorized token operator can perform this action"
        );
        require(from == owner, "from address should be owner's address");
        require(to != address(0), "to cannot be zero address");
        require(_isValidTokenId(tokenId), "Invalid token ID");

        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) external payable {
        require(
            _isAuthorizedSpenderForToken(msg.sender, tokenId),
            "Only autorized spender can perform this action"
        );
        _safeTransfer(from, to, tokenId, data);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable {
        require(
            _isAuthorizedSpenderForToken(msg.sender, tokenId),
            "Only autorized spender can perform this action"
        );
        _safeTransfer(from, to, tokenId, "");
    }

    function approve(address approved, uint256 tokenId) external payable {
        address tokenOwner = this.ownerOf(tokenId);
        require(
            approved != tokenOwner,
            "Cannot make owner an approved operator"
        );
        require(
            _isOwnerOrAuthorizedOperatorForOwner(msg.sender, tokenOwner),
            "Only owner or authorized operator can call this method"
        );
        _setApprovalForToken(approved, tokenId);
    }

    function setApprovalForAll(address operator, bool approved) external {
        _approvedOperators[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function getApproved(uint256 tokenId) external view returns (address) {
        return _approvals[tokenId];
    }

    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool)
    {
        return _approvedOperators[owner][operator];
    }

    function _isOwnerOrAuthorizedOperatorForOwner(
        address operator,
        address owner
    ) private view returns (bool) {
        return operator == owner || this.isApprovedForAll(owner, operator);
    }

    function _isAuthorizedOperatorForTokenId(address operator, uint256 tokenId)
        private
        view
        returns (bool)
    {
        return _approvals[tokenId] == operator;
    }

    function _isAuthorizedSpenderForToken(address spender, uint256 tokenId)
        private
        view
        returns (bool)
    {
        require(_isValidTokenId(tokenId), "nonexistent token");
        address tokenOwner = this.ownerOf(tokenId);
        return
            _isOwnerOrAuthorizedOperatorForOwner(spender, tokenOwner) ||
            _isAuthorizedOperatorForTokenId(spender, tokenId);
    }

    function _isValidTokenId(uint256 tokenId) private view returns (bool) {
        return this.ownerOf(tokenId) != address(0);
    }

    function _setApprovalForToken(address approvedAddress, uint256 tokenId)
        private
    {
        _approvals[tokenId] = approvedAddress;

        emit Approval(this.ownerOf(tokenId), approvedAddress, tokenId);
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) private {
        address tokenOwner = this.ownerOf(tokenId);
        require(from == tokenOwner, "from should be the token owner");
        require(to != address(0), "Cannot transfer to zero address");

        _setApprovalForToken(address(0), tokenId);

        _ownerships[tokenId] = to;
        _balances[from] = _balances[from] - 1;
        _balances[to] = _balances[to] + 1;

        emit Transfer(from, to, tokenId);
    }

    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private {
        _transfer(from, to, tokenId);
        require(_checkIfERC721Received(from, to, tokenId, data));
    }

    function _checkIfERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (_isContract(to)) {
            try
                IERC721Receiver(to).onERC721Received(
                    msg.sender,
                    from,
                    tokenId,
                    data
                )
            returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory errorMsg) {
                if (errorMsg.length == 0) {
                    revert(
                        "transfer to a contract that does not implement ERC721Receiver interface"
                    );
                } else {
                    assembly {
                        revert(add(32, errorMsg), mload(errorMsg))
                    }
                }
            }
        } else {
            return true;
        }
    }

    function _isContract(address account) private view returns (bool) {
        return account.code.length > 0;
    }
}
