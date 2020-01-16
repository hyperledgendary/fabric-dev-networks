#!/bin/bash

# SPDX-License-Identifier: Apache-2.0

set -o errexit
[ -n "$DEBUG" ] && set -x

function error_exit()
{
	echo "$1" 1>&2
	exit 1
}

: "${CORE_PEER_LOCALMSPID:?Org MSPID must be specified using the CORE_PEER_LOCALMSPID environment variable}"

source /etc/hyperledger/fabric/.fdnrc

# Create channel
peer channel create -o orderer.example.com:7050 -c ${CHANNEL_NAME} -f /etc/hyperledger/fabric/configtx/channel.tx --outputBlock /etc/hyperledger/fabric/configtx/channel.block

# Join peer to channel
peer channel join -b /etc/hyperledger/fabric/configtx/channel.block

# Update channel
peer channel update -o orderer.example.com:7050 --ordererTLSHostnameOverride orderer.example.com -c ${CHANNEL_NAME} -f /etc/hyperledger/fabric/configtx/${CORE_PEER_LOCALMSPID}anchors.tx
