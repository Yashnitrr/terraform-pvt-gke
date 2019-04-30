const express = require('express');
const graphqlHTTP = require('express-graphql');
const { buildSchema } = require('graphql');
const request = require('request');

// Construct a schema, using GraphQL schema language
var schema = buildSchema(`
  type Query {
    express: String
    ping: String
  }
`);

// The root provides a resolver function for each API endpoint
var root = {
    express: async () => {
        try {
            let resp = await new Promise((resolve, reject) => {
                request('http://express:3000/ping', (err, res, body) => {
                    if (err) {
                        return reject(err);
                    }
                    let message = JSON.parse(res.body)['message'];
                    return resolve(message);
                });
            });
            return resp;
        } catch (error) {
            return 'Error Occurred';
        }
    },
    ping: () => {
        return "Pong";
    }
};

var app = express();
app.use('/graphql', graphqlHTTP({
    schema: schema,
    rootValue: root,
    graphiql: true,
}));
app.listen(4000);
console.log('Running a GraphQL API server at localhost:4000/graphql');
