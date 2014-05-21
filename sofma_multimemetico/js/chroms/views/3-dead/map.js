function(doc) {
    if ((doc.type == 0) && (doc.state == 1))
        emit(doc.rnd, doc);
}
