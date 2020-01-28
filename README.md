# fabric-dev-networks

Collection of sample Fabric networks for developing and testing smart contracts

Just experimenting with an alternative approach to sharing sample networks, starting with a [small](./networks/small/README.md) network which should mostly work but is likely to keep changing

## Prereqs

Download the Hyperledger Fabric docker images

```
curl -sSL https://raw.githubusercontent.com/hyperledger/fabric/master/scripts/bootstrap.sh | bash -s -- 2.0.0-beta 1.4.4 0.4.18 -s -b
```

Build the custom tools image

```
docker build -t hyperledgendary/fabric-tools .
```
