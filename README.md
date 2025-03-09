# README

## Local development

```sh
# Set it up...
$ git clone https://github.com/hackclub/harbor && cd harbor

# Set your config
$ cp .env.example .env
# The only thing you need to set is SEED_USER_API_KEY, which should be your key 

# Build & run the project
$ docker compose run web --service-ports /bin/bash

# Now you're inside docker & you can do all the fun rails things...
app# bin/rails s -b 0.0.0.0 # this hosts the server on your computer w/ default port 3000
app# bin/rails c # start an interactive irb!
app# bin/rails db:migrate # migrate the database
```

Ever need to setup a new database?

```sh
# start a shell inside docker
$ docker compose run web --service-ports /bin/bash

# once inside, reset the db
app# $ bin/rails db:drop db:create db:migrate db:seed
```



