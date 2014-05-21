function(doc) {
    if ((doc.type == 1) && (doc.state == 0) && !('fitness' in doc)) 
      	emit(doc.rnd, doc);	
}
