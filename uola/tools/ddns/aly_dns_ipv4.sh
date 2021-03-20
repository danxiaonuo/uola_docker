#!/bin/bash

ApiId=""
ApiKey=""
# 子域名
SubDomain=''
# 域名
Domain=''
# 子域
Domain_Name=$SubDomain.$Domain
# 记录类型
Type="A"
# 解析记录的线路
Line="default"
# 记录的 TTL 值
TTL="600"

# 获取公网地址
ipv4=$(curl -s -m 3 --retry-delay 3 --retry 3 -k -4 --header 'cache-control: no-cache' --url https://api-ipv4.ip.sb/ip)
ipv6=$(curl -s -m 3 --retry-delay 3 --retry 3 -k -6 --header 'cache-control: no-cache' --url https://api-ipv6.ip.sb/ip)
# 获取DNS 解析记录
ipv4_dns=$(dig $Domain_Name A +short 2>&1)
ipv6_dns=$(dig $Domain_Name AAAA +short 2>&1)

# 生成时间戳
timestamp=$(date -u "+%Y-%m-%dT%H%%3A%M%%3A%SZ")

# 前置函数
urlencode() {
	# urlencode <string>
	out=""
	while read -n1 c; do
		case $c in
		[a-zA-Z0-9._-]) out="$out$c" ;;
		*) out="$out$(printf '%%%02X' "'$c")" ;;
		esac
	done
	echo -n $out
}

# URL加密命令
enc() {
	echo -n "$1" | urlencode
}

# 发送请求函数
send_request() {
	local args="AccessKeyId=$ApiId&Action=$1&Format=json&$2&Version=2015-01-09"
	local hash=$(echo -n "GET&%2F&$(enc "$args")" | openssl dgst -sha1 -hmac "$ApiKey&" -binary | openssl base64)
	local result=$(curl -s -m 3 --retry-delay 3 --retry 3 -k --request GET --url "http://alidns.aliyuncs.com/?$args&Signature=$(enc "$hash")" --header 'cache-control: no-cache')
	echo $result
}

# 获取记录值 (RecordID)
get_recordid() {
	echo "获取 $Domain_Name 的 IP..." >&2
	local queryString="SignatureMethod=HMAC-SHA1&SignatureNonce=$timestamp&SignatureVersion=1.0&SubDomain=$Domain_Name&Timestamp=$timestamp&Type=$Type"
	local result=$(send_request "DescribeSubDomainRecords" "$queryString")
	local code=$(echo $result | sed 's/{"TotalCount":\([0-9]+*\).*/\1/')

	if [ "$code" = "1" ]; then
		ip=$(echo $result | sed 's/.*,"Value":"\([0-9a-z\.:]*\)".*/\1/')

		if [ "$ip" = "$ipv4" ]; then
			echo "$ip 无变化, 退出脚本..." >&2
			echo "quit"
		else
			local recordId=$(echo $result | sed 's/.*\"RecordId":"\([0-9]*\)".*/\1/')
			echo $recordId
		fi
	else
		echo "null"
	fi
}

# 更新记录值 (RecordID)
update_record() {
	local queryString="RR=$SubDomain&RecordId=$1&SignatureMethod=HMAC-SHA1&SignatureNonce=$timestamp&SignatureVersion=1.0&TTL=$TTL&Timestamp=$timestamp&Type=$Type&Value=$(enc $ipv4)"
	local result=$(send_request "UpdateDomainRecord" $queryString)
}

# 添加记录值 (RecordID)
add_record() {
	local queryString="RR=$SubDomain&SignatureMethod=HMAC-SHA1&SignatureNonce=$timestamp&SignatureVersion=1.0&TTL=$TTL&Timestamp=$timestamp&Type=$Type&Value=$(enc $ipv4)"
	local result=$(send_request "AddDomainRecord&DomainName=$Domain" $queryString)
}

# 获取子域的记录ID
recordId=$(get_recordid)

if [ ! "$recordId" = "quit" ]; then
	if [ "$recordId" = "null" ]; then
		echo "域名记录不存在, 添加 $Domain_Name 至 $ipv4..."
		add_record
	elif [ "$ip" != "$ipv4" ]; then
		echo "域名记录已存在, 更新 $Domain_Name 至 $ipv4..."
		update_record $recordId
	elif [ "$ip" = "$ipv4" ]; then
		echo "记录值未发生任何变动，无需进行改动，正在退出……"
		exit 0
	fi
fi
