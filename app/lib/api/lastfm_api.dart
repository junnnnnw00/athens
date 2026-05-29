abstract class LastfmApi {
  Future<List<String>> getTopTags({
    required String artist,
    required String track,
  });
  Future<List<String>> getArtistTopTags({required String artist});
}

class FakeLastfmApi implements LastfmApi {
  @override
  Future<List<String>> getTopTags({
    required String artist,
    required String track,
  }) async {
    return ['indie rock', 'alternative', 'dreamy', 'shoegaze', 'melancholic'];
  }

  @override
  Future<List<String>> getArtistTopTags({required String artist}) async {
    return ['indie rock', 'alternative', 'shoegaze'];
  }
}
