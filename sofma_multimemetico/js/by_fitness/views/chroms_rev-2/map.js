function(doc) {
    if ((doc.type == 0) && ('fitness' in doc) && (doc.state == 0))
      	emit(doc.fitness, doc);	
}
