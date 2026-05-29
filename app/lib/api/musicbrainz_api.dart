abstract class MusicBrainzApi {
  Future<List<String>> getGenres({
    required String artist,
    required String title,
  });
}

class FakeMusicBrainzApi implements MusicBrainzApi {
  @override
  Future<List<String>> getGenres({
    required String artist,
    required String title,
  }) async {
    return ['indie rock', 'dream pop'];
  }
}
