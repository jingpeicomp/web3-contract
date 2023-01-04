// SPDX-License-Identifier: MIT
// Tells the Solidity compiler to compile only from v0.8.13 to v0.9.0
pragma solidity ^0.8.13;

import "../node_modules/@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";
import "../node_modules/@openzeppelin/contracts/utils/Strings.sol";

contract Mall3Goods is ERC1155 {
    /**
     * 合约拥有者，一般是平台
     */
    address private _builder;

    /**
     * 商品价格，单位 Gwei。 tokenID ---> price
     */
    mapping(uint256 => uint256) private _prices;

    /**
     * 商品拥有者，tokenID ---> address
     */
    mapping(uint256 => address) private _owners;

    /**
     * 商品卡号ID数组
     */
    uint256[] private _tokens;

    /**
     * 智能合约meta数据
     */
    string private _contractUrl;

    modifier condition(bool condition_, string memory info) {
        require(condition_, info);
        _;
    }

    constructor(
        address to,
        uint256[] memory itemIds,
        uint256 price,
        string memory contractUrl
    )
        ERC1155(
            "https://cdn.jsdelivr.net/gh/jingpeicomp/mall3-nft-meta/2022-12-26/{id}.json"
        )
    {
        require(to != address(0), "Mall3Goods: construct to the zero address");
        require(
            itemIds.length > 0 && itemIds.length < type(uint16).max,
            string(
                abi.encodePacked(
                    "Mall3Goods: the size of item id should be between 1 and ",
                    type(uint16).max
                )
            )
        );

        uint256[] memory amounts = new uint256[](itemIds.length);
        _tokens = itemIds;
        for (uint16 _i = 0; _i < itemIds.length; _i++) {
            amounts[_i] = 1;
            _prices[itemIds[_i]] = price;
            _owners[itemIds[_i]] = to;
        }
        _mintBatch(to, itemIds, amounts, "");
        _builder = _msgSender();
        _contractUrl = contractUrl;
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() ||
                isApprovedForAll(from, _msgSender()) ||
                _builder == _msgSender(),
            "Mall3Goods: caller is not token owner or approved or builder"
        );
        _safeTransferFrom(from, to, id, amount, data);
        _owners[id] = to;
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() ||
                isApprovedForAll(from, _msgSender()) ||
                _builder == _msgSender(),
            "ERC1155: caller is not token owner or approved or builder"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
        for (uint256 _i = 0; _i < ids.length; _i++) {
            _owners[ids[_i]] = to;
        }
    }

    /**
     * 不支持此操作
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
    {}

    /**
     * 不支持此操作
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
        return false;
    }

    /**
     * 购买商品
     */
    function buy(uint256 tokenId)
        public
        payable
        condition(
            msg.value == _prices[tokenId] * (10**9),
            string(
                abi.encodePacked(
                    "Mall3Goods: price is invalid, msg value ",
                    Strings.toString(msg.value),
                    " price ",
                    Strings.toString(_prices[tokenId])
                )
            )
        )
    {
        payable(_owners[tokenId]).transfer(_prices[tokenId] * (10**9));
        _safeTransferFrom(_owners[tokenId], _msgSender(), tokenId, 1, "");
        _owners[tokenId] = _msgSender();
    }

    /**
     * 转让商品
     */
    function transfer(uint256 tokenId, address to)
        public
        condition(
            msg.sender == _owners[tokenId] || msg.sender == _builder,
            "Mall3Goods: only owner or builder can transfer"
        )
    {
        safeTransferFrom(_owners[tokenId], to, tokenId, 1, "");
    }

    /**
     * 设置商品价格
     */
    function setPrice(uint256 tokenId, uint256 price)
        public
        condition(
            msg.sender == _owners[tokenId],
            "Mall3Goods: only owner can set price"
        )
        condition(price > 0, "Mall3Goods: price is invalid")
    {
        _prices[tokenId] = price;
    }

    /**
     * 获取用户拥有的所有商品信息
     */
    function getItems() public view returns (uint256[] memory) {
        uint16 _pos = 0;
        for (uint16 _i = 0; _i < _tokens.length; _i++) {
            if (_owners[_tokens[_i]] == _msgSender()) {
                _pos++;
            }
        }

        if (_pos > 0) {
            return new uint256[](0);
        }

        uint256[] memory itemIds = new uint256[](_pos);
        _pos = 0;
        for (uint16 _i = 0; _i < _tokens.length; _i++) {
            if (_owners[_tokens[_i]] == _msgSender()) {
                itemIds[_pos++] = _tokens[_i];
            }
        }

        return itemIds;
    }

    /**
     * 获取商品持有者地址
     */
    function getItemOwner(uint256 tokenId) public view returns (address) {
        return _owners[tokenId];
    }

    /**
     * 销毁商品
     */
    function burn(uint256 tokenId) public {
        require(
            _msgSender() == _builder,
            "Mall3Goods: only platform could burn token"
        );
        //执行销毁
        _burn(_owners[tokenId], tokenId, 1);
        _owners[tokenId] = address(0);
    }

    /**
     * opensea 智能合约metadata
     */
    function contractURI() public view returns (string memory) {
        return _contractUrl;
    }

    fallback() external payable {}

    receive() external payable {}
}
