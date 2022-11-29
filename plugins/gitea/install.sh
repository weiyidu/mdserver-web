#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

curPath=`pwd`
rootPath=$(dirname "$curPath")
rootPath=$(dirname "$rootPath")
serverPath=$(dirname "$rootPath")


install_tmp=${rootPath}/tmp/mw_install.pl
if [ -f ${rootPath}/bin/activate ];then
	source ${rootPath}/bin/activate
fi


URL_DOWNLOAD=https://dl.gitea.io/


bash ${rootPath}/scripts/getos.sh
OSNAME=`cat ${rootPath}/data/osname.pl`
OSNAME_ID=`cat /etc/*-release | grep VERSION_ID | awk -F = '{print $2}' | awk -F "\"" '{print $2}'`


getBit(){
	echo `getconf  LONG_BIT`
}


Install_App()
{

	mkdir -p $serverPath/source/gitea

	if id git &> /dev/null ;then 
	    echo "git uid is `id -u git`"
	    echo "git shell is `grep "^git:" /etc/passwd |cut -d':' -f7 `"
	else
	    groupadd git
		useradd -g git git
	fi

	if [ "macos" != "$OSNAME" ];then
		if [ ! -d /home/git ];then
			mkdir -p /home/git
			chown -R git:git /home/git
		fi
	fi

	echo '正在安装脚本文件...' > $install_tmp
	version=$1
	

	git config --global push.default simple

	if [ "macos" == "$OSNAME" ];then
		file=gitea-${version}-darwin-10.12-amd64
	else
		file=gitea-${version}-linux-amd64
	fi

	file_xz="${file}.xz"
	echo "wget -O $serverPath/source/gitea/$file_xz ${URL_DOWNLOAD}/gitea/${version}/${file_xz}"
	if [ ! -f $serverPath/source/gitea/$file_xz ];then
		wget  --no-check-certificate -O $serverPath/source/gitea/$file_xz ${URL_DOWNLOAD}/gitea/${version}/${file_xz}
	fi

	cd $serverPath/source/gitea && xz -k -d $file_xz
	if [ -f $file ];then
		mkdir -p $serverPath/gitea
		mv $serverPath/source/gitea/$file $serverPath/gitea/gitea
		chmod +x $serverPath/gitea/gitea

		chown -R git:git $serverPath/gitea
	fi


	if [ -d $serverPath/gitea ];then
		echo $version > $serverPath/gitea/version.pl

		cd ${rootPath} && python3 plugins/gitea/index.py start
		cd ${rootPath} && python3 plugins/gitea/index.py initd_install
	fi

	echo 'install success' > $install_tmp
}

Uninstall_App()
{

	if [ -f /usr/lib/systemd/system/gitea.service ];then
		systemctl stop gitea
		systemctl disable gitea
		rm -rf /usr/lib/systemd/system/gitea.service
		systemctl daemon-reload
	fi

	if [ -f $serverPath/gitea/initd/gitea ];then
		$serverPath/gitea/initd/gitea stop
	fi

	rm -rf $serverPath/gitea
	echo 'uninstall success' > $install_tmp
}


action=$1
version=$2
if [ "${1}" == 'install' ];then
	Install_App $version
else
	Uninstall_App $version
fi