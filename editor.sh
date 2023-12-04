#!/bin/bash
# https://github.com/microsoft/vscode/issues/68579#issuecomment-463039009
code --wait "$@"
open -a Terminal
