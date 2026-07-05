import 'package:get_it/get_it.dart';
import 'package:get_storage/get_storage.dart';
import 'package:bea_window_app/features/chat/repositories/chat_repository.dart';

final locator = GetIt.instance;
final appData = locator.get<GetStorage>();

void diSetup() {
  locator.registerSingleton<GetStorage>(GetStorage());
  locator.registerLazySingleton<ChatRepository>(() => ChatRepository());
}
