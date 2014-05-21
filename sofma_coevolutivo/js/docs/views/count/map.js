function(doc) {
    if ((doc.type == 0) && (doc.state == 0))
        emit(doc._id, 1);
}
