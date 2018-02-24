#!/usr/bin/env bash
set -e
haxe -cmd 'node build/tests.js' test/travis.hxml
