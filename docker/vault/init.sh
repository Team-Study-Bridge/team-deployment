#!/bin/sh

# Vault 주소와 토큰 설정
export VAULT_ADDR='http://127.0.0.1:8200'
VAULT_TOKEN='myroot'

# 로그인 (토큰은 바로 사용 가능하므로 생략 가능)
vault login $VAULT_TOKEN

# AWS S3 키 등록
vault kv put secret/lecture-service \
  aws.access-key=AKIA4ZPZVM5RZEZJRN5J \
  aws.secret-key=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

# 확인 출력
vault kv get secret/lecture-service
