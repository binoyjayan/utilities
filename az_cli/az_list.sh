#!/bin/bash

# $USER
q_all="[?tags.createdby == 'bjayan']"

az vm list --resource-group "" \
  --query  "$q_all" \
  --output table
