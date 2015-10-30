#!/bin/bash

docker run -P -ti --rm --name nginx-rainloop combro2k/nginx-rainloop:latest ${@}
