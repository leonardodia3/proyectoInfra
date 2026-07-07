const AWS=require("aws-sdk")

const db=new AWS.DynamoDB.DocumentClient()

exports.handler=async(event)=>{

 const body=JSON.parse(event.body)

 await db.put({

    TableName:"attendance",

    Item:{

      pk:`STUDENT#${body.dni}`,

      sk:`ATTENDANCE#${Date.now()}`,

      timestamp:new Date().toISOString(),

      method:"MANUAL"

    }

 }).promise()

 return{

    statusCode:200,

    body:"ok"

 }

}