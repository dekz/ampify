FROM      ubuntu:12.10
MAINTAINER  Jacob Evans "jacob@dekz.net"

# make sure the package repository is up to date
#RUN echo "deb http://archive.ubuntu.com/ubuntu precise main universe" > /etc/apt/sources.list
RUN apt-get update

RUN apt-get install -y inotify-tools nginx apache2 openssh-server
RUN apt-get install -q -y ca-certificates
RUN apt-get install -y -q vim
RUN apt-get install -y -q curl
RUN apt-get install -y -q git
RUN apt-get install -y -q make
RUN apt-get install -y -q wget
RUN apt-get install -y -q build-essential
RUN apt-get install -y -q g++

RUN apt-get install -y -q memcached
RUN apt-get install -y -q redis-server

# RBENV
RUN git clone https://github.com/sstephenson/rbenv.git /usr/local/rbenv
RUN echo '# rbenv setup' > /etc/profile.d/rbenv.sh
RUN echo 'export RBENV_ROOT=/usr/local/rbenv' >> /etc/profile.d/rbenv.sh
RUN echo 'export PATH="$RBENV_ROOT/bin:$PATH"' >> /etc/profile.d/rbenv.sh
RUN echo 'eval "$(rbenv init -)"' >> /etc/profile.d/rbenv.sh
RUN chmod +x /etc/profile.d/rbenv.sh
RUN mkdir /usr/local/rbenv/plugins
RUN git clone https://github.com/sstephenson/ruby-build.git /usr/local/rbenv/plugins/ruby-build

ENV RBENV_ROOT /usr/local/rbenv
ENV PATH "$RBENV_ROOT/bin:$RBENV_ROOT/shims:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
RUN rbenv install 2.0.0-p247
