import { createWalletClient, http, keccak256, encodePacked, type `0x${string}` } from "viem";
import { privateKeyToAccount } from "viem/accounts";
import { baseSepolia } from "viem/chains";

/**
 * Oracle signing service.
 * Signs delivery proof payloads with the trusted backend key.
 * The signature is submitted to DeliveryOracle.sol for CMXS reward minting.
 *
 * Phase 1 upgrade: replace this signer with a Chainlink CRE workflow.
 * Set oracle.updateTrustedSigner(creContractAddress) — no other changes needed.
 */

const ORACLE_PRIVATE_KEY = process.env["ORACLE_PRIVATE_KEY"] as `0x${string}`;

if (!ORACLE_PRIVATE_KEY || ORACLE_PRIVATE_KEY === "0x") {
  console.warn("[oracle] ORACLE_PRIVATE_KEY not set — proof signing will fail.");
}

const signerAccount = privateKeyToAccount(ORACLE_PRIVATE_KEY ?? "0x0");

const signerClient = createWalletClient({
  account: signerAccount,
  chain: baseSepolia,
  transport: http(process.env["BASE_SEPOLIA_RPC_URL"]),
});

export interface DeliveryProofParams {
  deliveryId: `0x${string}`;
  nodeOperator: `0x${string}`;
  segmentCount: bigint;
  latencyMs: bigint;
  expiry: bigint;
}

/**
 * Sign a delivery proof for submission to DeliveryOracle.sol
 * The message matches exactly what the contract verifies:
 *   keccak256(abi.encodePacked(deliveryId, nodeOperator, segmentCount, latencyMs, expiry, chainId))
 */
export async function signDeliveryProof(params: DeliveryProofParams): Promise<`0x${string}`> {
  const CHAIN_ID = BigInt(process.env["CHAIN_ID"] ?? "84532");

  const messageHash = keccak256(
    encodePacked(
      ["bytes32", "address", "uint256", "uint256", "uint256", "uint256"],
      [
        params.deliveryId,
        params.nodeOperator,
        params.segmentCount,
        params.latencyMs,
        params.expiry,
        CHAIN_ID,
      ]
    )
  );

  // signMessage applies the Ethereum signed message prefix (\x19Ethereum Signed Message:\n32)
  // matching MessageHashUtils.toEthSignedMessageHash() in the Solidity contract
  const signature = await signerAccount.signMessage({
    message: { raw: messageHash },
  });

  return signature;
}

export function getOracleSignerAddress(): string {
  return signerAccount.address;
}
