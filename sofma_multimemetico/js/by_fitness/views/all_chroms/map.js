function(doc) {
    if ((doc.type == 0) && ('fitness' in doc))
      	emit(doc.fitness, doc);	
}
