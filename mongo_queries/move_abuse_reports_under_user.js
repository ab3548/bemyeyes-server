db.abuse_reports.find().forEach(function(data) {
  if(data.reporter ==="helper"){
    print('helper');
    blind = db.users.findOne({_id:data.blind_id});
    db.users.update({
      '_id':blind._id
    },
     { $push: { abuse_reports: data } }
    );
  }
  else{

    print('blind');
    helper = db.users.findOne({_id:data.helper_id});
    db.users.update({
      '_id':helper._id
    },
     { $push: { abuse_reports: data } }
    );
  }
});

db.abuse_reports.drop();