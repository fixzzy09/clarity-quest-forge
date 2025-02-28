import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Test quest creation with valid difficulty",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet1 = accounts.get("wallet_1")!;

    let block = chain.mineBlock([
      Tx.contractCall(
        "quest-forge",
        "create-quest",
        [types.utf8("Test Quest"), types.uint(3)],
        wallet1.address
      ),
    ]);

    assertEquals(block.receipts[0].result.expectOk(), "u0");
  },
});

Clarinet.test({
  name: "Test quest creation with invalid difficulty",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet1 = accounts.get("wallet_1")!;

    let block = chain.mineBlock([
      Tx.contractCall(
        "quest-forge",
        "create-quest",
        [types.utf8("Test Quest"), types.uint(6)],
        wallet1.address
      ),
    ]);

    assertEquals(block.receipts[0].result.expectErr(), "u104");
  },
});

Clarinet.test({
  name: "Test quest creation with empty title",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet1 = accounts.get("wallet_1")!;

    let block = chain.mineBlock([
      Tx.contractCall(
        "quest-forge",
        "create-quest",
        [types.utf8(""), types.uint(3)],
        wallet1.address
      ),
    ]);

    assertEquals(block.receipts[0].result.expectErr(), "u105");
  },
});

Clarinet.test({  
  name: "Test quest completion and check completed-by field",
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
    ]);

    assertEquals(block.receipts[1].result.expectOk(), true);

    let questResponse = chain.callReadOnlyFn(
      "quest-forge",
      "get-quest",
      [types.uint(0)],
      wallet1.address
    );

    let quest = questResponse.result.expectOk().expectSome();
    assertEquals(quest.completed, true);
    assertEquals(quest['completed-by'].some, wallet1.address);
  },
});
