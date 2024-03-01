
SUAVEX_PRIVATE_KEY=ac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
SUAVEX_RPC_URL=http://localhost:8545

deploy-suavex-contract:
	forge create \
		--rpc-url $(SUAVEX_RPC_URL) \
		--private-key $(SUAVEX_PRIVATE_KEY) \
		test/protocols/Builder/Session.t.sol:Example --json | jq -r ".deployedTo"
