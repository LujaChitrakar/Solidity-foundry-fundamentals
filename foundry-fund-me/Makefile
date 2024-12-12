# makefile is used like commands to simplify the compile commands

-include .env

# make build=forge build
build:
	forge build 

deploy-sepolia:
	forge script script/DeployFundMe.s.sol --rpc-url $(SEPOLIA_RPC_URL) --private-key $(PRIVATE_KEY) --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv

deploy-polygon:
	forge script script/DeployFundMe.s.sol --rpc-url $(POLYGON_RPC_URL) --private-key $(PRIVATE_KEY) --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv

test-sepolia:
	forge test --rpc-url $(SEPOLIA_RPC_URL)

test-polygon:
	forge test --rpc-url $(POLYGON_RPC_URL)