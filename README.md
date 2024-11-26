# About

1. Create a basic AA on Ethereum
2. Create a basic AA on zkSYnc
3. Deploy, and send a userOp/ transaction through them
   1. not going to send an AA to ethereum
   2. but we will send an AA tx to zksync

## Mid-Session Recap

<blockquote>
We create a Minimal account that takes into account Ethereum's Minimal Account Abstraction. Account abstraction defines that anything can sign transactions and not just a privateKey. To send a transaction, we sign the data and send the data to alt mempool Nodes and they combine everything into UserOp and call handleOps into entrypoint contract and if it looks good and it will call the minimal account and that can do the dapp and call it. We can setup a PayMaster where someone else can pay for the gas and we can let "something" sign our transactions and we can create filters rules. 


UserOp will call our contract and call our custom logic and check the custom logic we built in our smart contract.
</blockquote>

<img src="./img/account-abstraction-again.png">