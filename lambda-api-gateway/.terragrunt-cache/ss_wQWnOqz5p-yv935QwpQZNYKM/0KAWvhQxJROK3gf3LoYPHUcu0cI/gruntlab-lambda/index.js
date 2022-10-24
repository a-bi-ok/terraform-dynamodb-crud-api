// Lambda function code

const AWS = require("aws-sdk");

const dynamo = new AWS.DynamoDB.DocumentClient();

exports.handler = async (event, context) => {
  var re = new RegExp("/v1/(.*)");
  let body;
  let prefix;

  console.log("debug [event] =", event);

  let statusCode = 200;
  const headers = {
    "Content-Type": "application/json",
  };

  // try {
  //   switch (event.routeKey) {
  //     case "DELETE /v1/{type}/{category}":
  //       prefix =
  //         event.rawPath.match(re) == null ? null : event.rawPath.match(re)[1];
  //       await dynamo
  //         .delete({
  //           TableName: "mock_spur_database",
  //           Key: {
  //             prefix: prefix,
  //           },
  //         })
  //         .promise();
  //       body = `Deleted item ${event.queryStringParameters.id}`;
  //       break;
  //     case "GET /v1/{type}/{category}":
  //       console.log(
  //         "debug [GET /v1/{type}/{category}] queryStringParameters = ",
  //         event
  //       );
  //       prefix =
  //         event.rawPath.match(re) == null ? null : event.rawPath.match(re)[1];
  //       console.log("debug [GET /v1/{type}/{category}] prefix = ", prefix);

  //       body = await dynamo
  //         .get({
  //           TableName: "mock_spur_database",
  //           Key: {
  //             prefix: prefix,
  //           },
  //         })
  //         .promise();
  //       break;
  //     case "GET /v1":
  //       body = await dynamo.scan({ TableName: "mock_spur_database" }).promise();
  //       console.log("debug [GET /v1] queryStringParameters = ");
  //       break;
  //     case "PUT /v1/{type}/{category}":
  //       prefix =
  //         event.rawPath.match(re) == null ? null : event.rawPath.match(re)[1];
  //       let requestJSON = JSON.parse(event.body);
  //       await dynamo
  //         .put({
  //           TableName: "mock_spur_database",
  //           Item: {
  //             id: requestJSON.id,
  //             table: requestJSON.table,
  //             prefix: prefix,
  //             data: requestJSON.data,
  //           },
  //         })
  //         .promise();
  //       body = `Put item ${requestJSON.id}`;
  //       break;
  //     default:
  //       throw new Error(`Unsupported route: "${event.routeKey}"`);
  //   }
  // } catch (err) {
  //   statusCode = 400;
  //   body = err.message;
  // } finally {
  //   body = JSON.stringify(body);
  // }

  return {
    statusCode,
    body,
    headers,
  };
};
