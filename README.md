Bikestorming.org API
=======

REST API for http://bikestorming.org project

**Status**: Proof-of-concepts handling public bikes 

**What it does**:
- hosts push endpoint at `/public_bikes`
- validates input with json schema (`validators/public_bikes.coffee`)
- push data to given cartodb.com account

## Installation
```sh
npm install
cp config/cartodb.coffee.default config/cartodb.coffee
vim config/cartodb.coffee
```

## Running

On dev environment we recommend `nodeman`

On production env try `nvm` + [`pm2`](https://github.com/Unitech/pm2)

You can find sample [Postman](http://www.getpostman.com/features) requests in `test/postman-requests.json`
