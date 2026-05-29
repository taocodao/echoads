import type { WalletClient } from "viem";
import { keccak256, encodePacked, createPublicClient, http, parseAbi } from "viem";
import { baseSepolia } from "viem/chains";

const ORACLE_ABI = parseAbi([
  "function recordDelivery(bytes32 impressionId, address node, uint256 cpmPaid, bytes calldata viewerSig) external returns (bytes32 podHash)",
  "event ProofOfDeliveryRecorded(bytes32 indexed podHash, address indexed viewer, address indexed node, uint256 cpmPaid, uint256 timestamp)"
]);

export class PoDClient {
  private wallet: WalletClient;
  private oracleAddress: `0x${string}`;
  private publicClient;

  constructor(viewerWallet: WalletClient, oracleAddress: string) {
    this.wallet = viewerWallet;
    this.oracleAddress = oracleAddress as `0x${string}`;
    this.publicClient = createPublicClient({
      chain: baseSepolia,
      transport: http(import.meta.env["VITE_BASE_SEPOLIA_RPC_URL"] ?? "https://sepolia.base.org")
    });
  }

  async submitProofOfDelivery(
    impressionId: `0x${string}`,
    nodeAddr: `0x${string}`,
    cpmPaid: bigint
  ): Promise<{ podHash: string; txHash: string; basescanUrl: string }> {
    const account = this.wallet.account;
    if (!account) throw new Error("Wallet not connected");

    const msgHash = keccak256(
      encodePacked(
        ["bytes32", "address", "uint256"],
        [impressionId, nodeAddr, cpmPaid]
      )
    );

    const signature = await this.wallet.signMessage({
      account,
      message: { raw: msgHash }
    });

    const txHash = await this.wallet.writeContract({
      account,
      address: this.oracleAddress,
      abi: ORACLE_ABI,
      functionName: "recordDelivery",
      args: [impressionId, nodeAddr, cpmPaid, signature],
      chain: baseSepolia
    });

    const receipt = await this.publicClient.waitForTransactionReceipt({ hash: txHash });
    
    let podHash = "0x";
    for (const log of receipt.logs) {
      if (log.address.toLowerCase() === this.oracleAddress.toLowerCase()) {
        if (log.topics[1]) {
           podHash = log.topics[1];
           break;
        }
      }
    }

    return {
      podHash,
      txHash,
      basescanUrl: `https://sepolia.basescan.org/tx/${txHash}`
    };
  }
}
