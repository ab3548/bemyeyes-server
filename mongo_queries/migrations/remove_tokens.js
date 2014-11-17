db.tokens.find().forEach(function(token){
  db.devices.update(
   { _id: token.device_id },
   {
     $set: {
       expiry_time : token.expiry_time,
       auth_token : token.token
     }
   }
);
  db.tokens.remove({_id:token._id});
});

//db.tokens.remove({})

db.tokens.find().forEach(function(token){
  device = db.devices.findOne(
   { _id: token.device_id }
);
  if(device){
    print(device.device_name)
}
});
