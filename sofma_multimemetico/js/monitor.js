#!/usr/local/bin/node


var cradle = require('cradle');

var c = new(cradle.Connection);
var db = c.database('sofea_test');

var feed = db.changes();

var population = 0;
feed.on('change', function (change) {
    if ( change.id == 'solution' ) {
	console.log("\n\n");
	population = 0;
    }
    if ( !change.deleted && change.id.match(/[01]+/) ){
	if ( change.changes[0].rev.match(/^1-/) ) {
	    population++;
	} else {
	    population--;
	}
    }
    console.log( population );
	 
});

