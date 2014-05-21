var request;
function pide_pop() {
  request = new XMLHttpRequest();
  var peticion_str = 'http://localhost:5984/_design/revs/_view/rev1?limit=32';
  request.open('GET', peticion_str , true);
  request.onreadystatechange= escribe_RSS ;
  request.send(null);
}

function evaluate_population(){
  if ( request.readyState == 4 ) {
    if ( request.status == 200 ) { // alert(request.responseText);
      var doc = request.responsetext;
      alert(doc);
    }
  }
}