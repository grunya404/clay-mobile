FROM dockerfile/nodejs:latest

# Install Git
RUN apt-get install -y git

# Add source
ADD . /opt/clay-mobile

WORKDIR /opt/clay-mobile

# Install app deps
RUN npm install

CMD ["npm", "start"]