#!/bin/sh

docker run -d --rm -p 5432:5432 -p 1433:1433 --name babelfish babelfish:dev 