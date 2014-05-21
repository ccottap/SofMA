function cool_chrom( str ) { // Taken from old agajaj

    var my_table = '<table style="padding:0;border-collapse:collapse"><tr>';
    for ( var i = 0; i < str.length; i ++ ) {
	if ( str[i] == '1' ) {
	    my_table += '<td style="background:green">';
	} else {
	    my_table += '<td style="background:red">';
	}
	my_table += "&nbsp;</td>";
    }
    return my_table + "</tr></table>";
}


