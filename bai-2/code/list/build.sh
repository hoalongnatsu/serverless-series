#!/bin/bash

go build -o main main.go
zip list.zip main
rm -rf main
