function createLogForTimeSpan(startDate, endDate, weekNumber){
  var sum_call_length = 0;
  var sum_wait_time = 0;
  var count = 0;
  var failedCount = 0;
  var sum_number_of_helpers_requested = 0;
  var max_number_of_helpers_requested = 0;

  db.request_logs.find({request_created:{$gte:startDate, $lte: endDate}, answered:{$ne:null}}).forEach(function(request_log) {
    sum_call_length += request_log.length_in_seconds;
    sum_wait_time += request_log.wait_length_in_seconds;
    sum_number_of_helpers_requested += request_log.number_of_helpers_requested;
    request_log.number_of_helpers_requested > max_number_of_helpers_requested ?
      max_number_of_helpers_requested = request_log.number_of_helpers_requested
        : max_number_of_helpers_requested = max_number_of_helpers_requested
  });
  failedCount = db.request_logs.count({request_created:{$gte:startDate, $lte: endDate}, answered:null});
  count = db.request_logs.count({request_created:{$gte:startDate, $lte: endDate}});

  var average_call_length = sum_call_length / count;
  var average_wait_time = sum_wait_time / count;
  var average_number_of_helpers_requested = sum_number_of_helpers_requested / count;

  db.request_log_aggregation.insert({
    count:count,
    failed_count: failedCount,
    average_wait_time: Math.round(average_wait_time * 100) / 100,
    average_call_length: Math.round(average_call_length * 100) / 100,
    average_number_of_helpers_requested: Math.round(average_number_of_helpers_requested * 100) / 100,
    max_number_of_helpers_requested:max_number_of_helpers_requested,
    created_at: new Date(),
    start_date:startDate,
    end_date: endDate,
    week_number: weekNumber
  });

}


load('/usr/local/src/moment/moment.min.js');
var lastWeek = moment().subtract(7, 'days');
var twoWeeksAgo = moment().subtract(14, 'days');
var threeWeeksAgo = moment().subtract(21, 'days');
var now = moment();

createLogForTimeSpan(lastWeek.toDate(), now.toDate(), lastWeek.week());
createLogForTimeSpan(twoWeeksAgo.toDate(), lastWeek.toDate(), twoWeeksAgo.week());
createLogForTimeSpan(threeWeeksAgo.toDate(), twoWeeksAgo.toDate(), threeWeeksAgo.week());

