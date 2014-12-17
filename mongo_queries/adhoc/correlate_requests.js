db.event_logs.find({name:"request_created", created_at: {$gte:ISODate("2014-11-01T22:00:00Z")}}).forEach(function (data){
  var request_id = JSON.parse(data.event_log_objects[0].json_serialized);
  print('///////////////////////////////////')
  print(request_id);
  db.event_logs.find({name:"helper_notified", created_at: {$gte: data.created_at}}).forEach(function(el){
    var request = JSON.parse(el.event_log_objects[0].json_serialized);
    var helper = JSON.parse(el.event_log_objects[1].json_serialized);
    if(request.id == request_id){
      print (el.created_at);
      print(helper.email);
    }
  });
});
