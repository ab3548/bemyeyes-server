   db.request_logs.remove({})

db.event_logs.find().forEach(function(event_log) {
    if (event_log.name === 'request_created') {
        var request_id = event_log.event_log_objects[0].json_serialized;
        var request_created = event_log.created_at;
        var answered = db.event_logs.findOne({
            name: 'request_answered',
            'event_log_objects.0.json_serialized': request_id
        });
        var stopped = db.event_logs.findOne({
            name: 'request_stopped',
            'event_log_objects.0.json_serialized': request_id
        });
        var cancelled = db.event_logs.findOne({
            name: 'request_cancelled',
            'event_log_objects.0.json_serialized': request_id
        });

        var number_of_helpers_requested = db.event_logs.count({
             name: 'helper_notified',
            'event_log_objects.0.json_serialized': {$regex:request_id}
        });

        print('--------------------------------------------');

        if (answered) {
            print('answered');
            print(answered.created_at);
        }

        if (stopped) {
            print('stopped:');
            print(stopped.created_at);
        }

        if (cancelled) {
            print('cancelled');
            print(cancelled.created_at);
        }

        if (answered && stopped) {
            var call_length = Math.abs(stopped.created_at - answered.created_at)/1000;
            var wait_length = Math.abs(request_created - answered.created_at)/1000;
            print('length');
            print(call_length / 1000);
        }

        db.request_logs.insert({
            request_id: request_id,
            request_created: request_created,
            answered: answered?answered.created_at: null,
            stopped: stopped?stopped.created_at:null,
            cancelled: cancelled?cancelled.created_at:null,
            length_in_seconds: call_length,
            wait_length_in_seconds: wait_length,
            number_of_helpers_requested: number_of_helpers_requested,
            created_at: new Date()

        });
    }
});
