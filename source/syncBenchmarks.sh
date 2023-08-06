#!/bin/bash

rsync -am --progress \
  --include='*.txt' \
  --include='*/' \
  --exclude='*' \
  embl:/g/kosinski/vmaurer/templateMatchingLibrary/benchmarks ../
