#!/bin/bash
#==================================================
# OS Required:  CentOS6
# Description:  呉真的服务器一键配置脚本
# Author:       kuretru < kuretru@gmail.com >
# Version:      1.0.161225
#==================================================

#是否更新内核，不更新改0
UpdateKernel=1			

#修改主机名
HostName='storage.i5zhen.com'

#修改密码
PassWord='123456'

#是否安装ShadowSocks
InstallSS=0							

#更新软件包
function SystemUpdate()
{
	if [ $UpdateKernel -eq 1 ]; then
		yum -y update
	else
		yum -y --skip-broken --exclude kernel* update
	fi
	yum clean all
}

#安装基本软件包
function InstallPackages()
{
	yum -y install vim wget curl tree lsof ntpdate epel-release net-snmp bind-utils mtr unzip crontabs git make gcc gcc-c++
}

#修改系统基本设置
function SystemConfig()
{
	#修改主机名
	sed -i "s/^HOSTNAME=.*$/HOSTNAME=${HostName}/g" /etc/sysconfig/network
	#修改密码
	echo $PassWord | passwd --stdin root
	#关闭SELinux
	sed -i "s/^SELINUX=.*$/SELINUX=disabled/g" /etc/selinux/config
	#配置i18n
	sed -i "s/^LANG=.*$/LANG=\"en_US.UTF-8\"/g" /etc/sysconfig/i18n
	sed -i "s/^SYSFONT=.*$/SYSFONT=\"latarcyrheb-sun16\"/g" /etc/sysconfig/i18n
	#时间相关设置
	/bin/cp -p /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
	ntpdate time.windows.com
	#登录文本
	cat <<EOF > /etc/motd
警告：你的IP已被记录，所有操作将会通告管理员！
Warning: Your IP address has been recorded, all operations will notify the administrator!
EOF
}

#配置SSH
function SSHConfig()
{
	sed -i "s/^Port.*$/Port 8022/g" /etc/ssh/sshd_config
	sed -i "s/^#LoginGraceTime/LoginGraceTime/g" /etc/ssh/sshd_config
	sed -i "s/^#MaxAuthTries 6/MaxAuthTries 2/g" /etc/ssh/sshd_config
	sed -i "s/^#PubkeyAuthentication/PubkeyAuthentication/g" /etc/ssh/sshd_config
	sed -i "s/^#AuthorizedKeysFile/AuthorizedKeysFile/g" /etc/ssh/sshd_config
	sed -i "s/^PasswordAuthentication yes/PasswordAuthentication no/g" /etc/ssh/sshd_config
	mkdir /root/.ssh
	touch /root/.ssh/authorized_keys
	cat <<EOF > /root/.ssh/authorized_keys
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAAAgQDUnJJ+Yn4dgqtnFKWWvrs1ykceXt3nn9pmi6zFc29QkYjEa99dAeFX3ts2E+e9gswyJIwvh7xqRyfKvii9cAaUpsgX7RkH/qe/fWmSfR3f33CRvdnmwsPI600EBxKKuEzZR3C6EQVtj6Nw7s7DCc46e058nPt/A1fFIavc6EGPGQ==
EOF
	chmod 600 /root/.ssh/authorized_keys
	chmod 700 /root/.ssh
	service sshd restart
}

#配置iptables
function iptablesConfig()
{
	iptables -P INPUT ACCEPT
	iptables -F
	iptables -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
	iptables -A INPUT -p icmp -j ACCEPT
	iptables -A INPUT -d 127.0.0.1/32 -j ACCEPT
	iptables -A INPUT -p tcp -m tcp --dport 8022 -j ACCEPT
	if [ $InstallSS -eq 1 ]; then
		iptables -A INPUT -p tcp -m tcp --dport 8023 -j ACCEPT
		iptables -A INPUT -p udp -m udp --dport 8023 -j ACCEPT
	fi
	iptables -A INPUT -p tcp -m tcp --dport 80 -j ACCEPT
	iptables -A INPUT -p tcp -m tcp --dport 443 -j ACCEPT
	iptables -A INPUT -p tcp -m tcp --dport 8099 -j ACCEPT
	iptables -P INPUT DROP
	service iptables save
}

#安装python2.7
function InstallPython27()
{
	yum -y install https://rhel6.iuscommunity.org/ius-release.rpm
	rpm --import /etc/pki/rpm-gpg/IUS-COMMUNITY-GPG-KEY
	yum -y install python27 python27-devel python27-pip python27-setuptools python27-virtualenv
	cd /usr/bin
	rm -rf /usr/bin/python
	ln -s python2.7 python
	sed -i "s|#!/usr/bin/python|#!/usr/bin/python2.6|" yum
}

#脚本开始
clear

cat <<EOF
########################################
#
# 呉真的一键服务器配置脚本，目前只适用于
# CentOS6，从一个新的服务器自动初始化配置
# https://www.i5zhen.com
#
########################################
EOF

read -e -p "输入Y开始安装(y/n)" ANSWER
if [[ "$ANSWER" = 'y' ]] || [[ "$ANSWER" = 'yes' ]]; then
	sleep 1
	
cat <<EOF
########################################
# 开始更新软件包   
########################################
EOF
	SystemUpdate
	
cat <<EOF
########################################
# 开始安装基本工具 
########################################
EOF
	InstallPackages
	
cat <<EOF
########################################
# 开始配置主机设置 
########################################
EOF
	SystemConfig
	
cat <<EOF
########################################
# 配置SSH 
########################################
EOF
	SSHConfig
	
cat <<EOF
########################################
# 配置iptables
########################################
EOF
	iptablesConfig
	
cat <<EOF
########################################
# 安装python2.7
########################################
EOF
	InstallPython27
else
	echo '用户退出'
	exit
fi

