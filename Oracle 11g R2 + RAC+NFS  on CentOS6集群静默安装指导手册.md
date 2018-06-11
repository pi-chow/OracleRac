# 一、安装前准备

- 本文档需要具备 Linux 操作系统知识的技术人员操作
- 在安装之前，以 root用户登录系统，完成配置工作
- 强调标注的地方请格外注意，否则可能会导致未知错误
- 目标操作系统：Centos 6.x

---

修订记录

日期| 修订版本|描述|作者
---|---|---|---
2018-6-6 | v 1.0 |初次建立|周立宇

# 二、安装准备

## 1.查看Centos版本信息

本手册面向centos 6（X64）系统，本文安装在centos 6.9系统上。首先请检查系统版本，确保符合要求：

```
# uname -r  #查看是否为centos 6.x版本
>2.6.32-696.el6.x86_64

```
## 2.检查服务器各个节点的配置是否符合安装要求

### 2.1.服务器硬盘空间要求

```
/tmp目录大小至少：1GB
安装Grid Infrastracture所需空间：6.6GB
安装Oracle Database所需空间：4GB
此外安装过程中分析、收集、跟踪文件所需空间：10GB
建议总共至少30GB，放心！（此处不包含ASM或NFS的空间需求）

```
### 2.2.服务器内存要求

```
内存大小：至少2.5GB
Swap大小：
当内存为2.5GB-16GB时，Swap需要大于等于系统内存。
当内存大于16GB时，Swap等于16GB即可。

```
### 2.3.检查调试代码

- 查看内存及Swap大小

```
# grep MemTotal /proc/meminfo
# grep SwapTotal /proc/meminfo

```
- 查看磁盘情况

```
# df -h
```
## 3.创建用户和组

> 在**每一个节点**上添加安装Oracle Grid的用户、组和家目录，并设置权限。

- 添加用户和用户组

```
# /usr/sbin/groupadd oinstall
# /usr/sbin/groupadd dba
# /usr/sbin/groupadd oper
# useradd -g oinstall -G oper,dba grid
# useradd -g oinstall -G dba,oper oracle

```

- 设置密码

```
# passwd oracle
# passwd grid

```

- 创建安装目录

```
# mkdir /opt/grid
# mkdir /opt/oracle
# mkdir /opt/gridbase
# mkdir /opt/oraInventory
# mkdir /opt/oracle/oraInventory
```
- 修改归属

```
# chown -R grid:oinstall /opt
# chown -R oracle:oinstall /opt/oracle

```

- 添加读写操作

```
# chmod -R g+w /opt
```

## 4.修改主机名

- 查看主机名


```
# hostname
```

- 更改主机名

```
# vi /etc/sysconfig/network

```


- 更改/etc下的hosts文件

```
# vi /etc/hosts
```
- 重启reboot,并查看hostname是否修改


## 5.安装包目录

安装包| FTP地址：ftp://192.168.10.21/software/DB/Oracle_rac/
---|---
oracle | 提供oracle企业版版本
oracle_rac |提供rac安装包及依赖包
dns_rpm |提供SCAN配置依赖包
nfs_rpm |提供NFS配置依赖包
response |提供rac与oracle相关配置文件

## 6.oracle_rac网络环境

### 6.1新增网卡

- 查看网卡mac地址信息

> 注意：需要两块网卡，一块用于公共通信、一块用于rac内部通信。其中，如需添加网卡需联系服务器管理人员进行分配。

```
# cat /etc/udev/rules.d/70-persistent-net.rules
```

- 编辑ifcfg-eth1  ``cetiti111与cetiti113都要添加``

```
# cd /etc/sysconfig/network-scripts
# cp ifcfg-eth0 ifcfg-eth1
# vi ifcfg-eth1

```
ifcfg-eth1修改内容

