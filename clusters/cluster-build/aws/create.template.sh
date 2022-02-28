#!/usr/bin/env bash

export AWS_KEY="awskey"
export AWS_ID="awsid"
export SSH_PRIV="$(cat id_ed25519)"
export SSH_PUB="$(cat id_ed25519.pub)"
export PULL_SECRET=$(cat pullsecret)
export CLUSTER_NAME="aws1"

./make_secret-aws.sh
