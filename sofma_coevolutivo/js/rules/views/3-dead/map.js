function(doc) {
    if ((doc.type == 1) && (doc.state == 1))
        emit(doc.rnd, doc);
}
