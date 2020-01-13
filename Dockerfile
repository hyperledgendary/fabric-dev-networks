ARG ALPINE_VERSION=3.10
ARG HLF_VERSION=2.0.0-beta

FROM hyperledger/fabric-tools:${HLF_VERSION} as tools

FROM alpine:${ALPINE_VERSION}

RUN apk add --no-cache \
	bash \
	jq \
	tzdata;
ENV FABRIC_CFG_PATH /etc/hyperledger/fabric
VOLUME /etc/hyperledger/fabric
COPY --from=tools /usr/local/bin /usr/local/bin
COPY --from=tools ${FABRIC_CFG_PATH}/core.yaml ${FABRIC_CFG_PATH}/orderer.yaml ${FABRIC_CFG_PATH}/
