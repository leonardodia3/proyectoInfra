const AWS=require("aws-sdk")

const db=new AWS.DynamoDB.DocumentClient()

exports.handler=async(event)=>{

 const dni=event.pathParameters.id

 const data=await db.query({

   TableName:"attendance",

   KeyConditionExpression:"pk=:pk",

   ExpressionAttributeValues:{

      ":pk":`STUDENT#${dni}`

   }

 }).promise()

 return{

   statusCode:200,

   body:JSON.stringify(data.Items)

 }

}