#! /usr/bin/env bash

pkill swift
cd .build/release
./testJWT
cd -
