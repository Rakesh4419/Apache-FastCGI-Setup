FROM centos:7

#Environment variables
RUN echo "nameserver 8.8.8.8" > /etc/resolve.conf
RUN yum update -y
RUN yum install expat-devel pcre pcre-devel openssl-devel libtool autoconf -y
RUN yum groupinstall " Development Tools"  -y
RUN yum install wget -y
WORKDIR  /usr/local/src/
RUN wget https://mirrors.estointernet.in/apache//httpd/httpd-2.4.46.tar.gz
RUN tar xvzf httpd-2.4.46.tar.gz
RUN wget https://github.com/apache/apr/archive/1.6.2.tar.gz -O apr-1.6.2.tar.gz
RUN wget https://github.com/apache/apr-util/archive/1.6.0.tar.gz -O apr-util-1.6.0.tar.gz
RUN tar -xzf apr-1.6.2.tar.gz
RUN tar -xzf apr-util-1.6.0.tar.gz
RUN mv apr-1.6.2 httpd-2.4.46/srclib/apr
RUN mv apr-util-1.6.0 httpd-2.4.46/srclib/apr-util
WORKDIR  httpd-2.4.46
RUN ./buildconf
RUN ./configure --enable-so --prefix=/usr/local/apache --with-mpm=worker --enable-unique-id --enable-ssl --enable-rewrite  --enable-deflate --enable-suexec --with-suexec-docroot="/home" --with-suexec-caller="nobody" --with-suexec-logfile="/usr/local/apache/logs/suexec_log" --enable-asis --enable-filter --with-pcre --with-mpm=worker --enable-headers --enable-expires --enable-proxy --enable-cgi --enable-rewrite --enable-spelling --enable-version

RUN make
RUN make install
#CMD     ["/usr/local/apache/bin/apachectl","-D","FOREGROUND"]

#Installing php

WORKDIR /usr/local/src/
RUN wget http://au1.php.net/distributions/php-7.2.3.tar.gz
RUN tar xvzf php-7.2.3.tar.gz
RUN yum install epel-release -y
RUN yum install libxml2.x86_64 libxml2-devel.x86_64 libxslt-devel.x86_64 libxslt.x86_64 libxslt-devel.x86_64 libxslt.x86_64 bzip2-libs.x86_64 bzip2-devel.x86_64 libcurl-devel.x86_64 curl.x86_64 libjpeg-turbo.x86_64 libjpeg-turbo-devel.x86_64 libpng.i686 libpng-devel.x86_64 freetype-devel.x86_64 freetype.x86_64 libc-client-devel  uw-imap-devel libc-client libc-client-devel.i386 -y
CMD ["/usr/local/apache/bin/apachectl", "-k", "start"]
WORKDIR /usr/local/src/php-7.2.3/
RUN ./configure --with-zlib --with-zlib-dir=/usr --with-bz2 --enable-soap --enable-exif -with-config-file-path=/usr/local/php --with-config-file-scan-dir=/usr/local/php/php.d --enable-phar --enable-bcmath --enable-calendar --with-curl --with-iconv --with-mysql --with-mysqli --with-mysqli=mysqlnd --with-mcrypt --with-mhash --with-gettext --with-xsl --with-xmlrpc --with-pdo-mysql=mysqlnd --enable-posix --enable-ftp --with-openssl --enable-mbstring --with-jpeg-dir=/usr --with-freetype-dir=/usr -with-png-dir=/usr --with-libxml-dir=/usr --with-kerberos --with-xsl --with-bz2 --enable-sockets --enable-zip --with-gd --enable-gd-native-ttf --enable-sockets --with-libdir=lib64 --with-kerberos --with-imap-ssl --with-imap --with-pcre-regex --libdir=/usr/lib64 --with-mysql-sock=/var/lib/mysql/mysql.sock
RUN make
RUN make install

#Installing FastCGI

WORKDIR /usr/local/src/
RUN yum install subversion -y 
RUN svn checkout http://svn.apache.org/repos/asf/httpd/mod_fcgid/trunk mod_fcgid
WORKDIR /usr/local/src/mod_fcgid/
RUN APXS=/usr/local/apache/bin/apxs ./configure.apxs
RUN make && make install

#Copying FastCG files and configuring apache 

COPY conf/fcgid.conf /usr/local/apache/conf/
COPY conf/httpd.conf /usr/local/apache/conf/httpd.conf
COPY ssl /usr/local/apache/

#Configuring user and virtualhost
RUN mkdir /usr/local/apache/conf.d/
COPY conf/domainconf.conf /usr/local/apache/conf.d/
RUN useradd posttest
RUN mkdir -p /home/posttest/public_html/cgi-bin
COPY conf/php-fcgi-starter /home/posttest/public_html/cgi-bin/
RUN chmod +x /home/posttest/public_html/cgi-bin/php-fcgi-starter
COPY public_html/ /home/posttest/public_html/
RUN chown -R posttest.posttest /home/posttest/public_html
RUN chmod 750 /home/posttest/public_html
RUN chmod 755 /home/posttest
RUN chown posttest.nobody /home/posttest/public_html


CMD     ["/usr/local/apache/bin/apachectl","-D","FOREGROUND"]
