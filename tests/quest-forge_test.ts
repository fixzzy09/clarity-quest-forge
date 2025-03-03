import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

// [Previous tests remain unchanged]

Clarinet.test({
  name: "Test quest completion with re-entrancy protection",
  async fn(chain: Chain, accounts: Map<string, Account>) {
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
      // Attempt immediate second completion
      Tx.contractCall(
        "quest-forge",
        "complete-quest",
        [types.uint(0)],
        wallet1.address
      ),
    ]);

    assertEquals(block.receipts[1].result.expectOk(), true);
    assertEquals(block.receipts[2].result.expectErr(), "u103");
  },
});

Clarinet.test({
  name: "Test event range retrieval",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet1 = accounts.get("wallet_1")!;

    let block = chain.mineBlock([
      Tx.contractCall(
        "quest-forge",
        "create-quest",
        [types.utf8("Quest 1"), types.uint(1)],
        wallet1.address
      ),
      Tx.contractCall(
        "quest-forge",
        "create-quest",
        [types.utf8("Quest 2"), types.uint(2)],
        wallet1.address
      ),
    ]);

    let eventsResponse = chain.callReadOnlyFn(
      "quest-forge",
      "get-events",
      [types.uint(0), types.uint(1)],
      wallet1.address
    );

    let events = eventsResponse.result.expectOk();
    assertEquals(events.length, 2);
  },
});
