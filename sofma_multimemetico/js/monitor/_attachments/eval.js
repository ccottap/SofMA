$db = $.couch.db("sofea_test");
var evaluations_so_far;
//--------------------------------------------------------------
function evaluate (data) {
    var after_eval = new Array;
    if (data.rows.length == 0 ) {
        setTimeout('check_evaluations()',1000);
    } else {
        var best_chrom ={ fitness: 0 };
        for (i in data.rows) {
            var str = data.rows[i].value.str;
            var m = str.match(/1/g);
            var this_element = data.rows[i].value;
            this_element.fitness = m.length;
            after_eval.push( this_element );
	    if ( this_element.fitness > best_chrom.fitness ) {
		best_chrom = this_element;
	    }
	}
	$("div#chromosomes").html( cool_chrom( best_chrom._id));
	$db .bulkSave({"docs": after_eval}, {
	    success: function(data) {
		console.log(data);
	    },
	    error: function(status) {
		console.log(status);
            }
	});
	check_evaluations();
    }
       
} 

//--------------------------------------------------------------
function show_chromosomes() {  
    $db.view("rev/rev1", {  
	success: evaluate,
	startkey: Math.random(),
	limit: 64});
}

//--------------------------------------------------------------
function check_evaluations () {
    $db.view("docs/count", {
	success: function(data) {
	    evaluations_so_far = data.rows[0].value;
	    if ( evaluations_so_far < 5000 ) {
	        show_chromosomes();
	    } else {
		alert("It's over");
	    }
	}
    } );
}

//------------------------------------------------
   
$(document).ready(function() {
    check_evaluations();
});