```
HWADDR`00:0c:29:85:ca:6b   #eth1网卡mac地址
DEVICE`eth1
ONBOOT`yes
BOOTPROTO`static
IPADDR`192.168.128.1  #IP 配置中的 cetiti111-priv
NETMASK`255.255.255.0

```
- 重启网络

```
#ifup eth1
#service network restart

```

- 检查服务器网络信息

```
# ifconfig
```


### 6.2DNS配置

> Oracle grid是使用Single Client Access Name(SCAN),所以要DNS服务器来对SCANIP进行解析。以上是对DNS服务器的相关配置。这里是把DNS服务器放在节点``cetiti111``中来进行解析。

- DNS服务器依赖包（文件夹：dns_rpm）``cetiti111``

```
bind-9.8.2-0.62.rc1.el6_9.5.x86_64
bind-libs-9.8.2-0.62.rc1.el6_9.5.x86_64
bind-utils-9.8.2-0.62.rc1.el6_9.5.x86_64

```
- DNS配置 ``cetiti111``

> 参照自己规划的IP结合配置文件进行修改。

```
# vi /etc/named.conf
添加内容
options {
        listen-on port 53 { 192.168.138.131; };
        listen-on-v6 port 53 { ::1; };
        directory       "/var/named";
        dump-file       "/var/named/data/cache_dump.db";
        statistics-file "/var/named/data/named_stats.txt";
        memstatistics-file "/var/named/data/named_mem_stats.txt";
        allow-query     { any; };
        recursion yes;

        dnssec-enable yes;
        dnssec-validation yes;

        /* Path to ISC DLV key */
        bindkeys-file "/etc/named.iscdlv.key";

        managed-keys-directory "/var/named/dynamic";
};

logging {
        channel default_debug {
                file "data/named.run";
                severity dynamic;
        };
};

zone "." IN {
        type hint;
        file "named.ca";
};
zone "domain.com" {
      type master;
       file "/etc/named/domain.com.hosts";
};
zone "138.168.192.in-addr.arpa"{
       type master;
       file "/etc/named/192.168.138.rev";
};
zone "128.168.192.in-addr.arpa"{
     type master;
     file "/etc/named/192.168.128.rev";
};
include "/etc/named.rfc1912.zones";
include "/etc/named.root.key";

```
- 编辑正向解析配置文件

```
# vi /etc/named/domain.com.hosts
添加内容：
$TTL 86400
$ORIGIN domain.com.
@ IN SOA  cetiti111.domain.com. root.domain.com.(
        1282236195
        10800
        3600
        604800
        38400 )
@    IN NS cetiti111.domain.com.
cetiti111.domain.com.    IN  A 192.168.138.131
cetiti113.domain.com.    IN  A 192.168.138.132
cetiti111-priv.domain.com. IN  A 192.168.128.1
cetiti113-priv.domain.com. IN  A 192.168.128.2
cetiti111-vip.domain.com.  IN  A 192.168.138.111
cetiti113-vip.domain.com.  IN  A 192.168.138.112
cetiti-scan.domain.com.  IN  A 192.168.138.115

```
- 编辑public，private反向解析配置文件


```
Public反向解析
# vi /etc/named/192.168.138.rev
添加内容：
$TTL 86400
@ IN SOA cetiti111.domain.com. root.domain.com.(
        1282248634
        10800
        3600
        604800
        38400)
                 IN NS   cetiti111.domain.com.
131              IN PTR  cetiti111.domain.com.
132              IN PTR  cetiti113.domain.com.
111              IN PTR  cetiti111-vip.domain.com.
112              IN PTR  cetiti113-vip.domain.com.
115              IN PTR  cetiti-scan.domain.com. Private反向解析
#vi /etc/named/192.168.128.rev
添加内容：
$TTL 86400 
@ IN  SOA cetiti111.domain.com. root.domain.com. (
        1282236195
        10800
        3600
        604800
        38400 )
               IN   NS      cetiti111.domain.com.
1              IN   PTR     cetiti111-priv.domain.com.
2              IN   PTR     cetiti113-priv.domain.com.

```
- 配置检查

