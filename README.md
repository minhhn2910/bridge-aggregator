### Bridge Aggregator 
Aggregating multiple cross-chain bridges with message passing.

Design: [TODO]

Principle: Moving all complex logic outside of the aggregator and message library => they only see unique payloads. Aggregators are specialied and should be owned by each cross-chain application.

### Run Test

Requirements:
* [Nodejs](https://nodejs.org/en/download) (for npm packages containing smart contract libraries)
    * Install dependencies: `npm install`
* [Foundry](https://book.getfoundry.sh/getting-started/installation)
    * Install dependencies: `forge install`


Test message endpoints:

`FOUNDRY_VIA_IR=true forge test --match-path test/TestMessageEndpoint.sol  -vvv`

Test bridge aggregator:

`FOUNDRY_VIA_IR=true forge test --match-path test/TestAggregator.sol  -vvv`
