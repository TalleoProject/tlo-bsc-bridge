all: WrappedTalleoToken_sol_WrappedTalleoToken.abi TokenSwap_sol_TokenSwap.abi BalancedSwap_sol_BalancedSwap.abi TokenMarket_sol_TokenMarket.abi

SafeMath.sol: ../node_modules/@openzeppelin/contracts/math/SafeMath.sol
	@cp ../node_modules/@openzeppelin/contracts/math/SafeMath.sol SafeMath.sol

WrappedTalleoToken_sol_WrappedTalleoToken.abi: WrappedTalleoToken.sol IBEP20.sol SafeMath.sol
	@../node_modules/.bin/solcjs --base-path . --abi WrappedTalleoToken.sol IBEP20.sol SafeMath.sol

TokenSwap_sol_TokenSwap.abi: TokenSwap.sol IBEP20.sol SafeMath.sol
	@../node_modules/.bin/solcjs --base-path . --abi TokenSwap.sol IBEP20.sol SafeMath.sol

BalancedSwap_sol_BalancedSwap.abi: BalancedSwap.sol IBEP20.sol SafeMath.sol
	@../node_modules/.bin/solcjs --base-path . --abi BalancedSwap.sol IBEP20.sol SafeMath.sol

TokenMarket_sol_TokenMarket.abi: TokenMarket.sol IBEP20.sol SafeMath.sol
	@../node_modules/.bin/solcjs --base-path . --abi TokenMarket.sol IBEP20.sol SafeMath.sol
