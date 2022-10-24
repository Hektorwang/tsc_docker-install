# tsc_docker  

## 部署要求  

1. 支持x86_64和aarch64两种架构的安装.  
2. kernel版本需要大于3.10  
3. 系统初始化程序必须是systemd  
4. 必须安装ps命令.  
5. XZ utils大于4.9  
6. iptables版本大于1.4  
7. 必须关闭selinux  

## 部署方法  

1. 将压缩包解压到``/home/tsc/install/``  
2. 执行安装命令:  

```bash
cd /home/tsc/install/tsc_docker-install
./install.sh install /home/tsc/docker
```
