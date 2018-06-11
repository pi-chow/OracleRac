#!/bin/bash
path=$1
rpm -ivh ${path}/compat-libcap1-1.10-1.x86_64.rpm
rpm -ivh ${path}/sysstat-9.0.4-33el6_9.1.x86_64.rpm
rpm -ivh ${path}/compat-libstdc++/compat-libstdc++-33-3.2.3-69.el6.x86_64.rpm
rpm -ivh ${path}/compat-libstdc++/compat-libstdc++-33-3.2.3-47.3.i386.rpm --force --nodeps
rpm -ivh ${path}/elfutils-libelf/elfutils-libelf-devel-0.164-2.el6.x86_64.rpm
rpm -ivh ${path}/gcc-c++/ppl-0.10.2-11.el6.x86_64.rpm
rpm -ivh ${path}/gcc-c++/mpfr-2.4.1-6.el6.x86_64.rpm
rpm -ivh ${path}/gcc-c++/cloog-ppl-0.15.7-1.2.el6.x86_64.rpm 
rpm -ivh ${path}/gcc-c++/cpp-4.4.7-4.el6.x86_64.rpm
rpm -ivh ${path}/gcc-c++/kernel-headers-2.6.32-696.30.1.el6.x86_64.rpm
rpm -ivh ${path}/gcc-c++/libgomp-4.4.7-4.el6.x86_64.rpm
rpm -Uvh ${path}/gcc-c++/glibc-2.14.1-6.x86_64.rpm glibc-common-2.14.1-6.x86_64.rpm glibc-headers-2.14.1-6.x86_64.rpm glibc-devel-2.14.1-6.x86_64.rpm nscd-2.14.1-6.x86_64.rpm
rpm -Uvh ${path}/gcc-c++/glibc-2.3.4-2.41.i686.rpm --force --nodeps
rpm -ivh ${path}/gcc-c++/gcc-4.4.7-4.el6.x86_64.rpm
rpm -ivh ${path}/gcc-c++/libstdc++-4.4.7-4.el6.x86_64.rpm
rpm -ivh ${path}/gcc-c++/libstdc++-devel-4.4.7-4.el6.x86_64.rpm
rpm -ivh ${path}/gcc-c++/gcc-c++-4.4.7-4.el6.x86_64.rpm
rpm -ivh ${path}/gcc-c++/libstdc++-3.4.6-3.i386.rpm --force --nodeps 
rpm -ivh ${path}/libaio/libaio-devel-0.3.107-10.el6.x86_64.rpm 
rpm -ivh ${path}/libaio/libaio-0.3.105-2.i386.rpm --force
rpm -ivh ${path}/libaio/libaio-0.3.105-2.i386.rpm --force
rpm -ivh ${path}/libaio/libaio-devel-0.3.105-2.i386.rpm --force
rpm -ivh ${path}/unixODBC/unixODBC-2.2.14-14.el6.x86_64.rpm --nodeps
rpm -ivh ${path}/unixODBC/unixODBC-devel-2.2.14-14.el6.x86_64.rpm --nodeps
rpm -ivh ${path}/unixODBC/unixODBC-2.2.11-6.2.1.i386.rpm --force --nodeps
rpm -ivh ${path}/unixODBC/unixODBC-devel-2.2.11-2.i386.rpm --force --nodeps
rpm -ivh ${path}/libgcc/libgcc-3.4.6-8.i386.rpm --force
rpm -ivh ${path}/pdksh-5.2.14-alt5.x86_64.rpm