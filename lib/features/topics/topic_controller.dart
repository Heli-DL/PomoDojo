import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'topic_model.dart';
import 'topic_repository.dart';

final topicRepositoryProvider = Provider<TopicRepository>((ref) {
  return TopicRepository();
});

class TopicsController extends AsyncNotifier<List<Topic>> {
  @override
  Future<List<Topic>> build() async {
    final repo = ref.read(topicRepositoryProvider);
    return await repo.watchUserTopics().first;
  }

  Stream<List<Topic>> watch() {
    final repo = ref.read(topicRepositoryProvider);
    return repo.watchUserTopics();
  }

  Future<void> add(Topic topic) async {
    await ref.read(topicRepositoryProvider).addTopic(topic);
    ref.invalidateSelf();
  }

  Future<void> save(Topic topic) async {
    await ref.read(topicRepositoryProvider).updateTopic(topic);
    ref.invalidateSelf();
  }

  Future<void> remove(String id) async {
    await ref.read(topicRepositoryProvider).deleteTopic(id);
    ref.invalidateSelf();
  }
}

final topicsControllerProvider =
    AsyncNotifierProvider<TopicsController, List<Topic>>(() {
      return TopicsController();
    });

final selectedTopicProvider = StateProvider<Topic?>((ref) => null);
