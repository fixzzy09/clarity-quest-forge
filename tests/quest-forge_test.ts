import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Test quest creation",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get("deployer")!;
    const wallet1 = accounts.get("wallet_1")!;

    let block = chain.mineBlock([
      Tx.contractCall(
        "quest-forge",
        "create-quest",
        [types.utf8("Test Quest"), types.uint(1)],
        wallet1.address
      ),
    ]);

    assertEquals(block.receipts[0].result.expectOk(), "u0");
  },
});

Clarinet.test({
  name: "Test quest completion",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get("deployer")!;
    const wallet1 = accounts.get("wallet_1")!;

    let block = chain.mineBlock([
      Tx.contractCall(
        "quest-forge",
        "create-quest",
        [types.utf8("Test Quest"), types.uint(1)],
        wallet1.address
      ),
      Tx.contractCall(
        "quest-forge",
        "complete-quest",
        [types.uint(0)],
        wallet1.address
      ),
    ]);

    assertEquals(block.receipts[1].result.expectOk(), true);
  },
});
