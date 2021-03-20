#!/bin/bash

ApiId=""
ApiKey=""
LoginToken="$ApiId,$ApiKey"
# 子域名
SubDomain=''
# 域名
Domain=''
# 子域
Domain_Name=$SubDomain.$Domain
# 记录类型
Type="AAAA"
# 解析记录的线路ID
#"默认": 0,
#"国内": "7=0",
#"国外": "3=0",
#"电信": "10=0",
#"联通": "10=1",
#"教育网": "10=2",
#"移动": "10=3",
#"百度": "90=0",
#"谷歌": "90=1",
#"搜搜": "90=4",
#"有道": "90=2",
#"必应": "90=3",
#"搜狗": "90=5",
#"奇虎": "90=6",
#"搜索引擎": "80=0"
Line='0'
# 记录的 TTL 值
TTL="600"

# 获取公网地址
ipv4=$(curl -s -m 3 --retry-delay 3 --retry 3 -k -4 --header 'cache-control: no-cache' --url https://api-ipv4.ip.sb/ip)
ipv6=$(curl -s -m 3 --retry-delay 3 --retry 3 -k -6 --header 'cache-control: no-cache' --url https://api-ipv6.ip.sb/ip)
# 获取DNS 解析记录
ipv4_dns=$(dig $Domain_Name A +short 2>&1)
ipv6_dns=$(dig $Domain_Name AAAA +short 2>&1)

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
	local result=$(curl -s -m 3 --retry-delay 3 --retry 3 -k --request POST --url https://dnsapi.cn/$1 --header 'cache-control: no-cache' --header 'content-type: application/x-www-form-urlencoded' --data "$2")
	echo $result
}

# 获取记录值 (RecordID)
get_recordid() {
	echo "获取 $Domain_Name 的 IP..." >&2
	local queryString="login_token=$(enc $LoginToken)&format=json&domain=$Domain&sub_domain=$SubDomain&record_type=$Type&record_line_id=$Line&ttl=$TTL"
	local result=$(send_request "Record.List" "$queryString")
	local code=$(echo $result | sed 's/.*:{"code":"\([0-9]*\)".*/\1/')

	if [ "$code" = "1" ]; then
		ip=$(echo $result | sed 's/.*,"value":"\([0-9a-z\.:]*\)".*/\1/')

		if [ "$ip" = "$ipv6" ]; then
			echo "$ip 无变化, 退出脚本..." >&2
			echo "quit"
		else
			local recordId=$(echo $result | sed 's/.*\[{"id":"\([0-9]*\)".*/\1/')
			echo $recordId
		fi
	else
		echo "null"
	fi
}

# 更新记录值 (RecordID)
update_record() {
	local queryString="login_token=$(enc $LoginToken)&format=json&record_id=$1&sub_domain=$SubDomain&domain=$Domain&value=$(enc $2)&record_type=$Type&record_line_id=$Line&ttl=$TTL"
	local result=$(send_request "Record.Modify" $queryString)
	local code=$(echo $result | sed 's/.*:{"code":"\([0-9]*\)".*/\1/')

	if [ "$code" = "1" ]; then
		echo "$Domain_Name 已指向 $2." >&2
	else
		echo "更新失败." >&2
		echo $result >&2
	fi
}

# 添加记录值 (RecordID)
add_record() {
	local queryString="login_token=$(enc $LoginToken)&format=json&sub_domain=$SubDomain&domain=$Domain&value=$(enc $1)&record_type=$Type&record_line_id=$Line&ttl=$TTL"
	local result=$(send_request "Record.Create" $queryString)
	local code=$(echo $result | sed 's/.*:{"code":"\([0-9]*\)".*/\1/')

	if [ "$code" = "1" ]; then
		echo "$Domain_Name 已指向 $1." >&2
	else
		echo "添加失败." >&2
		echo $result >&2
	fi
}
# 获取子域的记录ID
recordId=$(get_recordid)

if [ ! "$recordId" = "quit" ]; then
	if [ "$recordId" = "null" ]; then
		echo "域名记录不存在, 添加 $Domain_Name 至 $ipv6..."
		add_record $ipv6
	elif [ "$ip" != "$ipv6" ]; then
		echo "域名记录已存在, 更新 $Domain_Name 至 $ipv6..."
		update_record $recordId $ipv6
	elif [ "$ip" = "$ipv6" ]; then
		echo "记录值未发生任何变动，无需进行改动，正在退出……"
		exit 0
	fi
fi
