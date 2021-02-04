# Publisher

This script can `build` (compile and flatten), `deploy` and `verify` (on Etherscan) the Synthetix code to a testnet or mainnet.

## 1. Build

Will compile bytecode and ABIs for all `.sol` files found in `node_modules` and the `contracts` folder. It will output them in a `compiled` folder in the given build path (see below), along with the flattened source files under the folder `flattened`.

```bash
# build (flatten and compile all .SOL sources)
node publish build # "--help" for options
```

## 2. Deploy

Will attempt to deploy (or reuse) all of the contracts listed in the given `contract-flags` input file, as well as perform initial connections between the contracts.

:warning: **This step requires the `build` step having been run to compile the sources into ABIs and bytecode.**

> Note: this action will update in place both the [contract-flag input file](contract-flags.json) and the contract addresses output ([here's the rinkeby one for example](out/rinkeby/contracts.json)) in real time so that if any transactions fail, it can be restarted at the same place.

```bash
# deploy (take compiled SOL files and deploy)
node publish deploy # "--help" for options
```

### CLI Options

- `-a, --add-new-synths` Whether or not any new synths in the synths.json file should be deployed if there is no entry in the config file.
- `-b, --build-path [value]` Path for built files to go. (default of `./build` - relative to the root of this repo). The folders `compiled` and `flattened` will be made under this path and the respective files will go in there.
- `-c, --contract-deployment-gas-limit <value>` Contract deployment gas limit (default: 7000000 (7m))
- `-d, --deployment-path <value>` Path to a folder that has your input configuration file (`config.json`), the synths list (`synths.json`) and where your `deployment.json` file will be written (and read from if it currently exists). The `config.json` should be in the following format ([here's an example](deployed/rinkeby/config.json)):

  ```javascript
  // config.json
  {
    "ProxysUSD": {
      "deploy": true // whether or not to deploy this or use existing instance from any deployment.json file
    },

    ...
  }
  ```

  > Note: the advantage of supplying this folder over just usi`ng the network name is that you can have multiple deployments on the same network in different folders

- `-g, --gas-price <value>` Gas price in GWEI (default: "1")
- `-m, --method-call-gas-limit <value>` Method call gas limit (default: 150000)
- `-n, --network <value>` The network to run off. One of mainnet, kovan, rinkeby, rospen. (default: "kovan")
- `-o, --oracle <value>` The address of the oracle to use. (default: `0xac1e8b385230970319906c03a1d8567e3996d1d5` - used for all testnets)
- `-f, --fee-auth <value>` The address of the fee Authority to use for feePool. (default:
  `0xfee056f4d9d63a63d6cf16707d49ffae7ff3ff01` - used for all testnets)
  --oracle-gas-limit (no default: set to 0x5a556cc012642e9e38f5e764dccdda1f70808198)

### Examples

```bash
# deploy to rinkeby with 8 gwei gas
node publish deploy -n ropsten -d publish/deployed/ropsten -g 20
node publish deploy -n rinkeby -d publish/deployed/rinkeby -g 20
node publish deploy -n kovan -d publish/deployed/kovan -g 8
node publish deploy -n local -d publish/deployed/local -g 8
```

## 3. Verify

Will attempt to verify the contracts on Etherscan (by uploading the flattened source files and ABIs).

:warning: **Note: the `build` step is required for the ABIs and the `deploy` step for the live addresses to use.**

```bash
# verify (verify compiled sources by uploading flattened source to Etherscan via their API)
node publish verify # "--help" for options
```

### Examples

```bash
# verify on rinkeby.etherscan
node publish verify -n ropsten -d publish/deployed/ropsten
node publish verify -n rinkeby -d publish/deployed/rinkeby
node publish verify -n kovan -d publish/deployed/kovan
```

## 4. Nominate New Owner

For all given contracts, will invoke `nominateNewOwner` for the given new owner;

```bash
node publish nominate # "--help" for options
```

### Example

```bash
node publish nominate -n rinkeby -d publish/deployed/rinkeby -g 3 -c Synthetix -c ProxysUSD -o 0x0000000000000000000000000000000000000000
node publish nominate -o 0xB64fF7a4a33Acdf48d97dab0D764afD0F6176882 -n kovan -c ProxysUSD -d publish/deployed/kovan -g 20
```

## 5. Owner Actions

Helps the owner take ownership of nominated contracts and run any deployment tasks deferred to them.

```bash
node publish owner # "--help" for options
```

## 6. Remove Synths

Will attempt to remove all given synths from the `Synthetix` contract (as long as they have `totalSupply` of `0`) and update the `config.json` and `synths.json` for the deployment folder.

```bash
node publish remove-synths # "--help" for options
```

### Example

```bash
node publish remove-synths -n rinkeby -d publish/deployed/rinkeby -g 3 -s sRUB -s sETH
```

## 7. Replace Synths

Will attempt to replace all given synths with a new given `subclass`. It does this by disconnecting the existing TokenState for the Synth and attaching it to the new one.

```bash
node publish replace-synths # "--help" for options
```

## 7. Purge Synths

Will attempt purge the given synth with all token holders it can find. Uses the list of holders from mainnet, and as such won't do anything for other networks.

```bash
node publish purge-synths # "--help" for options
```

# When adding new synths

1. In the environment folder you are deploying to, add the synth key to the `synths.json` file. If you want the synth to be purgeable, add `subclass: "PurgeableSynth"` to the object.
2. [Optional] Run `build` if you've changed any source files, if not you can skip this step.
3. Run `deploy` as usual but add the `--add-new-synths` flag
4. Run `verify` as usual.

# Additional functionality

## Generate token file

Th `generate-token-list` command will generate an array of token proxy addresses for the given deployment to be used in the Synthetix website. The command outputs a JSON array to the console.

```bash
# output a list of token addresses, decimals and symbol names for all the token proxy contracts
node publish generate-token-list -d publish/deployed/mainnet

```

### CLI Options

- `-d, --deployment-path <value>` Same as `deploy` step above.

### Example

```bash
node publish generate-token-list -d publish/deployed/rinkeby/ > token-list.json
```


### LOCAL 

#### Install ganache-cli

```
npm install -g ganache-cli
```

#### Start Local Env

```
ganache-cli -l 8000000

Ganache CLI v6.12.1 (ganache-core: 2.13.1)

Available Accounts
==================
(0) 0xf35F9388d2343115cE9bb73F9c613Db5a3388E20 (100 ETH)
(1) 0xdA1830eF164B2BE1DccCCbCe1b9D0e1c3450A006 (100 ETH)
(2) 0x9888Cc3eAF922F293F83cB76676CE8671BD54C0e (100 ETH)
(3) 0x4AF2337aD2ae277Ed84Fd04DCdc431a543c7A84f (100 ETH)
(4) 0x3eB13ff12e389B5aBE0e19E667C1D441c8620cE6 (100 ETH)
(5) 0x8b2987354B9BA0175ed3E50d363eaD144FE648e9 (100 ETH)
(6) 0x88d5d6c04ECa1A4D680A97631415De6aD87049D5 (100 ETH)
(7) 0x2Ae9a44dCE8BFB26178fB9D90b1bF0F864806844 (100 ETH)
(8) 0x007eDddca4673E08E59278980Fd7b4530283c8fb (100 ETH)
(9) 0xF5A9FBA5f86eE5dBa94aFD3e1cf2bbBbB0C09f3B (100 ETH)

Private Keys
==================
(0) 0xde695dd96b9dec4c42afc63790f9e200b573856ace6a21434464ac2fbb1fc2b3
(1) 0x00c4b434a7ef564525f698b3d0a249b59516387f8735e0c727b108425dfc038d
(2) 0xce859b38bec4b9d554d20be8f04386531590f73991bbaba5e7e1079a69f064ff
(3) 0xa03cf47483b2ed87b4f17e528c0bf88ec726e7c28389bab15355a09e9e4341e9
(4) 0xd7a6341a17d360d6e320e42c1f58cd265931d54520dede3be89477b69d1ec32d
(5) 0x8b7352f18372f3fd07ce71c9c5347f904ac20bdd61acc5a90d61656ee8554d9e
(6) 0x621df0458aab9ff30684e19c9bf732c3ab706945c1b91a57c239eafd4164d689
(7) 0x11e0cff15324ddedbc1f670254bdab0a0b0aae633847f39239e5237b2ca8b8a3
(8) 0xdac073aee6c24b48fe72826967944fb47ecda6678706241861880ea09230e5d1
(9) 0x99ed824ef83cd0517527763f7f51a225ddc61211827cb94dbb0efd2a0bedb091
```

#### build and deploy contract

```
node publish build

node publish deploy -n local -d publish/deployed/local -g 20
```

#### EVN FILE

```
INFURA_PROJECT_ID=b9b55c7190734c17938d9dd1f301f2d6
DEPLOY_PRIVATE_KEY=0xde695dd96b9dec4c42afc63790f9e200b573856ace6a21434464ac2fbb1fc2b3
LAMBADDRESS=0xf214a4639dd86c98e0420c7c4dbeb324027224de // example address, should modify
TFIADDRESS=0xf214a4639dd86c98e0420c7c4dbeb324027224de // example address, should modify
```

