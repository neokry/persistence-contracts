# Math Blocks token contracts

### What are these contracts?
1. `FixedPriceToken`
   Each generative artwork is a unique contract.
   This allows for clear ownership of the collection, opt in upgradability and your own contract 
2. `TokenFactory`
   Factory contract allowing you to easily + for a low gas transaction create your own generative art contract.
3. `HTMLRenderer`
   A flexible html renderer that allows for generative scripts with external dependencies like p5.js and three.js to be rendered fully on chain.
4. `Observability`
   A single contract for all events to make data processing easier.
5. 'ETHFSAdapter'
    A file system adapter that allows reading of ETH FS data 
6. 'MathCastlesAdapter'
    A file system adapter that allows reading of the math castles library storage data
   
### Flexibility and safety

All drops contracts are wholly owned by their creator and allow for extensibility with rendering and minting.
The root token contract can be upgraded to allow for product upgrades and the factory gates allowed upgrade paths
so users of the contract can opt into new features.

The html renderer allows these generative art contracts to import from a variaty of onchain libraries.
   
### Local development

1. Install [Foundry](https://github.com/foundry-rs/foundry)
1. `yarn install`
1. `git submodule init && git submodule update`
1. `yarn build`
