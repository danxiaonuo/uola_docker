#!/bin/bash

config_name=$(uci get clash.config.config_name 2>&1)
clash_url=$(uci get clash.config.clash_url 2>&1)
use_config=$(uci get clash.config.use_config 2>&1 | sed -n 's:/[^/]*$::p')
use_config_url=$(uci get clash.config.use_config 2>&1)

rm -rf $use_config/* > /dev/null 2>&1
mkdir -p $use_config
wget --no-check-certificate $clash_url -O $use_config_url > /dev/null 2>&1
/etc/init.d/clash restart
