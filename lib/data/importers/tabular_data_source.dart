abstract class TabularDataSource {
  Future<List<String>> getHeaders();
  Stream<List<dynamic>> getRows();
}
