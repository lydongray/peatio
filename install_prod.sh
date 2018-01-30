#!bin/bash
# Update system
echo 'Updating system'
sudo apt-get update
sudo apt-get upgrade -y

# Download configuration files
echo 'Downloading configuration files'
wget https://gist.githubusercontent.com/scatterp2/3f6b1ae1965de18057a896bedc9a6132/raw/cb230dc8b9cc5dab6da64f7e34cf5e50ae373092/passenger.conf
wget https://gist.githubusercontent.com/scatterp2/5aab2adb578020f93d0f2146e0aac61b/raw/2b2e5fc7e8a95eea3d4b791217c5d1e5b848cd43/bitcoin.conf

# Remove conflicting packages
echo 'Removing apache2'
sudo apt-get remove -y apache2

# Install dependencies
echo 'Installing dependencies'
sudo apt-get install git curl zlib1g-dev build-essential libssl-dev libreadline-dev libyaml-dev libsqlite3-dev sqlite3 libxml2-dev libxslt1-dev libcurl4-openssl-dev libffi-dev nano dialog

# Install RVM - Ruby Version Manager
echo 'Installing RVM Key'
RUBY_VERISON=2.2.2
gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB
# Install Ruby and Rails
echo 'Installing Ruby 2.2.2 and Rails using RVM'
\curl -sSL https://get.rvm.io | bash -s stable --ruby=$RUBY_VERISON --gems=rails
# Disable installing documentation with Gems
echo "gem: --no-ri --no-rdoc" > ~/.gemrc
# Set Ruby version to use
rvm use $RUBY_VERISON
# Initialise RVM
source /home/deploy/.rvm/scripts/rvm

# Install MySql Database
echo 'Installing MySql Database'
sudo apt-get install mysql-server  mysql-client  libmysqlclient-dev

# Install Redis - In-memory data structure
echo 'Installing Redis'
sudo add-apt-repository ppa:chris-lea/redis-server
sudo apt-get update
sudo apt-get install redis-server

# Install RabbitMQ - Message queuing system
echo 'Installing RabbitMQ'
curl http://www.rabbitmq.com/rabbitmq-release-signing-key.asc | sudo apt-key add -
sudo apt-add-repository 'deb http://www.rabbitmq.com/debian/ testing main'
sudo apt-get update
sudo apt-get install rabbitmq-server
sudo rabbitmq-plugins enable rabbitmq_management
sudo service rabbitmq-server restart
wget http://localhost:15672/cli/rabbitmqadmin
chmod +x rabbitmqadmin
sudo mv rabbitmqadmin /usr/local/sbin

# Install Bitcoind - Bitcoin client
echo 'Installing Bitcoind'
sudo add-apt-repository ppa:bitcoin/bitcoin
sudo apt-get update
sudo apt-get install bitcoind
# Create Bitcoind configuration
mkdir -p ~/.bitcoin
touch ~/.bitcoin/bitcoin.conf

# Install Nginx
echo 'Installing Nginx'
# Install Phusion's PGP key to verify packages
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 561F9B9CAC40B2F7
# Install Nginx package
sudo apt-get install nginx-extras
# Add HTTPs support
sudo apt-get install apt-transport-https ca-certificates

# Install Passenger
echo 'Installing Passenger'
# Install passenger
sudo add-apt-repository 'deb https://oss-binaries.phusionpassenger.com/apt/passenger xenial main'
sudo apt-get update
sudo apt-get install passenger
# Invoke  passenger-config
which passenger-config | --ruby-command

# Configure Passenger
echo 'Configure Passenger'
# Remove default passenger site
sudo rm /etc/nginx/sites-enabled/default

# Configure Nginx.conf and copy to default location
echo 'Configure Nginx.conf'
# Copy nginx.conf to home folder
cp /etc/nginx/nginx.conf .
echo 'Take note of the following location:'
echo which passenger-config
read -p "Press [Enter] key to update nginx.conf..."
dialog --msgbox 'Update nginx.conf by setting the correct Ruby location from previous step' 10 20
sudo cp nginx.conf /etc/nginx/nginx.conf
sudo rm nginx.conf

# Install JavaScript Runtime - for asset pipeline to work
echo 'Installing Javascript Runtime'
curl -sL https://deb.nodesource.com/setup_8.x | sudo bash -
sudo apt-get install nodejs

# Install ImageMagick
echo 'Installing ImageMagick'
sudo apt-get install imagemagick

# Clone the project
echo 'Clonging the project'
mkdir -p ~/peatio
git clone git://github.com/peatio/peatio.git ~/peatio/current
# Move to application folder
cd peatio/current

# Install dependency gems
echo 'Installing Gems'
bundle install --without development test --path vendor/bundle

# Initialise config
echo 'Initialising config'
bin/init_config

# Configure Pusher settings
echo 'Configure Pusher settings'
nano config/application.yml

# Configure Bitcoind RPC endpoint
echo 'Configure Bitcoind RPC endpoint settings'
nano config/currencies.yml

# Configure database settings
echo 'Configure database settings and setup database'
nano config/database.yml
# Set up database
bundle exec rake db:setup

# Precompile assets
echo 'Precompiling assets'
bundle exec rake assets:precompile

# Run Daemons
echo 'Starting Daemons'
bundle exec rake daemons:start
# Move home
cd ~/

# Configure SSL certificate

# Configure Nginx application and start
echo 'Configure Nginx application and start'
sudo ln -s ~/peatio/current/config/nginx.conf /etc/nginx/conf.d/peatio.conf
sudo service nginx restart

# Done
echo 'Done'
