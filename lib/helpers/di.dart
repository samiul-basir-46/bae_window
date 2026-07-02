//import 'package:firebase_messaging/firebase_messaging.dart';

import 'package:get_it/get_it.dart';
import 'package:get_storage/get_storage.dart';
import 'package:dio/dio.dart';
import 'package:bea_window_app/features/email/data/email_repository.dart';
import 'package:bea_window_app/features/email/presentation/cubit/email_cubit.dart';



final locator = GetIt.instance;
final appData = locator.get<GetStorage>();

void diSetup() {
  locator.registerSingleton<GetStorage>(GetStorage());


  locator.registerLazySingleton<EmailRepository>(
    () => EmailRepository(Dio()),
  );

  locator.registerFactory<EmailCubit>(
    () => EmailCubit(locator<EmailRepository>()),
  );
}

