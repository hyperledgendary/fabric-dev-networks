# small dev network

A basic single organisation network for when you need something small and simple to get started.

_Based on the fabric-samples basic-network_

## Prereqs

Download the Hyperledger Fabric docker images.

```
curl -sSL https://raw.githubusercontent.com/hyperledger/fabric/master/scripts/bootstrap.sh | bash -s -- 2.0.0-beta 1.4.4 0.4.18 -s -b
```

## Usage

Thinking about creating a docker image based on fabric-tools with additional scripts to automate these steps, but for now run the following to set up a small network.

Generate:

```
docker run --rm -v ${PWD}:/local:ro -v small_config:/etc/hyperledger/fabric -w /etc/hyperledger/fabric --entrypoint=/bin/bash hyperledger/fabric-tools -c "rm -Rf /etc/hyperledger/fabric/configtx.yaml /etc/hyperledger/fabric/msp && cp /local/crypto-config.yaml /local/configtx.yaml /etc/hyperledger/fabric"
```

```
docker run --rm -v small_config:/etc/hyperledger/fabric -w /etc/hyperledger/fabric --entrypoint=/bin/bash hyperledger/fabric-tools -c "cryptogen generate --config=./crypto-config.yaml"
```

```
docker run --rm -v small_config:/etc/hyperledger/fabric -w /etc/hyperledger/fabric --entrypoint=/bin/bash hyperledger/fabric-tools -c "configtxgen -profile OneOrgOrdererGenesis -channelID system-channel -outputBlock ./configtx/genesis.block"
```

```
docker run --rm -v small_config:/etc/hyperledger/fabric -w /etc/hyperledger/fabric --entrypoint=/bin/bash hyperledger/fabric-tools -c "configtxgen -profile OneOrgChannel -outputCreateChannelTx ./configtx/channel.tx -channelID smallchannel"
```

```
docker run --rm -v small_config:/etc/hyperledger/fabric -w /etc/hyperledger/fabric --entrypoint=/bin/bash hyperledger/fabric-tools -c "configtxgen -profile OneOrgChannel -outputAnchorPeersUpdate ./configtx/HumboldtOrgMSPanchors.tx -channelID smallchannel -asOrg HumboldtOrg"
```

Check what ended up in _/etc/hyperledger/fabric_! 

```
docker run --rm -it -v small_config:/etc/hyperledger/fabric --entrypoint=/bin/bash hyperledger/fabric-tools
```

Start the fans!

```
docker-compose -f docker-compose.yml up -d ca.humboldt.example.com orderer.example.com peer0.humboldt.example.com couchdb cli
```

Check everything looks ok (see logging below)

```
docker ps
```

Create the channel

```
docker exec humboldt.cli peer channel create -o orderer.example.com:7050 -c smallchannel -f /etc/hyperledger/fabric/configtx/channel.tx --outputBlock /etc/hyperledger/fabric/configtx/channel.block
```

Join peer to the channel

```
docker exec humboldt.cli peer channel join -b /etc/hyperledger/fabric/configtx/channel.block
```

```
docker exec humboldt.cli peer channel update -o orderer.example.com:7050 --ordererTLSHostnameOverride orderer.example.com -c smallchannel -f /etc/hyperledger/fabric/configtx/HumboldtOrgMSPanchors.tx
```

```
docker exec humboldt.cli peer channel list
```

```
docker exec humboldt.cli peer channel getinfo -c smallchannel
```

## Chaincode lifecycle

_Is /etc/hyperledger/fabric/chaincode a reasonable place to dump packaged chaincode?_

```
cd <CHAINCODE_DIR>
docker run --rm -e CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/fabric/crypto-config/peerOrganizations/humboldt.example.com/users/Admin@humboldt.example.com/msp -v ${PWD}:/local:ro -v small_config:/etc/hyperledger/fabric -w /etc/hyperledger/fabric/chaincode --entrypoint=/bin/bash hyperledger/fabric-tools -c "peer lifecycle chaincode package /etc/hyperledger/fabric/chaincode/fabcar.tar.gz --path /local --lang <golang/java/node> --label fabcar_v1"
```

**Note:** currently fails for java implementation of fabcar

```
docker exec humboldt.cli peer lifecycle chaincode install /etc/hyperledger/fabric/chaincode/fabcar.tar.gz
```

```
docker exec humboldt.cli peer lifecycle chaincode queryinstalled
```

```
docker exec humboldt.cli peer lifecycle chaincode approveformyorg -o orderer.example.com:7050 --channelID smallchannel --name fabcar --version 1 --init-required --package-id <PACKAGE_ID> --sequence 1 --waitForEvent
```    

TODO: fails with _Error: timed out waiting for txid on all peers_

```
docker exec humboldt.cli peer lifecycle chaincode checkcommitreadiness -o orderer.example.com:7050 --channelID smallchannel --name fabcar --version 1 --sequence 1 --output json --init-required
```

```
docker exec humboldt.cli peer lifecycle chaincode commit -o orderer.example.com:7050 --channelID smallchannel --name fabcar --version 1 --sequence 1 --init-required
```

```
docker exec humboldt.cli peer lifecycle chaincode querycommitted --channelID smallchannel --name fabcar
```

```
docker exec humboldt.cli peer chaincode invoke -o orderer.example.com:7050 -C smallchannel -n fabcar --isInit -c '{"function":"initLedger","Args":[]}'
```

```
docker exec humboldt.cli peer chaincode query -C smallchannel -n fabcar -c '{"Args":["queryAllCars"]}'
```

## Logging

```
docker-compose -f docker-compose.yml up -d logspout && curl http://127.0.0.1:8000/logs
```

## Cleaning up

```
docker-compose -f docker-compose.yml down --volumes --remove-orphans
```

```
docker rm -f $(docker ps -aq)
docker container prune
docker volume prune
docker network prune
```

```
docker rmi $(docker images -a -q)
```

```
docker system prune -a
```