```
# named-checkconf  命令检查主配置文件配置是否无误
*运行没有提示（结果）就是最好的结果
# named-checkzone "domain.com" /etc/named/domain.com.hosts
# named-checkzone "138.168.192.in-addr.arpa" /etc/named/192.168.138.rev
# named-checkzone "128.168.192.in-addr.arpa " /etc/named/192.168.128.rev
*没有报错就可以

```

- 添加文件权限

```
# chown :named /etc/named/domain.com.hosts
# chown :named /etc/named/192.168.138.rev
# chown :named /etc/named/192.168.128.rev

```

- 启动DNS服务

```
# service named restart
```
- 添加DNS服务地址 ``cetiti111与cetiti113都要添加``

```
# vi /etc/resolv.conf 
添加DNS ：
search domain.com
nameserver 192.168.138.131

```
- 对DNS正向、反向验证

```
正向验证
# nslookup
> cetiti-scan.domain.com
Server:         192.168.138.131
Address:        192.168.138.131#53

Name:   cetiti-scan.domain.com
Address: 192.168.138.115 
反向验证
# host 192.168.196.115
115.196.168.192.in-addr.arpa domain name pointer cetiti111-scan.domain.com.
```
# 三、环境变量配置
## 1.编辑/etc/hosts 

``cetiti111与cetiti113都要添加``


```
#vi /etc/hosts 
末尾添加：
127.0.0.1    localhost 
#public ip
192.168.138.131 cetiti111
192.168.138.132 cetiti113

#virtual ip
192.168.138.111 cetiti111-vip
192.168.138.112 cetiti113-vip

#private ip
192.168.128.1 cetiti111-priv
192.168.128.2 cetiti113-priv

#scan ip 
192.168.138.115 cetiti-scan

```
## 2.编辑bash_profile

> 注意：cetiti111与cetiti113都需要编辑，注意节点的ORACLE_SID不能相同。本文分别为cetiti1，cetiti2。

- Oracle环境变量

```
# vi /home/oracle/.bash_profile
末尾添加：
ORACLE_BASE`/opt/oracle
ORACLE_HOME`/opt/oracle/product/11.2.0/db_1
ORACLE_SID`cetiti1
PATH`/usr/lib64:$ORACLE_HOME/bin:$PATH
LD_LIBRARY_PATH`$ORACLE_HOME/lib:$LD_LIBRARY_PATH
export ORACLE_BASE ORACLE_HOME ORACLE_SID PATH LD_LIBRARY_PATH

```
加载配置

```
# source /home/oracle/.bash_profile
```
- Grid环境变量

```
# vi /home/grid/.bash_profile
末尾添加：
ORACLE_BASE`/opt/gridbase
ORACLE_HOME`/opt/grid
PATH`$ORACLE_HOME/bin:$PATH
LD_LIBRARY_PATH`$ORACLE_HOME/lib:$LD_LIBRARY_PATH
export ORACLE_BASE ORACLE_HOME PATH LD_LIBRARY_PATH

```
加载配置

```
# source /home/grid/.bash_profile
```
## 3.编辑linux内核

``cetiti111与cetiti113都需要编辑``

- 配置/etc/sysctl.conf

```
# vi /etc/sysctl.conf
```
添加参数：


```
fs.aio-max-nr ` 1048576
fs.file-max ` 6815744
kernel.shmall ` 2097152
kernel.shmmax ` 1073741824
kernel.shmmni ` 4096
kernel.sem ` 250 32000 100 128
net.ipv4.ip_local_port_range ` 9000 65500
net.core.rmem_default ` 262144
net.core.rmem_max ` 4194304
net.core.wmem_default ` 262144
net.core.wmem_max ` 1048576

```
使修改生效

```
#sysctl -p
```
- 配置/etc/security/limits.conf

```
#vi /etc/security/limits.conf
```
添加参数：

