function(doc) {
    if ((doc.type == 1) && (doc.state == 0))
      	emit(doc.rnd, doc);
}
