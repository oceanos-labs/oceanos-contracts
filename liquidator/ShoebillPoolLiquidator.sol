// // consider case if there is no enough tokens in pool to withdraw

// // 1. deposit collateral into shoebill pool (if needed) (if not enough tokens in shoebill pool, then deposit)

// // 2. can liquidate

// contract ShoebillPoolLiquidator is Initializable, OwnableUpgradeable {
//     using SafeERC20 for IERC20;
//     using SafeMath for uint256;

//     IERC20 public collateralAsset;
//     IShoebillERC20 public sbToken;
//     IPriceCalculator public priceCalculator;

//     uint256 public liquidationFee;

//     function initialize(
//         IERC20 _collateralAsset,
//         IShoebillERC20 _sbToken,
//         IPriceCalculator _priceCalculator,
//         uint256 _liquidationFee
//     ) external initializer {
//         __Ownable_init();

//         collateralAsset = _collateralAsset;
//         sbToken = _sbToken;
//         priceCalculator = _priceCalculator;
//         liquidationFee = _liquidationFee;
//     }

//     function setLiquidationFee(uint256 _liquidationFee) external onlyOwner {
//         liquidationFee = _liquidationFee;
//     }

//     function liquidate(address pool, address user, uint256 amount) external {
//         require(
//             msg.sender == pool,
//             "ShoebillPoolLiquidator: only pool can call"
//         );

//         uint256 collateralAmount = priceCalculator.getCollateralAmount(
//             address(collateralAsset),
//             amount
//         );

//         uint256 fee = collateralAmount.mul(liquidationFee).div(1e18);

//         collateralAsset.safeTransferFrom(
//             msg.sender,
//             address(this),
//             collateralAmount
//         );

//         collateralAsset.safeTransfer(owner(), fee);

//         collateralAsset.safeApprove(address(sbToken), collateralAmount);
//         sbToken.mint(collateralAmount);

//         sbToken.safeTransfer(pool, collateralAmount);
//     }
// }
