db.requests.update(
  {
  answered:false,
  stopped:false,
  // ms * seconds * minutes *hour
  // 3 hours ago
  created_at:{$lt: new Date(ISODate().getTime() - 1000 * 60 * 60 * 3)}},
  {
    $set: { stopped: true },
  },
  {
    multi:true
  }
)
