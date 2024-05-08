-include .env

deploy-sepolia:
	forge script script/DeployTeachingContract.s.sol --rpc-url $(SEPOLIA_RPC_URL) --account sep --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv

deploy-anvil:
	forge script script/DeployTeachingContract.s.sol --account dev --broadcast