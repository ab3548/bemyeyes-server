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
  }
});

db.abuse_reports.drop();