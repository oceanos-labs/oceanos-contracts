// SPDX-License-Identifier: UNLICENSED

import "@pythnetwork/pyth-sdk-solidity/IPyth.sol";
import "@pythnetwork/pyth-sdk-solidity/PythStructs.sol";

import "../interfaces/IPriceCalculator.sol";

contract WemixPriceOracle is IPriceCalculator {
    address internal constant WEMIX =
        0x0000000000000000000000000000000000000000;
    uint256 private constant THRESHOLD = 15 minutes;

    /* ========== STATE VARIABLES ========== */
    address public gov;
    address public keeper;
    mapping(address => ReferenceData) public references; // 8 decimals of precision
    mapping(address => bytes32) private priceIds; // 0xf63f008474fad630207a1cfa49207d59bca2593ea64fc0a6da9bf3337485791c
    mapping(address => IPyth) public priceFeeds; // 0xA2aa501b19aff244D90cc15a4Cf739D2725B5729

    /* ========== MODIFIERS ========== */

    /// @dev `msg.sender` 가 keeper 또는 owner 인지 검증
    modifier onlyKeeper() {
        require(
            msg.sender == keeper || msg.sender == gov,
            "PriceCalculator: caller is not the owner or keeper"
        );
        _;
    }

    /* ========== INITIALIZER ========== */

    constructor() {
        gov = msg.sender;
        keeper = msg.sender;
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function setKeeper(address _keeper) external onlyKeeper {
        require(
            _keeper != address(0),
            "PriceCalculator: invalid keeper address"
        );
        keeper = _keeper;
    }

    function setPriceId(address asset, bytes32 priceId) external onlyKeeper {
        priceIds[asset] = priceId;
    }

    function setPriceFeed(address asset, IPyth priceFeed) external onlyKeeper {
        priceFeeds[asset] = priceFeed;
    }

    /// @notice Set price by keeper
    /// @param assets Array of asset addresses to set
    /// @param prices Array of asset prices to set
    /// @param timestamp Timstamp of price information
    function setPrices(
        address[] memory assets,
        uint256[] memory prices,
        uint256 timestamp
    ) external onlyKeeper {
        require(
            timestamp <= block.timestamp &&
                block.timestamp - timestamp <= THRESHOLD,
            "PriceCalculator: invalid timestamp"
        );

        for (uint256 i = 0; i < assets.length; i++) {
            references[assets[i]] = ReferenceData({
                lastData: prices[i],
                lastUpdated: block.timestamp
            });
        }
    }

    /* ========== VIEWS ========== */

    function priceOf(
        address asset
    ) public view override returns (uint256 priceInUSD) {
        if (asset == address(0)) {
            return priceOfETH();
        }

        (uint256 price, ) = _getLatestPrice(asset);

        return price * 1e10;
    }

    function priceOfETH() public view returns (uint256 valueInUSD) {
        (uint256 price, ) = _getLatestPrice(WEMIX);

        return price * 1e10;
    }

    /* ========== PRIVATE FUNCTIONS ========== */
    function _getLatestPrice(
        address token
    ) internal view returns (uint256, uint256) {
        require(address(priceFeeds[token]) != address(0), "missing priceFeed");

        PythStructs.Price memory priceData;

        try
            priceFeeds[token].getPriceNoOlderThan(priceIds[token], THRESHOLD)
        returns (PythStructs.Price memory _priceData) {
            priceData = _priceData;
        } catch {
            // try get from reference
            ReferenceData memory referenceToken = references[token];

            if (block.timestamp - referenceToken.lastUpdated > THRESHOLD) {
                revert("price is too old");
            }

            priceData.price = int64(uint64(referenceToken.lastData));
            priceData.publishTime = referenceToken.lastUpdated;
        }

        require(priceData.price > 0, "price cannot be zero");
        uint256 uPrice = uint256(uint64(priceData.price));

        return (uPrice, priceData.publishTime);
    }
}
