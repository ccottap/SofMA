function(doc) {
    if ((doc.type == 0) && (doc.state == 0) && !('fitness' in doc)) 
      	emit(doc.rnd, doc);	
}
