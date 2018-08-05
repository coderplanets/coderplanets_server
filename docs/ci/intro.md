
we use [Travis CI](https://travis-ci.org/) as continuous integration service,
current [build status](https://travis-ci.org/coderplanets/coderplanets_server) is
mentioned in README as: [![Build Status](https://travis-ci.org/coderplanets/coderplanets_server.svg?branch=dev)](https://travis-ci.org/coderplanets/coderplanets_server)
which will be refresh after every `commit push` or `PR merged`.

CI isn’t just for running tests, there are many other things to do:

- [x] make sure all the test is passed
- [x] make sure coveralls status refreshd
- [x] publish graphql schema to apollo-engine
- [x] check graphql schema is valid
- [x] make sure the commit message follow conventsions
