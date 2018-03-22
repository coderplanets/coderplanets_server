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
  // Tell the Proxy on what port to listen, and which paths should
  // be treated as GraphQL instead of transparently proxied as raw HTTP.
  // You can leave out the frontend section if you want: the default for
  // 'port' is process.env.PORT, and the default for graphqlPaths is
  // ['/graphql'].
  frontends: [
    {
      port: parseInt(process.env.APOLLO_FRONT_PORT),
      endpoints: ['/graphiql'],
    },
  ],
})

// Start the Proxy; crash on errors.
launcher.start().catch(err => {
  throw err
})
