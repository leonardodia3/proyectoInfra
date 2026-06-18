const AWS=require("aws-sdk")

const db=new AWS.DynamoDB.DocumentClient()

exports.handler=async()=>{

 const data=await db.scan({

    TableName:"attendance"

 }).promise()

 return{

   statusCode:200,

   body:JSON.stringify(data.Items)

 }

}