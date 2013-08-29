FROM      ubuntu
MAINTAINER  Jacob Evans "jacob@dekz.net"

RUN apt-get -y update
RUN apt-get install -y -q software-properties-common
RUN apt-get install -y -q python-software-properties
RUN add-apt-repository -y "deb http://archive.ubuntu.com/ubuntu $(lsb_release -sc) universe"
RUN apt-get update

#RUN apt-get install -y inotify-tools nginx apache2 openssh-server
RUN apt-get install -y nginx
RUN apt-get install -q -y ca-certificates
RUN apt-get install -y -q vim
RUN apt-get install -y -q curl
RUN apt-get install -y -q git
RUN apt-get install -y -q make
RUN apt-get install -y -q wget
RUN apt-get install -y -q build-essential
RUN apt-get install -y -q g++
RUN apt-get install -y -q libssl-dev

RUN apt-get install -y -q sqlite3
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
ENV PATH $RBENV_ROOT/bin:$RBENV_ROOT/shims:$PATH
RUN rbenv install 2.0.0-p247
RUN rbenv rehash
RUN rbenv global 2.0.0-p247
RUN gem install bundler
