#!/usr/bin/env bash

export AZ_CLIENT_KEY="azkey"
export AZ_CLIENT_ID="azid"
export AZ_TEN_ID="aztenid"
export AZ_SUB_ID="azsubid"
export SSH_PRIV="$(cat id_ed25519)"
export SSH_PUB="$(cat id_ed25519.pub)"
export PULL_SECRET=$(cat pullsecret)
export CLUSTER_NAME="azure1"

./make_secret-azure.sh