```
oracle soft nproc 2047
oracle hard nproc 16384
oracle soft nofile 1024
oracle hard nofile 65536
oracle soft stack 10240
grid soft nproc 2047
grid hard nproc 16384
grid soft nofile 1024
grid hard nofile 65536
grid soft stack 10240

```
## 4.设置节点时间同步

> 一般时间同步有linux的ntpd时间同步，还有就是oracle的时间同步，我们用 oracle的时间同步，需要关闭 ntpd 服务。

```
# /sbin/service ntpd status 
检查ntpd是否开启，如果开启继续执行
# /sbin/service ntpd stop
# chkconfig ntpd off
# mv /etc/ntp.conf /etc/ntp.conf.original
还要删除以下文件（如果有的话）
# rm /var/run/ntpd.pid

```
# 四、oracle_rac依赖包

## 1.需要依赖包

```
gcc-3.4.6
libaio-0.3.105 (i386)
libaio-0.3.105 (x86_64)
glibc-2.3.4-2.41 (i686)
glibc-2.3.4-2.41 (x86_64)
compat-libstdc++-33-3.2.3 (i386)
compat-libstdc++-33-3.2.3 (x86_64)
elfutils-libelf-0.97 (x86_64)
elfutils-libelf-devel-0.97
glibc-common-2.3.4
glibc-devel-2.3.4 (x86_64)
glibc-headers-2.3.4
gcc-c++-3.4.6
libaio-devel-0.3.105 (i386)
libaio-devel-0.3.105 (x86_64)
libgcc-3.4.6 (i386)
libgcc-3.4.6 (x86_64)
libstdc++-3.4.6 (i386)
libstdc++-3.4.6 (x86_64)
libstdc++-devel-3.4.6 (x86_64)
sysstat-5.0.5
unixODBC-2.2.11 (i386)
unixODBC-2.2.11 (x86_64)
unixODBC-devel-2.2.11 (i386)
unixODBC-devel-2.2.11 (x86_64)
pdksh-5.2.14
expat-1.95.7 (x86_64)

```
## 2.依赖包安装检测依赖包安装检测

- 检查依赖包是否已经安装

```
# rpm -qa |grep包名
```

- 常用问题总结

```
搜索 yum 源是否有未安装的包：# yum search 包名
yum 能搜索到的包安装：#yum install -y 包名
如果yum 搜索不到的包只能手动安装了：#rpm -ivh 包名
*对于 i386 或者 i686，因为已经有 x86_64 的包已经安装了需要强制安装 加参数 --force ----nodeps
依赖包查找地址
http://rpm.pbone.net/
https://pkgs.org/

```
## 3.安装依赖

### （1）在线环境安装

- yum可安装包

```
#yum install -y compat-libcap1 glibc glibc-devel glibc-headers glibc-common libaio libaio-devel libgcc libstdc++ libstdc++-devel sysstat unixODBC unixODBC-devel compat-libstdc++ elfutils-libelf elfutils-libelf-devel gcc-c++ gcc
```
- 剩下缺失的安装包通过rpm安装

### （2）离线安装

```
# rpm -ivh 安装包
# rpm -ivh   --force --nodeps(i386)
#rpm -qa | grep 查看安装包
#rpm -e   --nodeps(强制卸载)

```
- 安装包地址

```
ftp://192.168.10.21/software/DB/Oracle_rac/oracle_rac/rac_rpm/
注意：安装顺序可参考：rac_rpm.sh

```
# 五、创建共享磁盘（NFS）

> 本文安装通过NFS建立共享磁盘，以cetiti111作为NFS磁盘服务器。

- 安装依赖（nfs_rpm）``cetiti111``

```
nfs-utils-1.2.3-75.el6_9.x86_64
nfs-utils-lib-1.1.5-13.el6.x86_64
rpcbind-0.2.0-13.el6_9.1.x86_64

```

- 关闭防火墙 ``cetiti111``、``cetiti113``

