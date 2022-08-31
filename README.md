# taptrust-contracts

This code repository incorporates modified versions of substantial portions of the [verite]() project code. The original copyright and permission notices for the verite project is included in this project's `LICENSE` file. 


### Getting Started


1. To install required dependencies, run the following command:

```sh
npm install
```

### Running a local Ethereum node

Running an Ethereum node is easily accomplished by using our built-in scripts for running a [HardHat](https://hardhat.org) node.

1. To start a local Ethereum node, simply run:

```sh
npm run hardhat:node
```

Now you have a local Ethereum node running. This process is long-lived and should remain open in it's own terminal tab.

2. Next, you will need to deploy the smart contracts to the local Ethereum network.

```sh
npm run hardhat:deploy
```


### Testing

Run tests by running

```sh
npm run hardhat:test
```