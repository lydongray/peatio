#!bin/bash
# Update system
echo 'Updating system'
sudo apt-get update
sudo apt-get upgrade -y

# Download configuration files
echo 'Downloading configuration files'
wget https://raw.githubusercontent.com/lydongray/peatio/master/install/development/bitcoin.conf

# Remove conflicting packages
echo 'Removing apache2'
sudo apt-get remove -y apache2

# Install dependencies
echo 'Installing dependencies'
sudo apt-get install git curl zlib1g-dev build-essential libssl-dev libreadline-dev libyaml-dev libsqlite3-dev sqlite3 libxml2-dev libxslt1-dev libcurl4-openssl-dev libffi-dev nano dialog software-properties-common python-software-properties -y

# Install RVM - Ruby Version Manager
echo 'Installing RVM Key'
RUBY_VERISON=2.2.2
gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB
# Install Ruby and Rails
echo 'Installing Ruby 2.2.2 and Rails using RVM'
\curl -sSL https://get.rvm.io | bash -s stable --ruby=$RUBY_VERISON --gems=rails
# Disable installing documentation with Gems
echo "gem: --no-ri --no-rdoc" > ~/.gemrc
# Initialise RVM
source .rvm/scripts/rvm
# Set Ruby version to use
rvm use $RUBY_VERISON

# Install MySql Database
echo 'Installing MySql Database'
sudo apt-get install mysql-server  mysql-client  libmysqlclient-dev -y

# Install Redis - In-memory data structure
echo 'Installing Redis'
sudo add-apt-repository ppa:chris-lea/redis-server -y
sudo apt-get update
sudo apt-get install redis-server -y

# Install RabbitMQ - Message queuing system
echo 'Installing RabbitMQ'
curl http://www.rabbitmq.com/rabbitmq-release-signing-key.asc | sudo apt-key add -
sudo apt-add-repository 'deb http://www.rabbitmq.com/debian/ testing main'
sudo apt-get update
sudo apt-get install rabbitmq-server -y
sudo rabbitmq-plugins enable rabbitmq_management
sudo service rabbitmq-server restart
wget http://localhost:15672/cli/rabbitmqadmin
chmod +x rabbitmqadmin
sudo mv rabbitmqadmin /usr/local/sbin

# Install Bitcoind - Bitcoin client
echo 'Installing Bitcoind'
sudo add-apt-repository ppa:bitcoin/bitcoin -y
sudo apt-get update
sudo apt-get install bitcoind -y
# Create Bitcoind configuration
mkdir -p ~/.bitcoin
mv bitcoin.conf ~/.bitcoin/bitcoin.conf

# Install PhaontomJS
#Peatio uses Capybara with PhantomJS to do the feature tests, so if you want to run the tests. Install the PhantomJS is neccessary
echo 'Install PhantomJS'
sudo apt-get update
sudo apt-get install build-essential chrpath git-core libssl-dev libfontconfig1-dev -y
cd /usr/local/share
PHANTOMJS_VERISON=1.9.8
sudo wget https://bitbucket.org/ariya/phantomjs/downloads/phantomjs-$PHANTOMJS_VERISON-linux-x86_64.tar.bz2
sudo tar xjf phantomjs-$PHANTOMJS_VERISON-linux-x86_64.tar.bz2
sudo ln -s /usr/local/share/phantomjs-$PHANTOMJS_VERISON-linux-x86_64/bin/phantomjs /usr/local/share/phantomjs
sudo ln -s /usr/local/share/phantomjs-$PHANTOMJS_VERISON-linux-x86_64/bin/phantomjs /usr/local/bin/phantomjs
sudo ln -s /usr/local/share/phantomjs-$PHANTOMJS_VERISON-linux-x86_64/bin/phantomjs /usr/bin/phantomjs
# Move home
cd ~/

# Install JavaScript Runtime - for asset pipeline to work
echo 'Installing Javascript Runtime'
curl -sL https://deb.nodesource.com/setup_8.x | sudo bash -
sudo apt-get install nodejs -y

# Install ImageMagick
echo 'Installing ImageMagick'
sudo apt-get install imagemagick -y

# Clone the project
echo 'Clonging the project'
mkdir -p ~/peatio
git clone git://github.com/lydongray/peatio.git ~/peatio
# Move to application folder
cd peatio

# Set to development
echo 'Setting deployment to development'
echo "export RAILS_ENV=development" >> ~/.bashrc
source ~/.bashrc

# Install dependency gems
echo 'Installing Gems'
bundle install --without production

# Initialise config
echo 'Initialising config'
bin/init_config development

# Set up database
echo 'Configuring database'
bundle exec rake db:setup
bundle exec rake db:migrate

# Run Daemons
echo 'Starting Daemons'
bundle exec rake daemons:start

# Start server
echo 'Starting server'
bundle exec rails server
cd ~/

# Done
echo 'Done. Visit http://localhost:3000'
echo 'user: admin@peatio.dev, pass: Pass@word8'