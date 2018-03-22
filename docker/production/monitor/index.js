require('dotenv').config()

const { ApolloEngineLauncher } = require('apollo-engine')

// Define the Engine configuration.
const launcher = new ApolloEngineLauncher({
  apiKey: process.env.APOLLO_KEY,
  origins: [
    {
      http: {
        /* url: 'http://localhost:4001/graphiql',*/
        url: process.env.APOLLO_ORIGIN,
        overrideRequestHeaders: {
          /* Host: 'api.coderplanets.com',*/
          /* Host: 'coderplanets.com',*/
          /* Host: 'coderplanets.com',*/
          /* 'content-type': 'application/json',*/
          /* Origin: 'http://localhost:3000',*/
          /* special: 'Special header value',*/
          /* authorization: 'Bearer autk',*/
        },
      },
    },
  ],
  logging: {
    /* level: 'INFO',*/
    level: 'ERROR',
    /* level: 'INFO', */
    /* level: 'WARN', */
    /*
    request: {
      destination: 'STDOUT',
    },
    query: {
      destination: 'STDOUT',
    },
    */
  },
  frontends: [
    {
      /* parse evn-var issue */
      port: parseInt(process.env.APOLLO_FRONT_PORT.slice(1, -1)),
      endpoints: ['/graphiql'],
    },
  ],
})

// Start the Proxy; crash on errors.
launcher.start().catch(err => {
  throw err
})