```
# service iptables stop  关闭防火墙(开机重启)
# chkconfig iptables off（永远关闭防火墙）

```

- 启动NFS并设置开机自启动 ``cetiti111``

```
# service rpcbind start
# service nfs start
# chkconfig nfs on  

```
- linux 服务器模拟nas 存储提供nfs 挂在逻辑卷 ``cetiti111``

```
# mkdir /datahouse
# vi /etc/exports
末尾添加：
/datahouse *(rw,sync,no_wdelay,insecure_locks,no_root_squash)

```
- 检查是否有挂载地

```
# showmount -e cetiti111查看是否设置成功
```
- 创建本地挂载目录 ``cetiti111``，``cetiti113``

```
# mkdir /griddata
# chown -R grid:oinstall /griddata

```
- 编辑/etc/fstab ``cetiti111，cetiti113``

```
#vi /etc/fstab
末尾添加：
192.168.138.131:/datahouse /griddata	nfs	rw,nolock,bg,hard,nointr,tcp,vers`3,timeo`600,rsize`32768,wsize`32768,actimeo`0  0 0

```
- 重启服务 ``cetiti111，cetiti113``

```
# reboot
```
- 查看是否挂载成功

```
# df -h
```
# 六、配置节点信任

> grid,oracle用户都需要添加相互信任信息。两台服务器，分别以grid与oracle用户执行，下面以 grid 为例。

- 建立通信秘钥

```
# su – grid
在节点cetiti111和cetiti113分别执行
#ssh-keygen -t rsa
然后一路回车
#cat ~/.ssh/id_rsa.pub >> ~/.ssh/ authorized_keys
在节点 cetiti111上执行
# ssh cetiti113 cat ~/.ssh/id_rsa.pub >> ~/.ssh/ authorized_keys
在节点 cetiti113上执行
# ssh cetiti111 cat ~/.ssh/id_rsa.pub >> ~/.ssh/ authorized_keys

```
- 添加秘钥

> 如果秘钥的生成路径是按照上面一路默认的话，可以执行命令

```
在节点cetiti111和cetiti113均执行
# ssh-copy-id grid@cetiti111 #oracle用户：grid替换成oracle
# ssh-copy-id grid@cetiti113

```
- 验证是否通过

```
在 cetiti111, cetiti113均执行
#ssh cetiti111 date
#ssh cetiti113 date
只要不再提示输入密码就成功了

```
# 七、oracle rac安装

## 1.环境检测

- 解压安装包

```
# mkdir /opt/app/grid
# unzip linux.x64_11gR2_grid.zip -d /opt/app/grid

```
- 编辑response文件

> 编辑ftp://192.168.10.21/software/DB/Oracle_rac/response/
中的grid_install.rsp文件替换自己的节点信息。然后替换
解压目录中/opt/app/grid/response中的安装文件

```
ORACLE_HOSTNAME`cetiti111
oracle.install.crs.config.clusterNodes`cetiti111:cetiti111-vip,cetiti113:cetiti113-vip
oracle.install.crs.config.privateInterconnects`eth0:192.168.138.0:1,eth1:192.168.128.0:2

```
- 添加权限

```
# chown -R grid:oinstall  /opt/app/grid
```
- oracle_rac环境检测

```
# su - grid
# cd /opt/app/grid/grid
# ./runcluvfy.sh stage -pre crsinst -n cetiti111,cetiti113 -fixup -verbose

```
> 执行安装前检查，通过报告查看环境是否通过。

## 2.静默安装

> 安静等待，如果有报错，通过返回日志信息进行查看。以上脚本运行完之后，根据提示以root用户运行相应脚本

```
# su - grid
# cd /opt/app/grid/grid
#./runInstaller -silent -force -responseFile /opt/app/grid/grid/response/grid_install.rsp

```
## 3.执行脚本

> 根据提示内容，新建立连接，roo用户执行命令

