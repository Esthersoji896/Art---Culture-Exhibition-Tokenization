import { Clarinet, Tx, Chain, Account, types } from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { Buffer } from "https://deno.land/std@0.110.0/node/buffer.ts";

Clarinet.test({
  name: "Ensure can mint new art token",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get("deployer")!;

    let block = chain.mineBlock([
      Tx.contractCall("art-culture-exhibition", "mint", [
        types.ascii("Mona Lisa"),
        types.ascii("Leonardo da Vinci"),
        types.uint(1503),
        types.ascii("Oil on wood"),
        types.ascii("Famous portrait painting"),
        types.ascii("Italy"),
        types.buff(new Uint8Array(Buffer.from("authenticity-hash"))),
        types.ascii("ipfs://QmHash")
      ], deployer.address)
    ]);

    block.receipts[0].result.expectOk().expectUint(1);
  }
});

Clarinet.test({
  name: "Ensure can list and buy token",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get("deployer")!;
    const buyer = accounts.get("wallet_1")!;

    let block = chain.mineBlock([
      Tx.contractCall("art-culture-exhibition", "mint", [
        types.ascii("Starry Night"),
        types.ascii("Van Gogh"),
        types.uint(1889),
        types.ascii("Oil on canvas"),
        types.ascii("Post-impressionist masterpiece"),
        types.ascii("France"),
        types.buff(new Uint8Array(Buffer.from("authenticity-hash"))),
        types.ascii("ipfs://QmHash")
      ], deployer.address),
      Tx.contractCall("art-culture-exhibition", "list-token", [
        types.uint(1),
        types.uint(1000000)
      ], deployer.address)
    ]);

    block.receipts.forEach((receipt: any) => receipt.result.expectOk());

    block = chain.mineBlock([
      Tx.contractCall("art-culture-exhibition", "buy-token", [
        types.uint(1)
      ], buyer.address)
    ]);

    block.receipts[0].result.expectOk();
  }
});