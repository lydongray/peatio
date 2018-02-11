#!bin/bash
# Update system
echo 'Updating system'
sudo apt-get update
sudo apt-get upgrade -y

# Download configuration files
echo 'Downloading configuration files'
wget https://raw.githubusercontent.com/lydongray/peatio/master/install/production/bitcoin.conf
wget https://raw.githubusercontent.com/lydongray/peatio/master/install/production/passenger.conf

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

# Install Phusion's PGP key to verify packages
echo 'Install Phusions PGP key'
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 561F9B9CAC40B2F7
# Add HTTPs support to APT
echo 'Add HTTPs support'
sudo apt-get install apt-transport-https ca-certificates -y
# Add passenger repository
echo 'Add Passenger repository'
sudo add-apt-repository 'deb https://oss-binaries.phusionpassenger.com/apt/passenger xenial main'
sudo apt-get update

# Install Nginx
echo 'Installing Nginx'
# Install Nginx package
sudo apt-get install nginx-extras -y

# Install Passenger
echo 'Installing Passenger'
sudo apt-get install passenger -y
# Update passenger.conf with correct ruby location
# Eg. passenger_ruby [location];
# Get passenger_ruby location and store in file
$(which passenger-config) --ruby-command > passenger-config.conf
# Extract the exact location using regex and stick it into passenger.conf line 1
PASSENGER_CONFIG="$(grep -oP '(?<=Nginx\s:\s).*' passenger-config.conf)"
# Add variable to position 2
sed -i "2i$PASSENGER_CONFIG;" passenger.conf
# Remove temporary config file
sudo rm passenger-config.conf
# Remove default passenger site
sudo rm /etc/nginx/sites-enabled/default
# Move passenger.conf to nginx.conf location
sudo mv passenger.conf /etc/nginx

# Configure Nginx.conf and copy to default location
echo 'Configure Nginx.conf'
# Copy nginx.conf to home folder
cp /etc/nginx/nginx.conf .
# Uncomment passenger.conf include
sed -i 's/# include \/etc\/nginx\/passenger\.conf;/include \/etc\/nginx\/passenger.conf;/g' nginx.conf
sudo cp nginx.conf /etc/nginx/nginx.conf
sudo rm nginx.conf

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
git clone git://github.com/lydongray/peatio.git ~/peatio/current
# Move to application folder
cd peatio/current

# Set to production
echo 'Setting deployment to production'
echo "export RAILS_ENV=production" >> ~/.bashrc
source ~/.bashrc

# Install dependency gems
echo 'Installing Gems'
bundle install --without development test --path vendor/bundle

# Initialise config
echo 'Initialising config'
bin/init_config production

# Set up database
echo 'Configuring database'
bundle exec rake db:setup
bundle exec rake db:migrate

# Precompile assets
echo 'Precompiling assets'
bundle exec rake assets:precompile

# Run Daemons
echo 'Starting Daemons'
bundle exec rake daemons:start
# Move home
cd ~/

# Configure Nginx application and start
echo 'Configure Nginx application and start'
sudo ln -s ~/peatio/current/config/environments/production/peatio.conf /etc/nginx/conf.d/peatio.conf
sudo service nginx restart

# Configure SSL certificate
echo 'Configuring SSL'
# Install certbot
sudo add-apt-repository ppa:certbot/certbot -y
sudo apt-get update
sudo apt-get install python-certbot-nginx -y
# Install certificate
# Add .well-known folders
sudo mkdir ~/peatio/current/public/.well-known/acme-challenge
# Certbot will add necessary SSL configurations
sudo certbot --redirect --authenticator webroot --webroot-path /home/deploy/peatio/current/public --installer nginx -d bithingy.com -d www.bithingy.com

# Done
echo 'Done'