```
# /opt/oraInventory/orainstRoot.sh  #cetiti111，cetiti113
# /opt/grid/root.sh   #cetiti111，cetiti113
注意：在执行root.sh的同时，打开新的连接并执行
# dd if`/var/tmp/.oracle/npohasd of`/dev/null bs`1024 count`1
直到可以执行为止

```
## 4.集群验证

```
# su – grid
# crsctl query crs activeversion

```
> 返回内容Oracle Clusterware active version on the cluster is [11.2.0.1.0]表示安装成功。

## 5.补充内容

关机重启服务器后集群打开流程

> 通过ps -ef|grep has查看是否有未关闭进程，如果没有按下面步骤执行。

- 11.2.0.1的一个bug:高可用执行之前在每个节点执行

```
# dd if`/var/tmp/.oracle/npohasd of`/dev/null bs`1024 count`1
```
- 再在两个节点打开高可用

```
# ./crsctl start crs
```
- 启动命令

```
# cd /opt/grid/bin
# ./crsctl check cluster
# ./crsctl start cluster -all

```
- 状态检查命令

```
# ./crsctl query crs activeversion
# ./crsctl stat res -t
# ./crsctl stat res -t -init
# ./crs_stat -t -v
# ./olsnodes -n

```
- 关闭命令

```
./crsctl stop cluster -all
```
# 八、Oracle 安装

## 1.oracle集群方式安装

- 解压安装包 ``cetiti111``

```
# mkdir /opt/app/oracle
# tar -xzvf  oracle_enterprice_database.tar.gz -C /opt/app/oracle

```
- 编辑response文件

> 编辑ftp://192.168.10.21/software/DB/Oracle_rac/response/
中的grid_db_install.rsp与dbc.rsp替换自己的节点信息。然后替换
解压目录中/opt/app/oracle/database/response中的安装文件


grid_db_install.rsp更改内容:

```
ORACLE_HOSTNAME`cetiti111
oracle.install.db.CLUSTER_NODES`cetiti111,cetiti113

```
dbc.rsp更改内容:

```
NODELIST`cetiti111,cetiti113
```
- 执行脚本

```
# su - oracle
# cd /opt/app/oracle/database
# ./runInstaller -ignoreInternalDriverError -ignorePrereq -silent -force -responseFile /opt/app/oracle/database/response/grid_db_install.rsp

```
> 以上脚本运行完之后，根据提示以root用户运行相应脚本

## 2.配置集群监听

> listener(开启条件：cetiti111-vip与cetiti113-vip均打开，如果有节点vip未显示，可参考相关问题总结)


```
# su – grid
# srvctl status listener #查看cetiti111,cetiti113监听是否都打开没有打开添加监听
# srvctl add listener
# srvctl start listener
# srvctl status listener

```
## 3.配置数据库实例共享

- 创建文件夹 ``cetiti111、cetiti113``

```
# su – root
# mkdir /opt/oracle/oradata
# mkdir /opt/oracle/flash_recovery_area
# mkdir /opt/oracle/product/11.2.0/db_1/dbs
# chown -R oracle:oinstall /opt/oracle
# chmod -R g+w /opt/oracle/  #添加读写权限

```
- 将cetiti113的实例挂载到cetiti111中

> 具体方法参考NFS配置

```
需要挂载的磁盘
/opt/oracle/oradata
/opt/oracle/flash_recovery_area
/opt/oracle/product/11.2.0/db_1/dbs

```
## 4.安装数据库实例

```
# su - oracle
# /opt/oracle/product/11.2.0/db_1/bin/dbca -silent -responseFile /opt/app/oracle/database/response/dbca.rsp

```
- 检查集群数据库

```
# su - grid
# srvctl config database -d cetiti

```
- 检查数据库实例状态

```
# srvctl status database -d cetiti
```
- navicat连接数据库

```
主机或IP地址：192.168.138.115 #scan_ip地址
端口：1521
选择服务名
用户名：sys
密码：123456
高级：sysdba
```
