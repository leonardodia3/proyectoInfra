const AWS=require("aws-sdk")

const db=new AWS.DynamoDB.DocumentClient()

exports.handler=async(event)=>{

 const body=JSON.parse(event.body)

 await db.put({

   TableName:"attendance",

   Item:{

      pk:`STUDENT#${body.dni}`,
      sk:"PROFILE",

      name:body.name,

      email:body.email,

      classroom:body.classroom

   }

 }).promise()

 return{

   statusCode:200,

   body:JSON.stringify({

      message:"Alumno registrado"

   })

 }

}