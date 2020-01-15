#!/bin/bash

# SPDX-License-Identifier: Apache-2.0

set -o errexit
[ -n "$DEBUG" ] && set -x

function error_exit()
{
	echo "$1" 1>&2
	exit 1
}

if [ $# -lt 1 ]; then
  NETWORK_DIR=/etc/hyperledgendary/fabric-dev-networks/small
else
  NETWORK_DIR=$1
  shift
fi

if [ -d "${NETWORK_DIR}" ] && [ -f "${NETWORK_DIR}/.fdnrc" ] && [ -f "${NETWORK_DIR}/configtx.yaml" ] && [ -f "${NETWORK_DIR}/crypto-config.yaml" ]; then
  echo "Network config found: ${NETWORK_DIR}"
  source "${NETWORK_DIR}/.fdnrc"
  cp /etc/hyperledgendary/fabric-dev-networks/small/{crypto-config.yaml,configtx.yaml} /etc/hyperledger/fabric
else
  echo "Network config not found: ${NETWORK_DIR}" 1>&2 && exit 1
fi

pushd /etc/hyperledger/fabric

# generate crypto material
cryptogen generate --config=./crypto-config.yaml || error_exit "Failed to generate crypto material"

# generate genesis block for orderer
configtxgen -profile ${GENESIS_PROFILE} -channelID system-channel -outputBlock ./configtx/genesis.block || error_exit "Failed to generate orderer genesis block"

# generate channel configuration transaction
configtxgen -profile ${CHANNEL_PROFILE} -outputCreateChannelTx ./configtx/channel.tx -channelID ${CHANNEL_NAME} || error_exit "Failed to generate channel configuration transaction"

# generate anchor peer transaction
configtxgen -profile ${CHANNEL_PROFILE} -outputAnchorPeersUpdate ./configtx/${ORG_NAME}MSPanchors.tx -channelID ${CHANNEL_NAME} -asOrg ${ORG_NAME} || error_exit "Failed to generate anchor peer update for ${ORG_NAME}"

popd
