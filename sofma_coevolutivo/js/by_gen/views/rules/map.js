function(doc) {
    if (doc.type == 1) 
      	emit(doc.gen, doc);	
}
