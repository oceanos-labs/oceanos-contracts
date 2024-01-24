// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../interfaces/IMultiIncentive.sol";
import "../../interfaces/IOcUSD.sol";
import "../../interfaces/IERC20Detailed.sol";
import "../../interfaces/IPriceCalculator.sol";

/// @title PoolBase
/// @author oceanos
/// @notice Base contract for depositing collateral and minting ocUSD
abstract contract PoolBase {
    IOcUSD public ocUsd;
    IERC20 public collateralAsset;

    mapping(address => uint256) public collateralAmount; // collateral deposited by user
    mapping(address => uint256) public borrowedAmount; // ocUSD borrowed by user (including fee)
    uint256 public poolIssuedOcUSD; // total ocUSD minted by pool

    IPriceCalculator public priceCalculator;
    address public gov;
    address public feeReceiver; //

    // ========= POOL CONFIGURATION ===============//

    uint256 public maxTotalMintAmount; // maximum poolIssuedOcUSD, default type(uint256 public ).max

    uint256 public minMintAmount; // minimum mint amount, default 1

    uint256 public mintFee; // 10000 = 100%, default 0.1%

    uint256 public normalRedemptionFee; // 10000 = 100%, default 1%

    uint256 public protectionRedemptionFee; // 10000 = 100 %, default 0.5%

    uint256 public safeCollateralRatio; // 10000 = 100% , default 150%

    uint256 public protectionCollateralRatio; // 10000 = 100%, default 150%

    uint256 public liquidationCollateralRatio; // 10000 = 100%, default 120%

    uint256 public liquidationBonus; // 11000 = 10% of collateral plus, default 20%

    uint256 public liquidationProtocolRatio; // 10000 = 100%, default 50%

    address public mintIncentivePool;

    address public collateralIncentivePool;

    // ========= POOL CONFIGURATION END =============== //

    // ========= MODIFIER =============== //

    modifier onlyGov() {
        require(msg.sender == gov, "not gov");
        _;
    }

    // ========= INITIALIZER =============== //

    function _initialize(IOcUSD _ocUsd, IERC20 _collateral) internal virtual {
        ocUsd = _ocUsd;
        collateralAsset = _collateral;

        gov = msg.sender;
        feeReceiver = msg.sender;

        emit SetGov(address(0), gov, block.timestamp);
        emit SetFeeReceiver(address(0), feeReceiver, block.timestamp);
    }

    // ========= GOV FUNCTIONS =============== //

    function setGov(address _gov) external onlyGov {
        require(_gov != address(0), "zero address");

        emit SetGov(gov, _gov, block.timestamp);

        gov = _gov;
    }

    function setFeeReceiver(address _feeReceiver) external onlyGov {
        require(_feeReceiver != address(0), "zero address");

        emit SetFeeReceiver(feeReceiver, _feeReceiver, block.timestamp);

        feeReceiver = _feeReceiver;
    }

    function setPriceCalculator(
        IPriceCalculator _priceCalculator
    ) external onlyGov {
        require(address(_priceCalculator) != address(0), "zero address");

        emit SetPriceCalculator(
            address(priceCalculator),
            address(_priceCalculator),
            block.timestamp
        );

        priceCalculator = _priceCalculator;
    }

    function setPoolConfiguration(
        uint256 _maxTotalMintAmount,
        uint256 _minMintAmount,
        uint256 _mintFee,
        uint256 _normalRedemptionFee,
        uint256 _protectionRedemptionFee,
        uint256 _safeCollateralRatio,
        uint256 _protectionCollateralRatio,
        uint256 _liquidationCollateralRatio,
        uint256 _liquidationBonus,
        uint256 _liquidationProtocolRatio
    ) external onlyGov {
        maxTotalMintAmount = _maxTotalMintAmount;
        minMintAmount = _minMintAmount;
        mintFee = _mintFee;
        normalRedemptionFee = _normalRedemptionFee;
        protectionRedemptionFee = _protectionRedemptionFee;
        safeCollateralRatio = _safeCollateralRatio;
        protectionCollateralRatio = _protectionCollateralRatio;
        liquidationCollateralRatio = _liquidationCollateralRatio;
        liquidationBonus = _liquidationBonus;
        liquidationProtocolRatio = _liquidationProtocolRatio;

        emit SetPoolConfiguration(
            _maxTotalMintAmount,
            _minMintAmount,
            _mintFee,
            _normalRedemptionFee,
            _protectionRedemptionFee,
            _safeCollateralRatio,
            _protectionCollateralRatio,
            _liquidationCollateralRatio,
            _liquidationBonus,
            _liquidationProtocolRatio,
            block.timestamp
        );
    }

    function setMintIncentivePool(address _mintIncentivePool) external onlyGov {
        emit SetMintIncentivePool(
            mintIncentivePool,
            _mintIncentivePool,
            block.timestamp
        );

        mintIncentivePool = _mintIncentivePool;
    }

    function setCollateralIncentivePool(
        address _collateralIncentivePool
    ) external onlyGov {
        emit SetCollateralIncentivePool(
            collateralIncentivePool,
            _collateralIncentivePool,
            block.timestamp
        );

        collateralIncentivePool = _collateralIncentivePool;
    }

    // ========= GETTER =============== //

    // returns price in 18 decimals vitual function
    function getAssetPrice() public view virtual returns (uint256);

    function totalCollateralAmount() public view virtual returns (uint256) {
        return
            address(collateralAsset) == address(0)
                ? address(this).balance
                : collateralAsset.balanceOf(address(this));
    }

    function getAsset() external view returns (address) {
        return address(collateralAsset);
    }

    function collateralRatio(
        address user
    ) external view virtual returns (uint256) {
        return ((collateralAmount[user] * getAssetPrice() * 10000) /
            borrowedAmount[user] /
            _adjustDecimals());
    }

    // ========= INTERNAL =============== //

    // check after every function that changes user status,  collateral ratio is above safeCollateralRatio
    function _inSafeZone(
        address user,
        uint256 price
    ) internal view virtual returns (bool) {
        require(
            ((collateralAmount[user] * price * 10000) /
                borrowedAmount[user] /
                _adjustDecimals()) >= safeCollateralRatio,
            "collateral ratio is Below safeCollateralRatio"
        );

        return true;
    }

    function _adjustDecimals() internal view virtual returns (uint256) {
        uint8 decimals;
        if (address(collateralAsset) == address(0)) {
            decimals = 18;
        } else {
            decimals = IERC20Detailed(address(collateralAsset)).decimals();
        }
        return 10 ** uint256(decimals);
    }

    // ========= MUTABLES =============== //

    function mint(
        uint256 assetAmount,
        uint256 mintAmount
    ) external payable virtual {
        if (assetAmount > 0) {
            if (collateralIncentivePool != address(0)) {
                try
                    IMultiIncentive(collateralIncentivePool).refreshReward(
                        msg.sender
                    )
                {} catch {}
            }

            _safeTransferIn(msg.sender, assetAmount);
            collateralAmount[msg.sender] += assetAmount;

            emit Deposit(msg.sender, assetAmount, block.timestamp);
        }

        if (mintAmount > 0) {
            uint256 assetPrice = getAssetPrice();
            _mint(msg.sender, mintAmount, assetPrice);
        }
    }

    function withdraw(uint256 amount) external virtual {
        require(amount > 0, " > 0 ");
        _withdraw(msg.sender, amount);
    }

    function repay(address onBehalfOf, uint256 amount) external virtual {
        require(onBehalfOf != address(0), " != address(0)");
        require(amount > 0, " > 0 ");
        _repay(msg.sender, onBehalfOf, amount);
    }

    function _mint(
        address _user,
        uint256 _mintAmount,
        uint256 _assetPrice
    ) internal virtual {
        require(
            poolIssuedOcUSD + _mintAmount <= maxTotalMintAmount,
            "mint amount exceeds maximum mint amount"
        );
        require(
            _mintAmount >= minMintAmount,
            "mint amount is below minimum mint amount"
        );

        // try to call minterIncentivePool to refresh reward before update mint status
        if (mintIncentivePool != address(0)) {
            try
                IMultiIncentive(mintIncentivePool).refreshReward(_user)
            {} catch {}
        }

        uint256 mintFeeAmount = (_mintAmount * mintFee) / 10000;

        uint256 debtMintAmount = _mintAmount + mintFeeAmount;

        borrowedAmount[_user] += debtMintAmount; // increase debt
        poolIssuedOcUSD += debtMintAmount; // increase pool debt

        ocUsd.mint(_user, _mintAmount); // mint ocUsd excluding fee
        ocUsd.mint(feeReceiver, mintFeeAmount); // mint ocUsd fee to feeReceiver

        // check if user is in safe zone
        _inSafeZone(_user, _assetPrice);

        emit Mint(_user, debtMintAmount, mintFeeAmount, block.timestamp);
    }

    function _repay(
        address _user,
        address _onBehalfOf,
        uint256 _amount
    ) internal virtual {
        require(
            borrowedAmount[_onBehalfOf] >= _amount,
            "repay amount exceeds borrowed amount"
        );

        if (mintIncentivePool != address(0)) {
            try
                IMultiIncentive(mintIncentivePool).refreshReward(_onBehalfOf)
            {} catch {}
        }

        if (_amount > 0) {
            ocUsd.transferFrom(_user, address(this), _amount);
            ocUsd.burn(address(this), _amount);
            borrowedAmount[_onBehalfOf] -= _amount;
            poolIssuedOcUSD -= _amount;
        }

        emit Repay(_user, _onBehalfOf, _amount, block.timestamp);
    }

    function _withdraw(address _user, uint256 _amount) internal {
        require(
            collateralAmount[_user] >= _amount,
            "Withdraw amount exceeds deposited amount."
        );

        if (collateralIncentivePool != address(0)) {
            try
                IMultiIncentive(collateralIncentivePool).refreshReward(_user)
            {} catch {}
        }

        collateralAmount[_user] -= _amount;
        _safeTransferOut(_user, _amount);

        if (borrowedAmount[_user] > 0) {
            _inSafeZone(_user, getAssetPrice());
        }
        emit Withdraw(_user, _amount, block.timestamp);
    }

    /// @notice redemption func ocUsd to get collateral asset selecting any collateral provider with fee
    /// @param _target address of collateral provider
    /// @param _repayAmount amount of collateral asset to repay on behalf of _target
    /// @return uint256 that returns amount of collateral asset to get
    function redeem(
        address _target,
        uint256 _repayAmount // collateral asset amount
    ) external virtual returns (uint256) {
        require(_repayAmount > 0, " > 0 ");

        // 1. repay ocUsd
        _repay(msg.sender, _target, _repayAmount);

        uint256 assetPrice = getAssetPrice();
        uint256 assetAmount = (_repayAmount * _adjustDecimals()) / assetPrice;

        // 2. current mode
        uint256 currentPoolCollateralRatio = ((totalCollateralAmount() *
            assetPrice *
            10000) /
            poolIssuedOcUSD /
            _adjustDecimals());

        uint256 redemptionFee = currentPoolCollateralRatio >=
            protectionCollateralRatio
            ? normalRedemptionFee
            : protectionRedemptionFee;

        assetAmount = (assetAmount * (10000 - redemptionFee)) / 10000;

        if (collateralIncentivePool != address(0)) {
            try
                IMultiIncentive(collateralIncentivePool).refreshReward(_target)
            {} catch {}
        }
        collateralAmount[_target] -= assetAmount;
        _safeTransferOut(msg.sender, assetAmount);

        emit Redemption(
            msg.sender,
            _target,
            _repayAmount,
            assetAmount,
            block.timestamp
        );

        if (borrowedAmount[_target] > 0) {
            _inSafeZone(_target, assetPrice);
        }

        return assetAmount;
    }

    function liquidation(
        address onBehalfOf,
        uint256 assetAmount // collateral asset amount
    ) external virtual {
        uint256 assetPrice = getAssetPrice();
        uint256 onBehalfOfCollateralRatio = (collateralAmount[onBehalfOf] *
            assetPrice *
            10000) /
            borrowedAmount[onBehalfOf] /
            _adjustDecimals();
        require(
            onBehalfOfCollateralRatio < liquidationCollateralRatio,
            "Borrowers collateral ratio should below badCollateralRatio"
        );

        require(
            assetAmount * 2 <= collateralAmount[onBehalfOf],
            "a max of 50% collateral can be liquidated"
        );

        uint256 ocUsdAmount = (assetAmount * assetPrice) / _adjustDecimals();

        _repay(msg.sender, onBehalfOf, ocUsdAmount);

        uint256 bonusAmount = (assetAmount * liquidationBonus) / 10000;

        uint256 protocolAmount = (bonusAmount * liquidationProtocolRatio) /
            10000;

        uint256 reducedAsset = assetAmount + bonusAmount;

        if (collateralIncentivePool != address(0)) {
            try
                IMultiIncentive(collateralIncentivePool).refreshReward(
                    onBehalfOf
                )
            {} catch {}
        }
        collateralAmount[onBehalfOf] -= reducedAsset;
        _safeTransferOut(msg.sender, reducedAsset - protocolAmount);
        _safeTransferOut(feeReceiver, protocolAmount);

        emit Liquidate(
            onBehalfOf,
            msg.sender,
            ocUsdAmount,
            reducedAsset,
            protocolAmount,
            block.timestamp
        );
    }

    function _safeTransferIn(
        address from,
        uint256 amount
    ) internal virtual returns (bool) {
        if (address(collateralAsset) == address(0)) {
            require(msg.value == amount, "invalid msg.value");
            return true;
        } else {
            uint256 before = collateralAsset.balanceOf(address(this));
            collateralAsset.transferFrom(from, address(this), amount);
            require(
                collateralAsset.balanceOf(address(this)) >= before + amount,
                "transfer in failed"
            );
            return true;
        }
    }

    function _safeTransferOut(
        address to,
        uint256 amount
    ) internal virtual returns (bool) {
        if (address(collateralAsset) == address(0)) {
            (bool suc, ) = payable(to).call{value: amount}("");
            require(suc, "transfer out failed");
            return true;
        } else {
            collateralAsset.transfer(to, amount);
            return true;
        }
    }

    /* Events */

    event Deposit(
        address indexed account,
        uint256 collateralAmount,
        uint256 timestamp
    );
    event Withdraw(
        address indexed account,
        uint256 collateralAmount,
        uint256 timestamp
    );
    event Mint(
        address indexed account,
        uint256 totalMintAmount,
        uint256 feeAmount,
        uint256 timestamp
    );
    event Repay(
        address account,
        address indexed onbehalfOf,
        uint256 repayAmount,
        uint256 timestamp
    );

    event Redemption(
        address account,
        address indexed provider,
        uint256 ocUsdAmount,
        uint256 assetAmount,
        uint256 timestamp
    );

    event Liquidate(
        address indexed accountToLiquidate,
        address indexed liquidator,
        uint256 repayAmount,
        uint256 collateralAmount,
        uint256 protocolAmount,
        uint256 timestamp
    );

    event SetGov(address prevAddress, address newAddress, uint256 timestamp);
    event SetFeeReceiver(
        address prevAddress,
        address newAddress,
        uint256 timestamp
    );
    event SetPriceCalculator(
        address prevAddress,
        address newAddress,
        uint256 timestamp
    );
    event SetMintIncentivePool(
        address prevAddress,
        address newAddress,
        uint256 timestamp
    );

    event SetCollateralIncentivePool(
        address prevAddress,
        address newAddress,
        uint256 timestamp
    );

    event SetPoolConfiguration(
        uint256 maxTotalMintAmount,
        uint256 minMintAmount,
        uint256 mintFee,
        uint256 normalRedemptionFee,
        uint256 protectionRedemptionFee,
        uint256 safeCollateralRatio,
        uint256 protectionCollateralRatio,
        uint256 liquidationCollateralRatio,
        uint256 liquidationBonus,
        uint256 liquidationProtocolRatio,
        uint256 timestamp
    );

    uint256[50] private __gap;

    receive() external payable {}
}
