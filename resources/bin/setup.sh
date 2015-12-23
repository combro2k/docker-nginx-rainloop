#!/bin/bash

export DEBIAN_FRONTEND=noninteractive
export PACKAGES=(
	'git'
	'curl'
	'nginx'
	'php5-fpm'
	'php5-mysql'
	'php5-apcu'
	'php5-imagick'
	'php5-imap'
	'php5-mcrypt'
	'php5-gd'
	'libssh2-php'
	'php5-memcache'
	'php5-memcached'
	'php5-curl'
	'bsdtar'
)

pre_install() {
    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys ABF5BD827BD9BF62
    echo deb http://nginx.org/packages/mainline/ubuntu trusty nginx > /etc/apt/sources.list.d/nginx-stable-trusty.list

    apt-get update -q 2>&1
    apt-get install -yq ${PACKAGES[@]} 2>&1

    sources=(
        '/etc/nginx/sites-enabled'
        '/etc/nginx/sites-available'
        '/data/web'
        '/data/logs'
	)

    mkdir -p ${sources[@]} 2>&1
}

configure_php5_fpm() {
    echo "upload_max_filesize = 25M;" > /etc/php5/fpm/conf.d/z-rainloop.ini
    echo "post_max_size = 25M;" >> /etc/php5/fpm/conf.d/z-rainloop.ini
    echo "cgi.fix_pathinfo = 0;" >> /etc/php5/fpm/conf.d/z-rainloop.ini
    sed -i -e 's/^listen =.*/listen = \/var\/run\/php5-fpm.sock/' /etc/php5/fpm/pool.d/www.conf
}

install_rainloop() {
    curl -ssL http://repository.rainloop.net/v2/webmail/rainloop-latest.zip | bsdtar -C /data/web -mxf- || return 1
    chown www-data:www-data /data/web -R

    return 0
}

post_install() {
    apt-get autoremove 2>&1 || return 1
	apt-get autoclean 2>&1 || return 1
	rm -fr /var/lib/apt 2>&1 || return 1

	return 0
}

build() {
	if [ ! -f "${INSTALL_LOG}" ]
	then
		touch "${INSTALL_LOG}" || exit 1
	fi

	chmod +x /usr/local/bin/*

	tasks=(
        'pre_install'
        'configure_php5_fpm'
		'install_rainloop'
	)

	for task in ${tasks[@]}
    do
        name=$(echo ${task} | sed 's/_/ /g')

        echo -e "\e[92mRunning build task ${name}...\e[0m"
        if ! ${task} >> ${INSTALL_LOG} 2>&1 ; then
            return 1
        fi
    done
}

if [ $# -eq 0 ]
then
	echo "No parameters given! (${@})"
	echo "Available functions:"
	echo

	compgen -A function

	exit 1
else
	for task in ${@}
	do
		echo "Running ${task}..." 2>&1  || exit 1
		${task} || exit 1
	done
fi
