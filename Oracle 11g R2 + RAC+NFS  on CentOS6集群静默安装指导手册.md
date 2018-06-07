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

![image](https://github.com/zouzouPi/oracle-/blob/master/oracle_picture/网络配置/修改主机名1.png)

- 更改主机名

```
# vi /etc/sysconfig/network

```
- 更改/etc下的hosts文件

```
# vi /etc/hosts
```
-重启reboot,并查看hostname是否修改


## 4.oracle_rac网络环境
> 本文以如下节点分配为例

节点|public_ip|virtual_ip|private_ip|scan_ip
---|---|---|---|---
cetiti111|192.168.138.131|192.168.138.111|	192.168.128.1|192.168.138.115
cetiti113|192.168.138.132|192.168.138.112|	192.168.128.2|192.168.138.115

## 5.安装包目录

安装包| FTP地址：ftp://192.168.10.21/software/DB/Oracle_rac/
---|---
oracle | 提供oracle企业版版本
oracle_rac |提供rac安装包及依赖包
dns_rpm |提供SCAN配置依赖包
nfs_rpm |提供NFS配置依赖包
response |提供rac与oracle相关配置文件

# 三、网络配置

> 需要两块网卡，一块用于公共通信、一块用于rac内部通信。其中，如需添加网卡需联系服务器管理人员进行分配

- 查看网卡mac信息

```
# cat /etc/udev/rules.d/70-persistent-net.rules
```
![image](网卡信息.png)
- public_ip配置
