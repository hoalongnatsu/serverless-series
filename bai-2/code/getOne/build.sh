#!/bin/bash

GOOS=linux go build -o main main.go
zip getOne.zip main
rm -rf main
