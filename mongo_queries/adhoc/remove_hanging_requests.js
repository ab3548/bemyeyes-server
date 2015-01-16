db.requests.update(
  {
  answered:false,
  stopped:false,
  created_at:{$lt: new Date(ISODate().getTime() - 1000 * 60 * 60 * 24 *2)}},
  {
    $set: { stopped: true },
  },
  {
    multi:true
  }
)
