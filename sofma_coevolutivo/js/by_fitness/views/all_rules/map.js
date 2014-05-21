function(doc) {
    if ((doc.type == 1) && ('fitness' in doc))
      	emit(doc.fitness, doc);	
}
